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

    private let observeClients: ObserveClientsUseCase

    init(observeClients: ObserveClientsUseCase) {
        self.observeClients = observeClients
    }

    /// Observes client snapshots and updates the screen state until the stream finishes.
    ///
    /// Each snapshot becomes either `empty` or `content`. A stream that finishes without a
    /// snapshot becomes `empty`; cancellation restores `idle`; any other failure becomes `failed`.
    func load() async {
        state = .loading

        do {
            let stream = await observeClients()
            var receivedSnapshot = false

            for try await clients in stream {
                try Task.checkCancellation()
                receivedSnapshot = true
                state = clients.isEmpty ? .empty : .content(clients)
            }

            try Task.checkCancellation()
            if !receivedSnapshot {
                state = .empty
            }
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
