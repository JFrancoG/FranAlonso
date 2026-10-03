import Foundation

/// Identifies one local document-selection session without retaining another sale snapshot.
struct BillingDocumentDestination: Identifiable, Equatable {
    let id: UUID
    let saleID: SaleID
}
