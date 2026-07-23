/// Persists validated product snapshots through the local-first boundary.
struct SaveProductUseCase {
    private let productRepository: any ProductRepository

    /// Saves a product locally without waiting for remote synchronization.
    ///
    /// - Parameter product: The validated product snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func callAsFunction(_ product: Product) async throws {
        try await productRepository.saveProduct(product)
    }
}

extension SaveProductUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that persists product snapshots.
    init(repository: any ProductRepository) {
        self.init(productRepository: repository)
    }
}
