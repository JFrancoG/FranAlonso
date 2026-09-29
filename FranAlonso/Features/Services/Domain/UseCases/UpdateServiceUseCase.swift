/// Replaces a commercial profile while preserving its current identity and availability.
struct UpdateServiceUseCase {
    private let serviceRepository: any ServiceRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ServiceError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        try Task.checkCancellation()
        return try await serviceRepository.updateService(id: id, profile: profile)
    }
}

extension UpdateServiceUseCase {
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
