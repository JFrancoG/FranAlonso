/// Deactivates a known client without erasing its locally retained consent.
struct DeactivateClientUseCase {
    private let clientRepository: any ClientRepository

    /// Checks cancellation before the repository accepts the idempotent local tombstone.
    /// - Throws: `ClientError` for a rejected operation or `CancellationError` before acceptance.
    func callAsFunction(_ id: ClientID) async throws {
        try Task.checkCancellation()
        try await clientRepository.deactivateClient(id)
    }
}

extension DeactivateClientUseCase {
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
