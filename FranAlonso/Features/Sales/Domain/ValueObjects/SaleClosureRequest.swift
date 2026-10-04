import Foundation

/// An explicit local closure command retaining the paid snapshot and the existing document request identity.
struct SaleClosureRequest: Equatable {
    private let storedExpected: Sale
    private let storedRequestID: BillingDocumentRequestID
    private let storedClosedAt: Date

    var expected: Sale { storedExpected }
    var requestID: BillingDocumentRequestID { storedRequestID }
    var closedAt: Date { storedClosedAt }
}

extension SaleClosureRequest {
    /// Captures one paid command; replay retains the closure timestamp already accepted by the local source.
    /// - Throws: `SaleClosureError` for unpaid snapshots or a nonfinite proposed date.
    init(expected: Sale, requestID: BillingDocumentRequestID, closedAt: Date) throws {
        guard closedAt.timeIntervalSinceReferenceDate.isFinite else { throw SaleClosureError.invalidTimestamp }
        switch expected.status {
        case .awaitingDocument, .closed, .voided:
            break
        case .draft, .inProgress, .awaitingPayment:
            throw SaleClosureError.requiresPayment
        }
        self.init(storedExpected: expected, storedRequestID: requestID, storedClosedAt: closedAt)
    }
}
