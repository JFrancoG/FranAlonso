import Foundation

enum SaleLineStatus: String, Codable, Equatable {
    case upcoming
    case inProgress
    case completed
}

enum PaymentMethod: String, Codable, Equatable {
    case cash
    case card
}

enum SaleStatus: Codable, Equatable {
    case draft
    case inProgress
    case awaitingPayment
    case awaitingDocument(
        paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    )
    case closed(
        paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date,
        documentID: BillingDocumentID,
        closedAt: Date
    )
    case voided(
        paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date,
        documentID: BillingDocumentID,
        closedAt: Date,
        reversalID: SaleReversalID,
        voidedAt: Date
    )
}
