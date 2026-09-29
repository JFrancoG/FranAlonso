import Foundation

/// The explicit source of an inventory adjustment; manual retries retain their reference.
enum StockMovementOrigin: Codable, Equatable {
    case manual(reference: StockMovementID)
}

/// An immutable signed change in physical units, independent of prices and product availability.
///
/// Identity and the complete canonical payload determine idempotency. A reason is normalized on construction.
struct StockMovement: Identifiable, Codable, Equatable {
    let id: StockMovementID
    let productID: ProductID
    private let storedQuantityDelta: Int
    private let storedReason: String
    private let storedOccurredAt: Date
    let origin: StockMovementOrigin

    var quantityDelta: Int { storedQuantityDelta }
    var reason: String { storedReason }
    var occurredAt: Date { storedOccurredAt }

    private enum CodingKeys: String, CodingKey {
        case id, productID, origin
        case storedQuantityDelta = "quantityDelta"
        case storedReason = "reason"
        case storedOccurredAt = "occurredAt"
    }
}

extension StockMovement {
    /// Accepts a nonzero signed delta, a nonempty trimmed reason, and a finite explicit timestamp.
    /// - Throws: A neutral `StockError` for invalid input, before any persistence occurs.
    init(
        id: StockMovementID,
        productID: ProductID,
        quantityDelta: Int,
        reason: String,
        occurredAt: Date,
        origin: StockMovementOrigin
    ) throws {
        guard quantityDelta != 0 else { throw StockError.invalidDelta }
        let normalizedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedReason.isEmpty else { throw StockError.invalidReason }
        guard occurredAt.timeIntervalSinceReferenceDate.isFinite else { throw StockError.invalidDate }
        self.init(
            id: id,
            productID: productID,
            storedQuantityDelta: quantityDelta,
            storedReason: normalizedReason,
            storedOccurredAt: occurredAt,
            origin: origin
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(StockMovementID.self, forKey: .id),
            productID: container.decode(ProductID.self, forKey: .productID),
            quantityDelta: container.decode(Int.self, forKey: .storedQuantityDelta),
            reason: container.decode(String.self, forKey: .storedReason),
            occurredAt: container.decode(Date.self, forKey: .storedOccurredAt),
            origin: container.decode(StockMovementOrigin.self, forKey: .origin)
        )
    }
}
