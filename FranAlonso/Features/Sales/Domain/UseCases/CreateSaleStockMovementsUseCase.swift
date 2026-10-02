/// Creates original sale-line consumption through the append-only local ledger, without registering payment.
/// Payment and stock must be composed atomically by the later payment boundary, never as two UI writes.
struct CreateSaleStockMovementsUseCase {
    private let stockRepository: any StockRepository
    private let policy = SaleStockMovementPolicy()

    /// Validates every candidate before writing, then accepts each line durably in display order.
    /// Failure/cancellation may leave an accepted prefix; retry the same snapshot/payment to complete missing lines.
    /// Exact replay preserves original events. The last accepted append remains success after late cancellation.
    /// - Throws: Sale validation, StockError, or cancellation before the next line's acceptance.
    func callAsFunction(sale: Sale, paymentID: PaymentID) async throws -> [StockMovement] {
        try Task.checkCancellation()
        let movements = try policy(sale: sale, paymentID: paymentID)
        var accepted: [StockMovement] = []
        for movement in movements {
            try Task.checkCancellation()
            accepted.append(try await stockRepository.append(movement))
        }
        return accepted
    }
}

extension CreateSaleStockMovementsUseCase {
    init(repository: any StockRepository) {
        self.init(stockRepository: repository)
    }
}
