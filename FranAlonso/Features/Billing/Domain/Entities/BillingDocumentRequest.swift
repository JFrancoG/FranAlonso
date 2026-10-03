import Foundation

/// An immutable paid-sale and optional invoice-recipient snapshot for one retryable document allocation.
struct BillingDocumentRequest: Identifiable, Codable, Equatable {
    let id: BillingDocumentRequestID
    let documentID: BillingDocumentID
    let kind: BillingDocumentKind
    let requestedAt: Date
    private let storedSale: Sale
    private let storedFiscalRecipient: BillingFiscalRecipient?

    var sale: Sale { storedSale }
    var saleID: SaleID { storedSale.id }
    var fiscalRecipient: BillingFiscalRecipient? { storedFiscalRecipient }

    private enum CodingKeys: String, CodingKey {
        case id, documentID, sale, kind, requestedAt, fiscalRecipient
    }
}

extension BillingDocumentRequest {
    /// Captures a paid sale awaiting its document; retries must retain this exact value.
    ///
    /// Terminal sales cannot create a second request. Decoding applies the same payment
    /// and finite-timestamp invariants rather than restoring unchecked persisted input.
    /// Payment precedence comes from the sale lifecycle; timestamps may originate on
    /// different devices and are preserved without comparing their wall clocks.
    /// A nil invoice recipient preserves historical requests; new preparation requires a
    /// complete fiscal snapshot. Tickets never retain fiscal recipient data.
    /// - Throws: `BillingDocumentError` for an unpaid/terminal sale or invalid request time,
    ///   or `BillingFiscalRecipientError.unexpectedRecipient` for a ticket with recipient data.
    init(
        id: BillingDocumentRequestID,
        documentID: BillingDocumentID,
        sale: Sale,
        kind: BillingDocumentKind,
        requestedAt: Date,
        fiscalRecipient: BillingFiscalRecipient? = nil
    ) throws {
        guard requestedAt.timeIntervalSinceReferenceDate.isFinite else { throw BillingDocumentError.invalidTimestamp }
        switch sale.status {
        case .awaitingDocument:
            break
        case .closed, .voided:
            throw BillingDocumentError.terminalSale
        case .draft, .inProgress, .awaitingPayment:
            throw BillingDocumentError.requiresPayment
        }
        guard kind != .ticket || fiscalRecipient == nil else { throw BillingFiscalRecipientError.unexpectedRecipient }
        self.init(
            id: id,
            documentID: documentID,
            kind: kind,
            requestedAt: requestedAt,
            storedSale: sale,
            storedFiscalRecipient: fiscalRecipient
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(BillingDocumentRequestID.self, forKey: .id),
            documentID: container.decode(BillingDocumentID.self, forKey: .documentID),
            sale: container.decode(Sale.self, forKey: .sale),
            kind: container.decode(BillingDocumentKind.self, forKey: .kind),
            requestedAt: container.decode(Date.self, forKey: .requestedAt),
            fiscalRecipient: container.decodeIfPresent(BillingFiscalRecipient.self, forKey: .fiscalRecipient)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(documentID, forKey: .documentID)
        try container.encode(sale, forKey: .sale)
        try container.encode(kind, forKey: .kind)
        try container.encode(requestedAt, forKey: .requestedAt)
        try container.encodeIfPresent(fiscalRecipient, forKey: .fiscalRecipient)
    }
}
