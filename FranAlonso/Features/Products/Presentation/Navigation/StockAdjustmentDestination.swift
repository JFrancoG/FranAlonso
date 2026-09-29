import Foundation

/// Identifies one adjustment session independently of its product and eventual movement.
struct StockAdjustmentDestination: Identifiable, Equatable {
    let id: UUID
    let productID: ProductID
}
