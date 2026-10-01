import Foundation

/// A presentation session identity independent of the sale identity; no sale snapshot crosses navigation.
struct SaleDraftDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case create
        case editDraft
        case inspect
    }

    let id: UUID
    let saleID: SaleID
    let mode: Mode
}
