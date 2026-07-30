/// An actor-isolated Clients repository for previews and deterministic tests.
actor InMemoryClientRepository: ClientRepository {
    private var clients: [Client]

    init(clients: [Client] = []) {
        self.clients = clients
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(clients)
            continuation.finish()
        }
    }

    /// Inserts a client or replaces the snapshot with the same stable identity.
    func saveClient(_ client: Client) async throws {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
    }
}
