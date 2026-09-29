/// Creates an active product without overwriting an existing identity.
struct CreateProductUseCase {
    private let productRepository: any ProductRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ProductError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(id: ProductID, profile: ProductProfile) async throws -> Product {
        try Task.checkCancellation()
        return try await productRepository.createProduct(id: id, profile: profile)
    }
}

extension CreateProductUseCase {
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
