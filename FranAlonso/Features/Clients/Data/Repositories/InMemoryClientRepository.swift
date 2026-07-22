actor InMemoryClientRepository: ClientRepository {
    private let clients: [Client]

    init(clients: [Client] = []) {
        self.clients = clients
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(clients)
            continuation.finish()
        }
    }
}
