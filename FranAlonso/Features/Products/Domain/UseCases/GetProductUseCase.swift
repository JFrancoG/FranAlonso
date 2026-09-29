/// Reads a locally visible active or inactive product by identity.
struct GetProductUseCase {
    private let productRepository: any ProductRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ProductError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(_ id: ProductID) async throws -> Product? {
        try Task.checkCancellation()
        return try await productRepository.product(id: id)
    }
}

extension GetProductUseCase {
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
