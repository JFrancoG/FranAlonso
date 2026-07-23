/// Exposes locally materialized product snapshots to presentation consumers.
struct ObserveProductsUseCase {
    private let productRepository: any ProductRepository

    /// Starts observing the current local product collection.
    ///
    /// - Returns: A stream of product snapshots from the local source of truth.
    func callAsFunction() async -> AsyncThrowingStream<[Product], any Error> {
        await productRepository.observeProducts()
    }
}

extension ObserveProductsUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that provides local product snapshots.
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
