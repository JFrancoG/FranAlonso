import Foundation

/// A violation of a billing document's family and numbering state.
enum BillingDocumentError: Error, Equatable {
    /// A definitive number belongs to a different independent fiscal series.
    case incompatibleSeries(
        expected: BillingDocumentSeries,
        actual: BillingDocumentSeries
    )
}

/// The numbering state of a billing document request.
enum BillingDocumentStatus: Codable, Equatable {
    /// The request is durable but has no definitive number while offline or awaiting authority.
    case pendingNumber(requestID: BillingDocumentRequestID)

    /// The numbering authority has returned a definitive series value.
    case numbered(
        requestID: BillingDocumentRequestID,
        number: BillingDocumentNumber,
        issuedAt: Date
    )

    /// The stable identifier shared by retries of this numbering request.
    var requestID: BillingDocumentRequestID {
        switch self {
        case let .pendingNumber(requestID),
             let .numbered(requestID, _, _):
            requestID
        }
    }

    /// The definitive number, or `nil` while allocation remains pending.
    var number: BillingDocumentNumber? {
        switch self {
        case .pendingNumber:
            nil
        case let .numbered(_, number, _):
            number
        }
    }

    /// The authority's issue timestamp, or `nil` while allocation remains pending.
    var issuedAt: Date? {
        switch self {
        case .pendingNumber:
            nil
        case let .numbered(_, _, issuedAt):
            issuedAt
        }
    }
}

/// A billing document snapshot linked to one paid sale and one idempotent request.
struct BillingDocument: Identifiable, Codable, Equatable {
    let id: BillingDocumentID
    let saleID: SaleID
    let kind: BillingDocumentKind
    private let storedStatus: BillingDocumentStatus

    var status: BillingDocumentStatus {
        storedStatus
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case saleID
        case kind
        case status
    }
}

extension BillingDocument {
    /// Creates a durable billing request without inventing a definitive local number.
    ///
    /// - Parameters:
    ///   - id: The stable identity that the sale will retain when it closes.
    ///   - saleID: The paid sale for which the document is requested.
    ///   - kind: The requested ticket or invoice family.
    ///   - requestID: The stable identifier reused by allocation retries.
    /// - Returns: A document whose numbering remains pending.
    static func pendingNumber(
        id: BillingDocumentID,
        saleID: SaleID,
        kind: BillingDocumentKind,
        requestID: BillingDocumentRequestID
    ) -> BillingDocument {
        BillingDocument(
            id: id,
            saleID: saleID,
            kind: kind,
            storedStatus: .pendingNumber(requestID: requestID)
        )
    }

    /// Materializes the definitive result returned by the numbering authority.
    ///
    /// The request identifier is retained so repeated allocations can resolve to
    /// the same document without a second fiscal number.
    ///
    /// - Parameters:
    ///   - id: The stable identity of the billing document.
    ///   - saleID: The paid sale represented by the document.
    ///   - kind: The ticket or invoice family requested for the sale.
    ///   - requestID: The stable identifier used for the allocation request.
    ///   - number: The definitive number returned by the authority.
    ///   - issuedAt: The timestamp at which the authority issued the document.
    /// - Returns: A numbered billing-document snapshot.
    /// - Throws: `BillingDocumentError.incompatibleSeries` when the number was
    ///   allocated from another document family's series.
    static func numbered(
        id: BillingDocumentID,
        saleID: SaleID,
        kind: BillingDocumentKind,
        requestID: BillingDocumentRequestID,
        number: BillingDocumentNumber,
        issuedAt: Date
    ) throws -> BillingDocument {
        try ensureSeriesIsCompatible(kind: kind, status: .numbered(
            requestID: requestID,
            number: number,
            issuedAt: issuedAt
        ))

        return BillingDocument(
            id: id,
            saleID: saleID,
            kind: kind,
            storedStatus: .numbered(
                requestID: requestID,
                number: number,
                issuedAt: issuedAt
            )
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(BillingDocumentKind.self, forKey: .kind)
        let status = try container.decode(BillingDocumentStatus.self, forKey: .status)

        try Self.ensureSeriesIsCompatible(kind: kind, status: status)

        self.init(
            id: try container.decode(BillingDocumentID.self, forKey: .id),
            saleID: try container.decode(SaleID.self, forKey: .saleID),
            kind: kind,
            storedStatus: status
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(saleID, forKey: .saleID)
        try container.encode(kind, forKey: .kind)
        try container.encode(status, forKey: .status)
    }

    private static func ensureSeriesIsCompatible(
        kind: BillingDocumentKind,
        status: BillingDocumentStatus
    ) throws {
        guard let number = status.number else {
            return
        }
        guard number.series == kind.series else {
            throw BillingDocumentError.incompatibleSeries(
                expected: kind.series,
                actual: number.series
            )
        }
    }
}
