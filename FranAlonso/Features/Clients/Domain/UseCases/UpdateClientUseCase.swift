/// Edits client profile fields without changing identity, consent or activation.
struct UpdateClientUseCase {
    private let clientRepository: any ClientRepository

    /// Checks cancellation before local acceptance; the repository result is authoritative after delegation.
    /// - Throws: `ClientError` for a rejected operation or `CancellationError` before acceptance.
    func callAsFunction(id: ClientID, profile: ClientProfile) async throws -> Client {
        try Task.checkCancellation()
        return try await clientRepository.updateClient(id: id, profile: profile)
    }
}

extension UpdateClientUseCase {
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
