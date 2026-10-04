import Foundation
import Testing
@testable import FranAlonso

struct BillingSeriesAdjustmentAuthorizationTests {
    @Test(arguments: [
        BillingSeriesAdjustmentError.permissionDenied, .unavailable, .invalidResponse
    ])
    func `denied or indeterminate authority never contacts transaction`(
        failure: BillingSeriesAdjustmentError
    ) async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        let authorizer = SeriesAdjustmentAuthorizer(failure: failure)
        let repository = FirestoreBillingSeriesAdjustmentRepository(dataSource: ledger, authorizer: authorizer)
        await #expect(throws: failure) {
            try await repository.adjust(request)
        }
        #expect(await ledger.adjustmentCalls == 0)
        #expect(await authorizer.requests == [request])
        #expect(await ledger.state().audits.isEmpty)
    }

    @Test(arguments: ["", " \n\t "])
    func `invalid administrative principal fails before remote contact`(principal: String) async throws {
        let ledger = SeriesAdjustmentLedger()
        let repository = FirestoreBillingSeriesAdjustmentRepository(
            dataSource: ledger,
            authorizer: SeriesAdjustmentAuthorizer(principal: principal)
        )
        await #expect(throws: BillingSeriesAdjustmentError.permissionDenied) {
            try await repository.adjust(seriesAdjustmentRequest())
        }
        #expect(await ledger.adjustmentCalls == 0)
    }

    @Test func `cancellation during initial authorization prevents transaction`() async throws {
        let request = try seriesAdjustmentRequest()
        let gate = SeriesAdjustmentGate()
        let authorizer = SeriesAdjustmentAuthorizer(gate: gate)
        let ledger = SeriesAdjustmentLedger()
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
        task.cancel()
        await gate.release()
        let result = await task.value
        #expect(throws: CancellationError.self) {
            try result.get()
        }
        #expect(await ledger.adjustmentCalls == 0)
        #expect(await ledger.state().commits == 0)
    }

    @Test(arguments: [Optional<String>.none, .some("admin-opaque-B")])
    func `revocation or replacement after commit prevents publication but retains audit`(
        replacement: String?
    ) async throws {
        let request = try seriesAdjustmentRequest()
        let gate = SeriesAdjustmentGate()
        let authorizer = SeriesAdjustmentAuthorizer()
        let ledger = SeriesAdjustmentLedger(responseGate: gate)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
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
        let committed = await ledger.state()
        #expect(committed.commits == 1 && committed.audits.count == 1)
        await authorizer.replace(principal: replacement)
        await gate.release()
        let result = await task.value
        #expect(throws: BillingSeriesAdjustmentError.permissionDenied) {
            try result.get()
        }
        #expect(await ledger.state() == committed)
        #expect(await ledger.adjustmentCalls == 1)
    }

    @Test func `indeterminate second authorization does not publish committed acceptance`() async throws {
        let request = try seriesAdjustmentRequest()
        let gate = SeriesAdjustmentGate()
        let authorizer = SeriesAdjustmentAuthorizer()
        let ledger = SeriesAdjustmentLedger(responseGate: gate)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
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
        await authorizer.refuse(.unavailable)
        await gate.release()
        let result = await task.value
        #expect(throws: BillingSeriesAdjustmentError.unavailable) {
            try result.get()
        }
        #expect(await ledger.state().commits == 1)
    }

    @Test func `cancelled response can later recover the same committed adjustment`() async throws {
        let request = try seriesAdjustmentRequest()
        let gate = SeriesAdjustmentGate()
        let authorizer = SeriesAdjustmentAuthorizer()
        let ledger = SeriesAdjustmentLedger(responseGate: gate)
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
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
        let committed = await ledger.state()
        task.cancel()
        await gate.release()
        let result = await task.value
        #expect(throws: CancellationError.self) {
            try result.get()
        }
        #expect(await ledger.state() == committed)
        let recovered = try await FirestoreBillingSeriesAdjustmentRepository(dataSource: ledger, authorizer: authorizer)
            .adjust(request)
        #expect(recovered.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(await ledger.state() == committed)
    }

    @Test func `cancellation while reauthorizing cannot publish a committed response`() async throws {
        let request = try seriesAdjustmentRequest()
        let gate = SeriesAdjustmentGate()
        let authorizer = SeriesAdjustmentAuthorizer(gate: gate, gateAtCall: 2)
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
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
        #expect(await ledger.state().commits == 1)
        task.cancel()
        await gate.release()
        let result = await task.value
        #expect(throws: CancellationError.self) {
            try result.get()
        }
        #expect(await ledger.adjustmentCalls == 1)
    }

    @Test func `each acceptance checks current authority for the exact operation twice`() async throws {
        let request = try seriesAdjustmentRequest()
        let ledger = SeriesAdjustmentLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        let authorizer = SeriesAdjustmentAuthorizer()
        _ = try await FirestoreBillingSeriesAdjustmentRepository(dataSource: ledger, authorizer: authorizer)
            .adjust(request)
        #expect(await authorizer.requests == [request, request])
    }
}
