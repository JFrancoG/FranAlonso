import Foundation

/// Accepts one manual adjustment while retaining caller-supplied identity and timestamp across retries.
struct AdjustStockUseCase {
    let repository: any StockRepository

    /// Delegates acceptance once; the repository owns identity checks, eligibility, balance and the commit boundary.
    func callAsFunction(
        id: StockMovementID,
        productID: ProductID,
        quantityDelta: Int,
        reason: String,
        occurredAt: Date
    ) async throws -> StockMovement {
        try Task.checkCancellation()
        let movement = try PrepareStockAdjustmentUseCase()(
            id: id,
            productID: productID,
            quantityDelta: quantityDelta,
            reason: reason,
            occurredAt: occurredAt
        )
        return try await repository.append(movement)
    }
}
