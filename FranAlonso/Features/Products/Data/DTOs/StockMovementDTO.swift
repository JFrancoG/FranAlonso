import Foundation

/// Portable immutable inventory payload; transport version is independent of local manual/sale blobs.
struct StockMovementDTO: Codable, Equatable {
    let payloadVersion: Int
    let id: String
    let productID: String
    let quantityDelta: Int64
    let reason: String
    let occurredAt: SaleTimestampDTO
    let origin: StockMovementOriginDTO

    private enum CodingKeys: String, CodingKey {
        case payloadVersion, id, productID, quantityDelta, reason, occurredAt, origin
    }
}

extension StockMovementDTO {
    init(from decoder: any Decoder) throws {
        try stockSyncKeys(
            decoder,
            allowed: ["payloadVersion", "id", "productID", "quantityDelta", "reason", "occurredAt", "origin"]
        )
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try c.decode(Int.self, forKey: .payloadVersion),
            id: try c.decode(String.self, forKey: .id),
            productID: try c.decode(String.self, forKey: .productID),
            quantityDelta: try c.decode(Int64.self, forKey: .quantityDelta),
            reason: try c.decode(String.self, forKey: .reason),
            occurredAt: try c.decode(SaleTimestampDTO.self, forKey: .occurredAt),
            origin: try c.decode(StockMovementOriginDTO.self, forKey: .origin)
        )
        _ = try toDomain()
    }

    /// Captures every conflict-relevant field without reducing timestamp precision.
    init(_ movement: StockMovement) throws {
        self.init(
            payloadVersion: StockMovementOriginDTO(movement.origin).transportVersion,
            id: movement.id.rawValue.uuidString,
            productID: movement.productID.rawValue.uuidString,
            quantityDelta: Int64(movement.quantityDelta),
            reason: movement.reason,
            occurredAt: try SaleTimestampDTO(movement.occurredAt),
            origin: StockMovementOriginDTO(movement.origin)
        )
    }

    /// Revalidates the signed event and rejects noncanonical identity, text or unsupported transport.
    func toDomain() throws -> StockMovement {
        guard payloadVersion == origin.transportVersion, let delta = Int(exactly: quantityDelta) else {
            throw StockSyncError.invalidPayload
        }
        let movement = try StockMovement(
            id: StockMovementID(rawValue: stockSyncUUID(id)),
            productID: ProductID(rawValue: stockSyncUUID(productID)),
            quantityDelta: delta,
            reason: reason,
            occurredAt: occurredAt.date,
            origin: origin.toDomain()
        )
        guard movement.reason == reason else { throw StockSyncError.invalidPayload }
        return movement
    }
}

/// A tagged origin, preventing ambiguous or partial sale linkage on the wire.
enum StockMovementOriginDTO: Codable, Equatable {
    case manual(reference: String)
    case sale(saleID: String, lineID: String, paymentID: String)
    case saleReversal(
        saleID: String,
        lineID: String,
        paymentID: String,
        reversalID: String,
        originalMovementID: String
    )

    private enum CodingKeys: String, CodingKey {
        case kind, reference, saleID, lineID, paymentID, reversalID, originalMovementID
    }
}

extension StockMovementOriginDTO {
    init(_ origin: StockMovementOrigin) {
        switch origin {
        case .manual(let reference):
            self = .manual(reference: reference.rawValue.uuidString)
        case .sale(let saleID, let lineID, let paymentID):
            self = .sale(
                saleID: saleID.rawValue.uuidString,
                lineID: lineID.rawValue.uuidString,
                paymentID: paymentID.rawValue.uuidString
            )
        case let .saleReversal(saleID, lineID, paymentID, reversalID, originalMovementID):
            self = .saleReversal(
                saleID: saleID.rawValue.uuidString,
                lineID: lineID.rawValue.uuidString,
                paymentID: paymentID.rawValue.uuidString,
                reversalID: reversalID.rawValue.uuidString,
                originalMovementID: originalMovementID.rawValue.uuidString
            )
        }
    }

