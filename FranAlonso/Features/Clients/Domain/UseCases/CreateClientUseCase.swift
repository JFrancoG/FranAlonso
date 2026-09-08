/// Creates a local draft without granting consent-backed activation.
struct CreateClientUseCase {
    private let clientRepository: any ClientRepository

    /// Checks cancellation before local acceptance; the repository result is authoritative after delegation.
    /// - Throws: `ClientError` for a rejected operation or `CancellationError` before acceptance.
    func callAsFunction(id: ClientID, profile: ClientProfile) async throws -> Client {
        try Task.checkCancellation()
        return try await clientRepository.createClient(id: id, profile: profile)
    }
}

extension CreateClientUseCase {
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
