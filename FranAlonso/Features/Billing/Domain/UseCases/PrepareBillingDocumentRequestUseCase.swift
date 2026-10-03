import Foundation

/// Seals local document input without allocating a number, contacting a repository, or closing the sale.
struct PrepareBillingDocumentRequestUseCase {
    private let requestIDFactory: @Sendable () -> BillingDocumentRequestID
    private let documentIDFactory: @Sendable () -> BillingDocumentID
    private let clock: @Sendable () -> Date

    /// Validation precedes identity generation; tickets discard unused fiscal input.
    /// Historical requests remain readable.
    func callAsFunction(
        sale: Sale,
        kind: BillingDocumentKind,
        recipientInput: BillingFiscalRecipientInput? = nil
    ) throws -> BillingDocumentRequest {
        switch sale.status {
        case .awaitingDocument:
            break
        case .closed, .voided:
            throw BillingDocumentError.terminalSale
        case .draft, .inProgress, .awaitingPayment:
            throw BillingDocumentError.requiresPayment
        }
        let requestedAt = clock()
        guard requestedAt.timeIntervalSinceReferenceDate.isFinite else { throw BillingDocumentError.invalidTimestamp }
        let recipient: BillingFiscalRecipient?
        switch kind {
        case .ticket:
            recipient = nil
        case .invoice:
            recipient = try BillingFiscalRecipient(recipientInput ?? BillingFiscalRecipientInput())
        }
        return try BillingDocumentRequest(
            id: requestIDFactory(),
            documentID: documentIDFactory(),
            sale: sale,
            kind: kind,
            requestedAt: requestedAt,
            fiscalRecipient: recipient
        )
    }
}

extension PrepareBillingDocumentRequestUseCase {
    init(
        makeRequestID: @escaping @Sendable () -> BillingDocumentRequestID = {
            BillingDocumentRequestID(rawValue: UUID())
        },
        makeDocumentID: @escaping @Sendable () -> BillingDocumentID = { BillingDocumentID(rawValue: UUID()) },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.init(requestIDFactory: makeRequestID, documentIDFactory: makeDocumentID, clock: now)
    }
}