    func toDomain() throws -> StockMovementOrigin {
        switch self {
        case .manual(let reference):
            return .manual(reference: StockMovementID(rawValue: try stockSyncUUID(reference)))
        case .sale(let saleID, let lineID, let paymentID):
            return .sale(
                saleID: SaleID(rawValue: try stockSyncUUID(saleID)),
                lineID: SaleLineID(rawValue: try stockSyncUUID(lineID)),
                paymentID: PaymentID(rawValue: try stockSyncUUID(paymentID))
            )
        case let .saleReversal(saleID, lineID, paymentID, reversalID, originalMovementID):
            return .saleReversal(
                saleID: SaleID(rawValue: try stockSyncUUID(saleID)),
                lineID: SaleLineID(rawValue: try stockSyncUUID(lineID)),
                paymentID: PaymentID(rawValue: try stockSyncUUID(paymentID)),
                reversalID: SaleReversalID(rawValue: try stockSyncUUID(reversalID)),
                originalMovementID: StockMovementID(rawValue: try stockSyncUUID(originalMovementID))
            )
        }
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .kind) {
        case "manual":
            try stockSyncKeys(decoder, allowed: ["kind", "reference"])
            self = .manual(reference: try c.decode(String.self, forKey: .reference))
        case "sale":
            try stockSyncKeys(decoder, allowed: ["kind", "saleID", "lineID", "paymentID"])
            self = .sale(
                saleID: try c.decode(String.self, forKey: .saleID),
                lineID: try c.decode(String.self, forKey: .lineID),
                paymentID: try c.decode(String.self, forKey: .paymentID)
            )
        case "saleReversal":
            try stockSyncKeys(
                decoder,
                allowed: ["kind", "saleID", "lineID", "paymentID", "reversalID", "originalMovementID"]
            )
            self = .saleReversal(
                saleID: try c.decode(String.self, forKey: .saleID),
                lineID: try c.decode(String.self, forKey: .lineID),
                paymentID: try c.decode(String.self, forKey: .paymentID),
                reversalID: try c.decode(String.self, forKey: .reversalID),
                originalMovementID: try c.decode(String.self, forKey: .originalMovementID)
            )
        default:
            throw StockSyncError.invalidPayload
        }
        _ = try toDomain()
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .manual(let reference):
            try c.encode("manual", forKey: .kind)
            try c.encode(reference, forKey: .reference)
        case .sale(let saleID, let lineID, let paymentID):
            try c.encode("sale", forKey: .kind)
            try c.encode(saleID, forKey: .saleID)
            try c.encode(lineID, forKey: .lineID)
            try c.encode(paymentID, forKey: .paymentID)
        case let .saleReversal(saleID, lineID, paymentID, reversalID, originalMovementID):
            try c.encode("saleReversal", forKey: .kind)
            try c.encode(saleID, forKey: .saleID)
            try c.encode(lineID, forKey: .lineID)
            try c.encode(paymentID, forKey: .paymentID)
            try c.encode(reversalID, forKey: .reversalID)
            try c.encode(originalMovementID, forKey: .originalMovementID)
        }
    }
}

private extension StockMovementOriginDTO {
    var transportVersion: Int {
        switch self {
        case .manual, .sale: 1
        case .saleReversal: 2
        }
    }
}

/// Rejects alternate textual identities before using an identifier as a document path.
func stockSyncUUID(_ text: String) throws -> UUID {
    guard let value = UUID(uuidString: text), value.uuidString == text else { throw StockSyncError.invalidPayload }
    return value
}

private struct StockSyncCodingKey: CodingKey {
    private let keyText: String
    var stringValue: String { keyText }
    var intValue: Int? { nil }
}

extension StockSyncCodingKey {
    fileprivate init?(stringValue: String) {
        self.init(keyText: stringValue)
    }
    fileprivate init?(intValue: Int) { return nil }
}

/// Rejects unknown transport fields instead of silently dropping mutable or future representations.
func stockSyncKeys(_ decoder: any Decoder, allowed: Set<String>) throws {
    let c = try decoder.container(keyedBy: StockSyncCodingKey.self)
    guard Set(c.allKeys.map(\.stringValue)).isSubset(of: allowed) else { throw StockSyncError.invalidPayload }
}
