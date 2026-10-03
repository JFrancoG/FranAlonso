import Foundation

/// A violation of payment, allocation, or recovery invariants.
enum BillingDocumentError: Error, Equatable {
    case incompatibleSeries(expected: BillingDocumentSeries, actual: BillingDocumentSeries)
    case requiresPayment
    case terminalSale
    case invalidTimestamp
    case conflictingRequest
    case conflictingDocument
    case invalidLocalTransition
}

/// The numbered record returned by an authority for one immutable paid request.
///
/// This value records an allocation; it neither allocates numbers nor proves a final PDF
/// exists. Local pending/failed intentions belong to `BillingDocumentLocalState`.
struct BillingDocument: Identifiable, Codable, Equatable {
    let request: BillingDocumentRequest
    let issuedAt: Date
    private let storedNumber: BillingDocumentNumber

    var id: BillingDocumentID { request.documentID }
    var saleID: SaleID { request.saleID }
    var kind: BillingDocumentKind { request.kind }
    var number: BillingDocumentNumber { storedNumber }

    private enum CodingKeys: String, CodingKey {
        case request, number, issuedAt
    }
}

extension BillingDocument {
    /// Materializes an authority's confirmed allocation without changing the request.
    /// The finite authority timestamp is retained exactly; it is not compared with
    /// payment metadata captured by a device's independent clock.
    ///
    /// - Throws: `BillingDocumentError` when series or issue time are incompatible.
    static func numbered(
        request: BillingDocumentRequest,
        number: BillingDocumentNumber,
        issuedAt: Date
    ) throws -> BillingDocument {
        guard number.series == request.kind.series else {
            throw BillingDocumentError.incompatibleSeries(expected: request.kind.series, actual: number.series)
        }
        guard issuedAt.timeIntervalSinceReferenceDate.isFinite else { throw BillingDocumentError.invalidTimestamp }
        return BillingDocument(request: request, issuedAt: issuedAt, storedNumber: number)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try Self.numbered(
            request: container.decode(BillingDocumentRequest.self, forKey: .request),
            number: container.decode(BillingDocumentNumber.self, forKey: .number),
            issuedAt: container.decode(Date.self, forKey: .issuedAt)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request, forKey: .request)
        try container.encode(number, forKey: .number)
        try container.encode(issuedAt, forKey: .issuedAt)
    }
}
