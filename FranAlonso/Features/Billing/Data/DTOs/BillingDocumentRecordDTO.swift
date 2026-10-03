import Foundation

/// Versioned, exact transport of the immutable paid request; Sale retains its own payload version.
struct BillingDocumentRequestDTO: Codable, Equatable {
    let payloadVersion: Int
    let id: String
    let documentID: String
    let kind: BillingDocumentKind
    let requestedAt: SaleTimestampDTO
    let sale: SaleDTO

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case payloadVersion, id, documentID, kind, requestedAt, sale
    }
}

extension BillingDocumentRequestDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            id: try container.decode(String.self, forKey: .id),
            documentID: try container.decode(String.self, forKey: .documentID),
            kind: try container.decode(BillingDocumentKind.self, forKey: .kind),
            requestedAt: try container.decode(SaleTimestampDTO.self, forKey: .requestedAt),
            sale: try container.decode(SaleDTO.self, forKey: .sale)
        )
    }

    init(_ request: BillingDocumentRequest) throws {
        self.init(
            payloadVersion: 1,
            id: request.id.rawValue.uuidString,
            documentID: request.documentID.rawValue.uuidString,
            kind: request.kind,
            requestedAt: try SaleTimestampDTO(request.requestedAt),
            sale: try SaleDTO(request.sale)
        )
    }

    /// Revalidates the paid lifecycle, exact timestamps, commercial snapshot and canonical path identities.
    func toDomain() throws -> BillingDocumentRequest {
        guard payloadVersion == 1 else { throw BillingDocumentReservationError.invalidResponse }
        do {
            return try BillingDocumentRequest(
                id: BillingDocumentRequestID(rawValue: billingTransportUUID(id)),
                documentID: BillingDocumentID(rawValue: billingTransportUUID(documentID)),
                sale: sale.toDomain(),
                kind: kind,
                requestedAt: requestedAt.date
            )
        } catch {
            throw BillingDocumentReservationError.invalidResponse
        }
    }
}

/// An immutable allocation; a nil issuedAt exists only in an uncommitted server-timestamp write plan.
struct BillingDocumentRecordDTO: Codable, Equatable {
    let payloadVersion: Int
    let request: BillingDocumentRequestDTO
    let series: BillingDocumentSeries
    let number: Int64
    let issuedAt: SaleTimestampDTO?

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case payloadVersion, request, series, number, issuedAt
    }
}

extension BillingDocumentRecordDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            request: try container.decode(BillingDocumentRequestDTO.self, forKey: .request),
            series: try container.decode(BillingDocumentSeries.self, forKey: .series),
            number: try container.decode(Int64.self, forKey: .number),
            issuedAt: try container.decodeIfPresent(SaleTimestampDTO.self, forKey: .issuedAt)
        )
    }

    /// A missing server timestamp cannot masquerade as a confirmed allocation.
    func toDomain() throws -> BillingDocument {
        guard payloadVersion == 1, let issuedAt, let value = Int(exactly: number) else {
            throw BillingDocumentReservationError.invalidResponse
        }
        do {
            return try BillingDocument.numbered(
                request: request.toDomain(),
                number: BillingDocumentNumber(series: series, value: value),
                issuedAt: issuedAt.date
            )
        } catch {
            throw BillingDocumentReservationError.invalidResponse
        }
    }
}

/// Protects request identity independently of the document's identity.
struct BillingRequestBindingDTO: Codable, Equatable {
    let payloadVersion: Int
    let requestID: String
    let documentID: String

    private enum CodingKeys: String, CodingKey, CaseIterable { case payloadVersion, requestID, documentID }
}

extension BillingRequestBindingDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            requestID: try container.decode(String.self, forKey: .requestID),
            documentID: try container.decode(String.self, forKey: .documentID)
        )
    }
}

/// The last committed number for exactly one independent family.
struct BillingCounterDTO: Codable, Equatable {
    let payloadVersion: Int
    let series: BillingDocumentSeries
    let lastNumber: Int64

    private enum CodingKeys: String, CodingKey, CaseIterable { case payloadVersion, series, lastNumber }
}

extension BillingCounterDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            series: try container.decode(BillingDocumentSeries.self, forKey: .series),
            lastNumber: try container.decode(Int64.self, forKey: .lastNumber)
        )
    }
}

/// Unknown fields cannot be discarded while deciding whether an immutable remote payload is equivalent.
func requireBillingPayloadKeys(_ decoder: any Decoder, allowed: [String]) throws {
    let container = try decoder.container(keyedBy: BillingPayloadKey.self)
    guard Set(container.allKeys.map(\.stringValue)).isSubset(of: Set(allowed)) else {
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Unsupported Billing payload fields.")
        )
    }
}

private struct BillingPayloadKey: CodingKey {
    let stringValue: String
    let intValue: Int?
}

extension BillingPayloadKey {
    init?(stringValue: String) { self.init(stringValue: stringValue, intValue: nil) }
    init?(intValue: Int) { self.init(stringValue: String(intValue), intValue: intValue) }
}

private func billingTransportUUID(_ value: String) throws -> UUID {
    guard let uuid = UUID(uuidString: value), uuid.uuidString == value else {
        throw BillingDocumentReservationError.invalidResponse
    }
    return uuid
}
