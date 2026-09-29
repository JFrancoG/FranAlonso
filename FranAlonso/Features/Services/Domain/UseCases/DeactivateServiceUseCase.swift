/// Makes a service inactive without deleting its profile or references.
struct DeactivateServiceUseCase {
    private let serviceRepository: any ServiceRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ServiceError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(_ id: ServiceID) async throws {
        try Task.checkCancellation()
        try await serviceRepository.deactivateService(id)
    }
}

extension DeactivateServiceUseCase {
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
