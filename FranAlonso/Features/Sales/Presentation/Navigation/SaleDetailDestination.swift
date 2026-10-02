import Foundation

/// Identifies a read-only historical presentation independently of its sale.
struct SaleDetailDestination: Identifiable, Hashable {
    let id: UUID
    let saleID: SaleID
}
