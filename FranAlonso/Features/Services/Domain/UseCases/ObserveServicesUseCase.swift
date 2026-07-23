/// Exposes locally materialized service snapshots to presentation consumers.
struct ObserveServicesUseCase {
    private let serviceRepository: any ServiceRepository

    /// Starts observing the current local service collection.
    ///
    /// - Returns: A stream of service snapshots from the local source of truth.
    func callAsFunction() async -> AsyncThrowingStream<[Service], any Error> {
        await serviceRepository.observeServices()
    }
}

extension ObserveServicesUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that provides local service snapshots.
    init(repository: any ServiceRepository) {
        self.init(serviceRepository: repository)
    }
}
