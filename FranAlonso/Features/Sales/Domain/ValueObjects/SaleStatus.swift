import Foundation

/// The execution state of service work represented by a sale line.
enum SaleLineStatus: String, Codable, Equatable {
    /// Work on the service has not started.
    case upcoming

    /// Work on the service is currently underway.
    case inProgress

    /// Work is finished; a sale awaits payment only after every line reaches this state.
    case completed
}

/// A payment method recorded as part of a sale's payment metadata.
enum PaymentMethod: String, Codable, Equatable {
    case cash
    case card
}

/// The lifecycle state of a sale and the metadata accumulated after payment.
///
/// Payment, document, and reversal metadata is retained across later states so
/// retries can be checked for idempotency without rewriting commercial snapshots.
enum SaleStatus: Codable, Equatable {
    /// The sale exists, but service work has not started.
    case draft

    /// Service work has started and at least one line remains incomplete.
    case inProgress

    /// Every line is complete and no payment has been recorded.
    case awaitingPayment

    /// Payment is recorded, but no billing document has been attached.
    ///
    /// - Parameters:
    ///   - paymentID: The stable identifier of the payment operation.
    ///   - method: The recorded payment method.
    ///   - paidAt: The recorded payment timestamp.
    case awaitingDocument(
        paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    )

    /// Payment and billing document metadata are recorded and the sale is closed.
    ///
    /// Only a later compensating void may change this lifecycle state.
    /// - Parameters:
    ///   - paymentID: The stable identifier of the payment operation.
    ///   - method: The recorded payment method.
    ///   - paidAt: The recorded payment timestamp.
    ///   - documentID: The stable identifier of the attached billing document.
    ///   - closedAt: The recorded closure timestamp.
    case closed(
        paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date,
        documentID: BillingDocumentID,
        closedAt: Date
    )

    /// A closed sale reversed through a terminal compensating operation.
    ///
    /// The original commercial, payment, and document history remains intact.
    /// - Parameters:
    ///   - paymentID: The stable identifier of the original payment operation.
    ///   - method: The original recorded payment method.
    ///   - paidAt: The original recorded payment timestamp.
    ///   - documentID: The stable identifier of the original billing document.
    ///   - closedAt: The original recorded closure timestamp.
    ///   - reversalID: The stable identifier of the compensating operation.
    ///   - voidedAt: The effective timestamp of the compensating void.
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
