import Foundation

/// Builds the canonical manual command shared by repository and caller-context acceptance routes.
struct PrepareStockAdjustmentUseCase {
    /// Validates the signed delta, reason and timestamp before any persistence route is invoked.
    func callAsFunction(
        id: StockMovementID,
        productID: ProductID,
        quantityDelta: Int,
        reason: String,
        occurredAt: Date
    ) throws -> StockMovement {
        try StockMovement(
            id: id,
            productID: productID,
            quantityDelta: quantityDelta,
            reason: reason,
            occurredAt: occurredAt,
            origin: .manual(reference: id)
        )
    }
}
