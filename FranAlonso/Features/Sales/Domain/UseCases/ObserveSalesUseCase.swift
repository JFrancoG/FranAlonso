/// Exposes locally materialized sale snapshots to presentation consumers.
struct ObserveSalesUseCase {
    private let saleRepository: any SaleRepository

    /// Starts observing the current local sale collection.
    ///
    /// - Returns: A stream of sale snapshots from the local source of truth.
    func callAsFunction() async -> AsyncThrowingStream<[Sale], any Error> {
        await saleRepository.observeSales()
    }
}

extension ObserveSalesUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that provides local sale snapshots.
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
