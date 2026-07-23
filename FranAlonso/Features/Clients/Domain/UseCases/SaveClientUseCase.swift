/// Persists validated client snapshots through the local-first boundary.
struct SaveClientUseCase {
    private let clientRepository: any ClientRepository

    /// Saves a client locally without waiting for remote synchronization.
    ///
    /// - Parameter client: The validated client snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func callAsFunction(_ client: Client) async throws {
        try await clientRepository.saveClient(client)
    }
}

extension SaveClientUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that persists client snapshots.
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
