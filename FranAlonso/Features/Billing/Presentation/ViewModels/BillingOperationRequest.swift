import Foundation

/// A semantic caller-owned task intention; the screen supplies its context only while executing the operation.
struct BillingOperationRequest: Equatable {
    enum Operation: Equatable {
        case load, prepare, generate, closeSale
        case recoverFamily(BillingDocumentKind)
    }

    let id: UUID
    let operation: Operation
}
