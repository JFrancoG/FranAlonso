/// Observes the active local products eligible for service linkage, preserving source order and termination.
struct ObserveLinkableProductsUseCase {
    private let productRepository: any ProductRepository

    /// Maps snapshots lazily; the source owns errors, buffering and cancellation without another producer task.
    func callAsFunction() async -> AsyncMapSequence<AsyncThrowingStream<[Product], any Error>, [Product]> {
        await productRepository.observeProducts().map { products in
            products.filter { $0.status == .active }
        }
    }
}

extension ObserveLinkableProductsUseCase {
    /// Uses the existing Product Domain boundary shared by inventory and service composition.
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
