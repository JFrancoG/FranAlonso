/// Reopens a visible client profile from the local source of truth.
struct GetClientUseCase {
    private let clientRepository: any ClientRepository

    /// Resolves a stable identity without exposing retained deactivated history as an editable client.
    /// - Throws: `ClientError.notFound` for an absent profile, a repository failure, or prior cancellation.
    func callAsFunction(_ id: ClientID) async throws -> Client {
        try Task.checkCancellation()
        guard let client = try await clientRepository.client(id: id) else { throw ClientError.notFound }
        return client
    }
}

extension GetClientUseCase {
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
