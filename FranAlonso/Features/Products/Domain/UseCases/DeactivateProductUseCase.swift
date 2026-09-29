/// Makes a product inactive without deleting its profile or references.
struct DeactivateProductUseCase {
    private let productRepository: any ProductRepository

    /// Checks cancellation before local acceptance; the repository outcome remains authoritative afterward.
    /// - Throws: `ProductError` for local rejection, or `CancellationError` before acceptance.
    func callAsFunction(_ id: ProductID) async throws {
        try Task.checkCancellation()
        try await productRepository.deactivateProduct(id)
    }
}

extension DeactivateProductUseCase {
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
