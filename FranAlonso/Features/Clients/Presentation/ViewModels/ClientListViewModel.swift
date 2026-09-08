import Foundation
import Observation

/// Coordinates locally materialized clients into explicit list-screen states.
@Observable
@MainActor
final class ClientListViewModel {
    /// The complete rendering state of the client list.
    enum State: Equatable {
        case idle
        case loading
        case empty
        case content([Client])
        case failed
    }

    private(set) var state: State = .idle
    var query = ""
    private(set) var formDestination: ClientFormDestination?

    private let observeClients: ObserveClientsUseCase
    private let searchClients = SearchClientsUseCase()
    private let makeID: @MainActor () -> UUID
    @ObservationIgnored private var observationGeneration = UUID()

    init(
        observeClients: ObserveClientsUseCase,
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        self.observeClients = observeClients
        self.makeID = makeID
    }

    /// Derives matching rows from the single observed snapshot and the current query.
    var visibleClients: [Client] {
        guard case .content(let clients) = state else { return [] }
        return searchClients(clients, query: query)
    }

    /// Distinguishes an unmatched query from a source that has no clients.
    var hasNoSearchResults: Bool {
        guard case .content(let clients) = state, !clients.isEmpty else { return false }
        return visibleClients.isEmpty
    }

    /// Allocates a stable client identity once for the current creation session.
    func beginCreatingClient() {
        guard formDestination == nil else { return }
        formDestination = ClientFormDestination(id: makeID(), clientID: ClientID(rawValue: makeID()), mode: .create)
    }

    /// Opens only a client present in the currently displayed search results.
    func beginEditingClient(_ id: ClientID) {
        guard formDestination == nil, visibleClients.contains(where: { $0.id == id }) else { return }
        formDestination = ClientFormDestination(id: makeID(), clientID: id, mode: .edit)
    }

    /// Applies dismissal or a completed form result only to the matching presentation session.
    func finishFormSession(_ sessionID: UUID) {
        guard formDestination?.id == sessionID else { return }
        formDestination = nil
    }

    /// Observes client snapshots and updates the screen state until the stream finishes.
    ///
    /// Each snapshot becomes either `empty` or `content`. A stream that finishes without a
    /// snapshot becomes `empty`; cancellation restores `idle`; any other failure becomes `failed`.
    /// The caller owns the task lifetime. Replaced observations cannot publish into the newer load.
    func load() async {
        let generation = UUID()
        observationGeneration = generation
        state = .loading

        do {
            try Task.checkCancellation()
            let stream = await observeClients()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false

            for try await clients in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                state = clients.isEmpty ? .empty : .content(clients)
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
