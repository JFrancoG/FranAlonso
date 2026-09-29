import Foundation
import Observation

/// Coordinates local service snapshots, search and independent form sessions.
@Observable
@MainActor
final class ServiceListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case content([Service])
        case failed
    }

    private(set) var state: State = .idle
    var query = ""
    private(set) var formDestination: ServiceFormDestination?

    private let observeServices: ObserveServicesUseCase
    private let searchServices = SearchServicesUseCase()
    private let makeID: @MainActor () -> UUID
    @ObservationIgnored private var observationGeneration = UUID()

    init(
        observeServices: ObserveServicesUseCase,
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        self.observeServices = observeServices
        self.makeID = makeID
    }

    /// Searches the current snapshot without hiding inactive services or mutating the source.
    var visibleServices: [Service] {
        guard case .content(let services) = state else { return [] }
        return searchServices(services, query: query)
    }

    /// Distinguishes an unmatched query from an empty local collection.
    var hasNoSearchResults: Bool {
        guard case .content(let services) = state, !services.isEmpty else { return false }
        return visibleServices.isEmpty
    }

    /// Allocates the session and service identities once until the form is dismissed.
    func beginCreatingService() {
        guard formDestination == nil else { return }
        formDestination = ServiceFormDestination(id: makeID(), serviceID: ServiceID(rawValue: makeID()), mode: .create)
    }

    /// Opens only identities included in the currently visible search results.
    func beginEditingService(_ id: ServiceID) {
        guard formDestination == nil, visibleServices.contains(where: { $0.id == id }) else { return }
        formDestination = ServiceFormDestination(id: makeID(), serviceID: id, mode: .edit)
    }

    /// Ignores a delayed completion or dismissal from a previously presented form.
    func finishFormSession(_ sessionID: UUID) {
        guard formDestination?.id == sessionID else { return }
        formDestination = nil
    }

    /// Observes local snapshots for the lifetime of the caller's task.
    ///
    /// An observation that ends without values becomes `empty`. Cancellation returns to `idle`,
    /// while other errors become `failed`. Replaced observations cannot publish into a newer load.
    func load() async {
        let generation = UUID()
        observationGeneration = generation
        state = .loading

        do {
            try Task.checkCancellation()
            let stream = await observeServices()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false

            for try await services in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                state = services.isEmpty ? .empty : .content(services)
            }

            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                state = .empty
            }
        } catch is CancellationError {
            guard observationGeneration == generation else { return }
            state = .idle
        } catch {
            guard observationGeneration == generation else { return }
            state = Task.isCancelled ? .idle : .failed
        }
    }
}
