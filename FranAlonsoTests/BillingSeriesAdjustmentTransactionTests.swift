import Foundation
import Testing
@testable import FranAlonso

struct BillingSeriesAdjustmentTransactionTests {
    @Test(arguments: [BillingDocumentSeries.ticket, .invoice])
    func `explicit adjustment atomically advances only its selected family`(
        series: BillingDocumentSeries
    ) async throws {
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        try await ledger.seedCounter(
            BillingCounterDTO(payloadVersion: 1, series: .invoice, lastNumber: 40),
            at: .invoice
        )
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        let receipt = try await repository.adjust(seriesAdjustmentRequest(series: series))
        #expect(receipt.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(receipt.principalID == "admin-opaque-A")
        #expect(receipt.request.targetLastNumber == 50)
        let state = await ledger.state()
        #expect(state.audits.count == 1)
        #expect(state.commits == 1)
        #expect(state.bindings.isEmpty && state.documents.isEmpty)
        #expect(try await ledger.counter(series)?.lastNumber == 50)
        let other: BillingDocumentSeries = series == .ticket ? .invoice : .ticket
        #expect(try await ledger.counter(other)?.lastNumber == 40)
    }

    @Test func `absent head accepts explicit initialization from zero`() async throws {
        let ledger = SeriesAdjustmentLedger()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        _ = try await repository.adjust(seriesAdjustmentRequest(expected: 0, target: 300))
        #expect(try await ledger.counter(.ticket)?.lastNumber == 300)
        #expect(try await ledger.counter(.ticket)?.payloadVersion == 1)
        #expect(await ledger.state().commits == 1)
    }

    @Test func `stale expected head requires a new decision without mutation`() async throws {
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 41))
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.conflict) {
            try await repository.adjust(seriesAdjustmentRequest())
        }
        #expect(await ledger.state() == before)
        #expect(await ledger.adjustmentCalls == 1)
    }

    @Test(arguments: [
        SeriesAdjustmentCounterCorruption.unsupportedVersion, .wrongSeries, .negative, .malformed, .unknownField
    ])
    func `corrupt shared head cannot be replaced`(corruption: SeriesAdjustmentCounterCorruption) async throws {
        let ledger = SeriesAdjustmentLedger()
        await ledger.seedCounterBytes(try corruption.bytes())
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try await repository.adjust(seriesAdjustmentRequest())
        }
        #expect(await ledger.state() == before)
    }

    @Test(arguments: [
        SeriesAdjustmentAuditCorruption.unsupportedVersion, .missingTimestamp, .blankPrincipal, .noncanonicalID,
        .wrongRequestVersion, .malformed, .unknownField, .nestedUnknownField
    ])
    func `corrupt immutable audit blocks recovery and overwrite`(
        corruption: SeriesAdjustmentAuditCorruption
    ) async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        await ledger.seedAuditBytes(try corruption.bytes(request), at: request.id.uuidString)
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try await repository.adjust(request)
        }
        #expect(await ledger.state() == before)
    }

    @Test(arguments: [
        (BillingDocumentSeries.invoice, Int64(40), Int64(50)),
        (.ticket, 39, 50),
        (.ticket, 40, 51)
    ])
    func `reusing operation identity with another intent conflicts`(
        series: BillingDocumentSeries,
        expected: Int64,
        target: Int64
    ) async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedAudit(seriesAdjustmentAudit(request), at: request.id.uuidString)
        let before = await ledger.state()
        let changed = try seriesAdjustmentRequest(series: series, expected: expected, target: target)
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.conflict) {
            try await repository.adjust(changed)
        }
        #expect(await ledger.state() == before)
    }

    @Test func `another administrator cannot take ownership of an existing operation`() async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedAudit(seriesAdjustmentAudit(request), at: request.id.uuidString)
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer(principal: "admin-opaque-B")
        )
        await #expect(throws: BillingSeriesAdjustmentError.conflict) {
            try await repository.adjust(request)
        }
        #expect(await ledger.state() == before)
    }

    @Test func `valid replay survives a subsequently corrupt counter without rewriting its date`() async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedAudit(seriesAdjustmentAudit(request), at: request.id.uuidString)
        await ledger.seedCounterBytes(Data("{}".utf8))
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        let receipt = try await repository.adjust(request)
        #expect(receipt.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(receipt.request.expectedLastNumber == 40 && receipt.request.targetLastNumber == 50)
        #expect(await ledger.state() == before)
    }

    @Test func `failure before commit leaves head and audit untouched`() async throws {
        let ledger = SeriesAdjustmentLedger(interruption: .beforeCommit)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let before = await ledger.state()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.unavailable) {
            try await repository.adjust(seriesAdjustmentRequest())
        }
        #expect(await ledger.state() == before)
        #expect(await ledger.adjustmentCalls == 1)
    }

    @Test func `lost response after commit recovers only through explicit identical retry`() async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger(interruption: .afterCommit)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.unavailable) {
            try await repository.adjust(request)
        }
        let committed = await ledger.state()
        #expect(committed.audits.count == 1 && committed.commits == 1)
        #expect(try await ledger.counter(.ticket)?.lastNumber == 50)
        #expect(await ledger.adjustmentCalls == 1)
        let recovered = try await repository.adjust(request)
        #expect(recovered.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(await ledger.state() == committed)
        #expect(await ledger.adjustmentCalls == 2)
    }

    @Test func `mismatched transport response is not published`() async throws {
        let request = try seriesAdjustmentRequest()
        let source = SeriesAdjustmentSubstitutionSource(
            response: try seriesAdjustmentAudit(seriesAdjustmentRequest(index: 2))
        )
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: source,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try await repository.adjust(request)
        }
        #expect(await source.calls == 1)
    }

    @Test func `foreign principal response is not published`() async throws {
        let request = try seriesAdjustmentRequest()
        let source = SeriesAdjustmentSubstitutionSource(
            response: try seriesAdjustmentAudit(request, principal: "admin-opaque-B")
        )
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: source,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        await #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try await repository.adjust(request)
        }
    }
}
