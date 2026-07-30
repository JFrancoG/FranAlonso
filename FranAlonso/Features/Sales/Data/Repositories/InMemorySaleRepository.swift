/// An actor-isolated Sales repository for previews and deterministic tests.
actor InMemorySaleRepository: SaleRepository {
    private var sales: [Sale]

    init(sales: [Sale] = []) {
        self.sales = sales
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(sales)
            continuation.finish()
        }
    }

    /// Inserts a sale or replaces the snapshot with the same stable identity.
    func saveSale(_ sale: Sale) async throws {
        if let index = sales.firstIndex(where: { $0.id == sale.id }) {
            sales[index] = sale
        } else {
            sales.append(sale)
        }
    }
}
