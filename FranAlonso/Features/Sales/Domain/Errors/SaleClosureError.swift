/// Neutral rejections at the paid-sale and retained-document acceptance boundary.
enum SaleClosureError: Error, Equatable {
    case requiresPayment, invalidTimestamp, notFound, documentNotFound, documentPending, invalidDocument
    case staleSale, conflictingDocument, unauthorized, conflict, deleted, persistenceUnavailable
}
