import Foundation
import Testing
@testable import FranAlonso

struct BillingSeriesAdjustmentReservationIntegrationTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `adjustment changes the next allocation and preserves previously issued documents`(
        kind: BillingDocumentKind
    ) async throws {
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(
            BillingCounterDTO(payloadVersion: 1, series: kind.series, lastNumber: 40),
            at: kind.series
        )
        let reservation = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let originalRequest = try billingTransactionRequest(index: 1, kind: kind)
        let original = try await reservation.reserve(originalRequest)
        #expect(original.number.value == 41)
        let issued = await ledger.state()
        let adjustment = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        _ = try await adjustment.adjust(seriesAdjustmentRequest(series: kind.series, expected: 41, target: 100))
        let adjusted = await ledger.state()
        #expect(adjusted.documents == issued.documents && adjusted.bindings == issued.bindings)
        let next = try await reservation.reserve(billingTransactionRequest(index: 2, kind: kind))
        #expect(next.number.value == 101)
        let recoveredOriginal = try await reservation.reserve(originalRequest)
        #expect(recoveredOriginal == original)
        #expect(try await ledger.counter(kind.series)?.lastNumber == 101)
        #expect(try await ledger.counter(kind == .ticket ? .invoice : .ticket) == nil)
    }

    @Test
    func `original acceptance replays after later reservations and another administrative advance`() async throws {
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let adjustment = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        )
        let firstRequest = try seriesAdjustmentRequest()
        let firstReceipt = try await adjustment.adjust(firstRequest)
        let reservation = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let firstDocument = try await reservation.reserve(billingTransactionRequest(index: 1))
        #expect(firstDocument.number.value == 51)
        _ = try await adjustment.adjust(seriesAdjustmentRequest(index: 2, expected: 51, target: 150))
        let secondDocument = try await reservation.reserve(billingTransactionRequest(index: 2))
        #expect(secondDocument.number.value == 151)
        let beforeReplay = await ledger.state()
        let replay = try await adjustment.adjust(firstRequest)
        #expect(replay == firstReceipt)
        #expect(replay.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(await ledger.state() == beforeReplay)
        #expect(try await ledger.counter(.ticket)?.lastNumber == 151)
    }

    @Test func `reservation wins a stale adjustment snapshot and forces an explicit conflict`() async throws {
        let gate = SeriesAdjustmentGate()
        let ledger = SeriesAdjustmentLedger(readGate: gate, readKind: .adjustment)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let request = try seriesAdjustmentRequest()
        let authorizer = SeriesAdjustmentAuthorizer()
        let task = Task {
            await seriesAdjustmentResult(
                request,
                ledger: ledger,
                authorizer: authorizer,
                gate: gate
            )
        }
        let entered = await gate.waitUntilEntered()
        try #require(entered)
        let reserved = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger)
            .reserve(billingTransactionRequest())
        #expect(reserved.number.value == 41)
        await gate.release()
        let result = await task.value
        #expect(throws: BillingSeriesAdjustmentError.conflict) {
            try result.get()
        }
        #expect(try await ledger.counter(.ticket)?.lastNumber == 41)
        #expect(await ledger.state().audits.isEmpty)
        #expect(await ledger.state().commits == 1)
        #expect(await ledger.staleAttempts == 1)
    }

    @Test func `administrative advance wins and reservation replans from the shared committed head`() async throws {
        let gate = SeriesAdjustmentGate()
        let ledger = SeriesAdjustmentLedger(readGate: gate, readKind: .reservation)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let documentRequest = try billingTransactionRequest()
        let task = Task {
            do {
                let document = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger)
                    .reserve(documentRequest)
                await gate.finish()
                return Result<BillingDocument, any Error>.success(document)
            } catch {
                await gate.finish()
                return Result<BillingDocument, any Error>.failure(error)
            }
        }
        let entered = await gate.waitUntilEntered()
        try #require(entered)
        let adjustmentResult: Result<BillingSeriesAdjustmentReceipt, any Error>
        do {
            adjustmentResult = .success(
                try await FirestoreBillingSeriesAdjustmentRepository(
                    dataSource: ledger,
                    authorizer: SeriesAdjustmentAuthorizer()
                ).adjust(seriesAdjustmentRequest())
            )
        } catch {
            adjustmentResult = .failure(error)
        }
        await gate.release()
        let result = await task.value
        _ = try adjustmentResult.get()
        let document = try result.get()
        #expect(document.number.value == 51)
        #expect(try await ledger.counter(.ticket)?.lastNumber == 51)
        #expect(await ledger.state().audits.count == 1)
        #expect(await ledger.state().commits == 2)
        #expect(await ledger.staleAttempts == 1)
    }

    @Test func `two adjustments from the same expected head cannot both commit`() async throws {
        let gate = SeriesAdjustmentGate()
        let ledger = SeriesAdjustmentLedger(readGate: gate, readKind: .adjustment)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let firstRequest = try seriesAdjustmentRequest()
        let authorizer = SeriesAdjustmentAuthorizer()
        let task = Task {
            await seriesAdjustmentResult(
                firstRequest,
                ledger: ledger,
                authorizer: authorizer,
                gate: gate
            )
        }
        let entered = await gate.waitUntilEntered()
        try #require(entered)
        let secondRequest = try seriesAdjustmentRequest(index: 2, target: 70)
        _ = try await FirestoreBillingSeriesAdjustmentRepository(dataSource: ledger, authorizer: authorizer)
            .adjust(secondRequest)
        await gate.release()
        let result = await task.value
        #expect(throws: BillingSeriesAdjustmentError.conflict) {
            try result.get()
        }
        #expect(try await ledger.counter(.ticket)?.lastNumber == 70)
        #expect(try await ledger.audit(firstRequest.id) == nil)
        #expect(try await ledger.audit(secondRequest.id)?.request.targetLastNumber == 70)
        #expect(await ledger.state().commits == 1)
        #expect(await ledger.staleAttempts == 1)
    }

    @Test func `upper administrative limit retains exactly one allocatable number without overflow`() async throws {
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: Int64.max - 2))
        _ = try await FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer()
        ).adjust(seriesAdjustmentRequest(expected: Int64.max - 2, target: Int64.max - 1))
        let reservation = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let last = try await reservation.reserve(billingTransactionRequest(index: 1))
        #expect(last.number.value == 9_223_372_036_854_775_807)
        let exhausted = await ledger.state()
        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await reservation.reserve(billingTransactionRequest(index: 2))
        }
        #expect(await ledger.state() == exhausted)
    }
}
