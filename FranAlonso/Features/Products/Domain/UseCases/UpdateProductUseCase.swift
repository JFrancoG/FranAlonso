/// Edits product metadata while preserving its current identity and availability.
struct UpdateProductUseCase {
    private let productRepository: any ProductRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ProductError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(id: ProductID, profile: ProductProfile) async throws -> Product {
        try Task.checkCancellation()
        return try await productRepository.updateProduct(id: id, profile: profile)
    }
}

extension UpdateProductUseCase {
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
