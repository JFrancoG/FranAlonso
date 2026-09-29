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

extension InMemoryProductRepository {
    func product(id: ProductID) async throws -> Product? {
        try Task.checkCancellation()
        return products.first { $0.id == id }
    }

    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        try Task.checkCancellation()
        guard !products.contains(where: { $0.id == id }) else { throw ProductError.alreadyExists }
        let product = Product(id: id, name: profile.name, status: .active)
        products.append(product)
        return product
    }

    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        try Task.checkCancellation()
        guard let index = products.firstIndex(where: { $0.id == id }) else { throw ProductError.notFound }
        let product = Product(id: id, name: profile.name, status: products[index].status)
        products[index] = product
        return product
    }

    func deactivateProduct(_ id: ProductID) async throws {
        try Task.checkCancellation()
        guard let index = products.firstIndex(where: { $0.id == id }) else { throw ProductError.notFound }
        guard products[index].status != .inactive else { return }
        products[index] = Product(id: id, name: products[index].name, status: .inactive)
    }
}
