/// Resolves a previously selected product again instead of trusting a stale catalogue snapshot.
struct GetLinkableProductUseCase {
    private let productRepository: any ProductRepository

    /// Returns the matching active product without reserving it for a later write.
    /// - Throws: `ServiceError.linkedProductUnavailable`, the source read error or cancellation.
    func callAsFunction(_ id: ProductID) async throws -> Product {
        try Task.checkCancellation()
        let product = try await productRepository.product(id: id)
        try Task.checkCancellation()
        return try ServiceProductLinkPolicy().requireProduct(product, id: id)
    }
}

extension GetLinkableProductUseCase {
    /// Uses the same Product Domain repository as the linkable catalogue.
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
