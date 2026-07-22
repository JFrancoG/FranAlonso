import Observation

@Observable
@MainActor
final class ClientListViewModel {
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
