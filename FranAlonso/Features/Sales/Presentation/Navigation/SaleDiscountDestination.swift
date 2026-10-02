import Foundation

/// Identifies one percentage editor without retaining another sale snapshot.
struct SaleDiscountDestination: Identifiable, Equatable {
    enum Target: Equatable {
        case line(SaleLineID)
        case global
    }

    let id: UUID
    let target: Target
}
