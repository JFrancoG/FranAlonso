/// An actor-isolated Clients repository for previews and deterministic tests.
actor InMemoryClientRepository: ClientRepository {
    private var clients: [Client]
    private var deactivatedIDs: Set<ClientID> = []

    init(clients: [Client] = []) {
        self.clients = clients
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(clients.filter { !deactivatedIDs.contains($0.id) })
            continuation.finish()
        }
    }

    /// Inserts a client or replaces the snapshot with the same stable identity.
    func saveClient(_ client: Client) async throws {
        guard !deactivatedIDs.contains(client.id) else { throw ClientError.deactivated }
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
    }

    func client(id: ClientID) async throws -> Client? {
        try Task.checkCancellation()
        guard !deactivatedIDs.contains(id) else { return nil }
        return clients.first { $0.id == id }
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        try Task.checkCancellation()
        guard !deactivatedIDs.contains(id) else { throw ClientError.alreadyExists }
        guard !clients.contains(where: { $0.id == id }) else { throw ClientError.alreadyExists }
        let client = Client(
            id: id,
            displayName: profile.displayName,
            taxIdentifier: profile.taxIdentifier,
            billingAddress: profile.billingAddress,
            status: .draft
        )
        clients.append(client)
        return client
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        try Task.checkCancellation()
        guard !deactivatedIDs.contains(id) else { throw ClientError.deactivated }
        guard let index = clients.firstIndex(where: { $0.id == id }) else { throw ClientError.notFound }
        let client = Client(
            id: id,
            displayName: profile.displayName,
            taxIdentifier: profile.taxIdentifier,
            billingAddress: profile.billingAddress,
            status: clients[index].status
        )
        clients[index] = client
        return client
    }

    func deactivateClient(_ id: ClientID) async throws {
        try Task.checkCancellation()
        guard !deactivatedIDs.contains(id) else { return }
        guard clients.contains(where: { $0.id == id }) else { throw ClientError.notFound }
        deactivatedIDs.insert(id)
    }
}
