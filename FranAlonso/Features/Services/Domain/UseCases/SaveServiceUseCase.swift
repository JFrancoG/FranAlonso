/// Persists validated service snapshots through the local-first boundary.
struct SaveServiceUseCase {
    private let serviceRepository: any ServiceRepository

    /// Saves a service locally without waiting for remote synchronization.
    ///
    /// - Parameter service: The validated service snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func callAsFunction(_ service: Service) async throws {
        try await serviceRepository.saveService(service)
    }
}

extension SaveServiceUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that persists service snapshots.
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
