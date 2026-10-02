/// Reads one local quantity per linked product, in first-occurrence order.
/// The snapshots are advisory and are neither atomic across products nor an inventory reservation.
struct GetSaleStockQuantitiesUseCase {
    let repository: any StockRepository

    /// Omits professional lines and repeated product reads without mutating the stock ledger.
    /// - Throws: Repository errors or cancellation, including cancellation after a suspended read.
    func callAsFunction(lines: [SaleLine]) async throws -> [ProductID: Int] {
        try Task.checkCancellation()
        var quantities: [ProductID: Int] = [:]
        for line in lines {
            guard let productID = line.linkedProductID, quantities[productID] == nil else { continue }
            try Task.checkCancellation()
            let quantity = try await repository.quantity(for: productID)
            try Task.checkCancellation()
            quantities[productID] = quantity
        }
        return quantities
    }
}
