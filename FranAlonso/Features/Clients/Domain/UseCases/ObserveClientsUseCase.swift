/// Exposes locally materialized client snapshots to presentation consumers.
struct ObserveClientsUseCase: Sendable {
    private let clientRepository: any ClientRepository

    /// Starts observing the current local client collection.
    ///
    /// - Returns: A stream of client snapshots from the local source of truth.
    func callAsFunction() async -> AsyncThrowingStream<[Client], any Error> {
        await clientRepository.observeClients()
    }
}

extension ObserveClientsUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that provides local client snapshots.
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
