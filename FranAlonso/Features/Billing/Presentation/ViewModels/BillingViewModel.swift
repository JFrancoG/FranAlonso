import Observation

/// The presentation facade reads its Store directly, including through Observation tracking.
@Observable @MainActor
final class BillingViewModel<Repository: BillingDocumentReservationRepository> {
    private let store: BillingDocumentStore<Repository>

    var state: BillingDocumentStoreState { store.state }
    var localState: BillingDocumentLocalState? { store.localState }
    var request: BillingDocumentRequest? { store.request }
    var document: BillingDocument? { store.document }
    var isBusy: Bool { store.isBusy }
    var canReserve: Bool { store.canReserve }
    var failure: BillingDocumentFailure? { store.failure }

    func prepare(_ request: BillingDocumentRequest) throws {
        try store.prepare(request)
    }

    func reserve() async throws -> BillingDocument {
        try await store.reserve()
    }

    /// Explicitly retries the same sealed request; generates no new allocation identity.
    func retry() async throws -> BillingDocument {
        try await store.reserve()
    }

    func cancelReservation() {
        store.cancelReservation()
    }

    func close() {
        store.close()
    }

    init(reserve: ReserveBillingDocumentUseCase<Repository>) {
        store = BillingDocumentStore(reserve: reserve)
    }
}
