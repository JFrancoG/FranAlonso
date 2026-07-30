actor InMemorySaleRepository: SaleRepository {
    private var sales: [Sale]

    init(sales: [Sale] = []) {
        self.sales = sales
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(sales)
            continuation.finish()
        }
    }

    func saveSale(_ sale: Sale) async throws {
        if let index = sales.firstIndex(where: { $0.id == sale.id }) {
            sales[index] = sale
        } else {
            sales.append(sale)
        }
    }
}
