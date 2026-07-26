actor InMemoryProductRepository: ProductRepository {
    private var products: [Product]

    init(products: [Product] = []) {
        self.products = products
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(products)
            continuation.finish()
        }
    }

    func saveProduct(_ product: Product) async throws {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        } else {
            products.append(product)
        }
    }
}
