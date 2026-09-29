/// Creates an active service without overwriting an existing identity.
struct CreateServiceUseCase {
    private let serviceRepository: any ServiceRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ServiceError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        try Task.checkCancellation()
        return try await serviceRepository.createService(id: id, profile: profile)
    }
}

extension CreateServiceUseCase {
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
