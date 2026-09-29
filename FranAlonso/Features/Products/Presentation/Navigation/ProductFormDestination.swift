import Foundation

/// Identifies one form session independently of the product being created or edited.
/// A new session prevents a delayed dismissal from closing a reopened form.
struct ProductFormDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: UUID
    let productID: ProductID
    let mode: Mode
}
