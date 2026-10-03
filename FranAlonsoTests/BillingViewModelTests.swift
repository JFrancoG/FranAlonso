import Observation
import Testing
@testable import FranAlonso

@Suite("Billing presentation facade") @MainActor
struct BillingViewModelTests {
    @Test
    func `computed facade projections follow preparation and confirmed allocation`() async throws {
        let authority = BillingPresentationRepository()
        let model = BillingViewModel(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try model.prepare(request)
        #expect(model.localState == .pendingNumber(request))
        #expect(model.canReserve)

        let document = try await model.reserve()

        #expect(model.document == document)
        #expect(model.localState == .numbered(document))
        #expect(model.request == request)
        #expect(!model.canReserve)
        #expect(!model.isBusy)
    }

    @Test
    func `reading facade getters observes changes owned by the private store`() async throws {
        let authority = BillingPresentationRepository()
        let model = BillingViewModel(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()

        try await confirmation("Prepared allocation invalidates facade getters", expectedCount: 1) { changed in
            withObservationTracking {
                _ = model.request
                _ = model.canReserve
            } onChange: {
                changed()
            }
            try model.prepare(request)
        }

        #expect(model.request == request)
        #expect(await authority.received.isEmpty)
    }

    @Test
    func `explicit facade retry recovers a lost response without replacing identifiers`() async throws {
        let ledger = BillingTransactionLedger(interruption: .afterCommit)
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let model = BillingViewModel(reserve: ReserveBillingDocumentUseCase(repository: repository))
        let request = try billingTransactionRequest(kind: .invoice)
        try model.prepare(request)
        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await model.reserve()
        }
        #expect(model.failure == .unavailable)
        #expect(model.canReserve)
        let committed = await ledger.state()

        let recovered = try await model.retry()
        let replay = try await model.retry()

        #expect(replay == recovered)
        #expect(model.request == request)
        #expect(model.document == recovered)
        #expect(model.failure == nil)
        #expect(await ledger.state() == committed)
        #expect(await ledger.calls == 2)
    }

    @Test
    func `facade cancellation and close revoke publication without losing the request`() async throws {
        let gate = RecoveryOperationGate()
        let authority = BillingPresentationRepository(replies: [.init(gate: gate, response: .success)])
        let model = BillingViewModel(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try model.prepare(request)
        let task = Task {
            try await model.reserve()
        }
        #expect(await gate.waitForEntry())
        #expect(model.isBusy)
        model.cancelReservation()
        #expect(model.localState == .pendingNumber(request))
        #expect(model.canReserve)
        model.close()
        await gate.release()

        await #expect(throws: CancellationError.self) {

            try await task.value

        }
        #expect(model.state == .closed(.pendingNumber(request)))
        #expect(model.request == request)
        #expect(!model.isBusy)
        #expect(!model.canReserve)
        await #expect(throws: BillingDocumentStoreError.closed) {
            try await model.retry()
        }
    }
}
