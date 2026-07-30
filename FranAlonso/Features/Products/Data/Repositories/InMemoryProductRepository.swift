/// An actor-isolated Products repository for previews and deterministic tests.
actor InMemoryProductRepository: ProductRepository {
    private var products: [Product]

    init(products: [Product] = []) {
        self.products = products
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(products)
            continuation.finish()
        }
    }

    /// Inserts a product or replaces the snapshot with the same stable identity.
    func saveProduct(_ product: Product) async throws {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        } else {
            products.append(product)
        }
    }
}
