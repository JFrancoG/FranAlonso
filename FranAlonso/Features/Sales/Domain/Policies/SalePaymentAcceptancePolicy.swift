import Foundation

/// Protects captured commercial terms while accepting or exactly replaying payment metadata.
struct SalePaymentAcceptancePolicy {
    /// Returns the current snapshot for replay, preserving any later document and reversal.
    /// Initial acceptance requires full snapshot equality in the owning repository context.
    /// - Throws: `SalePaymentError.staleSale`, or the aggregate's payment validation error.
    func callAsFunction(
        expected: Sale,
        current: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) throws -> Sale {
        var candidate = expected
        try candidate.registerPayment(id: paymentID, method: method, paidAt: paidAt)
        guard current.id == expected.id,
              current.clientID == expected.clientID,
              current.createdAt == expected.createdAt,
              current.lines == expected.lines,
              current.globalDiscount == expected.globalDiscount else {
            throw SalePaymentError.staleSale
        }
        switch current.status {
        case .awaitingPayment:
            guard current == expected else { throw SalePaymentError.staleSale }
            return candidate
        case .awaitingDocument, .closed, .voided:
            var replay = current
            try replay.registerPayment(id: paymentID, method: method, paidAt: paidAt)
            return replay
        case .draft, .inProgress:
            throw SalePaymentError.staleSale
        }
    }
}
