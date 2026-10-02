import Foundation

/// A frozen advisory presentation; its identity belongs to the pending payment command.
struct SaleStockConfirmation: Identifiable, Equatable {
    struct Warning: Identifiable, Equatable {
        let id: SaleLineID
        let serviceName: String
        let projectedQuantity: Int
    }
    let id: UUID
    let warnings: [Warning]
    let stockUnavailable: Bool
}
