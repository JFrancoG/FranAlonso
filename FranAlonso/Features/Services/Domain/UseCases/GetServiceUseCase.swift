/// Reads a locally visible active or inactive service by identity.
struct GetServiceUseCase {
    private let serviceRepository: any ServiceRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ServiceError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(_ id: ServiceID) async throws -> Service? {
        try Task.checkCancellation()
        return try await serviceRepository.service(id: id)
    }
}

extension GetServiceUseCase {
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
