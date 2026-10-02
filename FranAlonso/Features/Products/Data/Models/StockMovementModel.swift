import Foundation
import SwiftData

/// An immutable, versioned inventory event with separate mutable synchronization acceptance.
/// No persisted total accompanies the event; quantity is derived from accepted movements.
@Model
final class StockMovementModel {
    #Index<StockMovementModel>([\.productID])

    @Attribute(.unique) private(set) var id: UUID
    private(set) var productID: UUID
    private(set) var payloadVersion: Int
    private(set) var payloadData: Data
    private(set) var isPendingSync: Bool

    init(
        id: UUID,
        productID: UUID,
        payloadVersion: Int,
        payloadData: Data,
        isPendingSync: Bool
    ) {
        self.id = id
        self.productID = productID
        self.payloadVersion = payloadVersion
        self.payloadData = payloadData
        self.isPendingSync = isPendingSync
    }
}

extension StockMovementModel {
    /// Retains manual payload v1 and stores original sale consumption as v2 without changing the model shape.
    convenience init(_ movement: StockMovement) throws {
        self.init(
            id: movement.id.rawValue,
            productID: movement.productID.rawValue,
            payloadVersion: movement.origin.payloadVersion,
            payloadData: try JSONEncoder().encode(movement),
            isPendingSync: true
        )
    }

    /// Marks only transport acceptance; immutable business fields and payload bytes are untouched.
    func acknowledgeSync() {
        if isPendingSync {
            isPendingSync = false
        }
    }

    /// Rejects unsupported or inconsistent storage before exposing a detached Domain value.
    func toDomain() throws -> StockMovement {
        guard payloadVersion == 1 || payloadVersion == 2 else { throw StockError.storageFailure }
        do {
            let movement = try JSONDecoder().decode(StockMovement.self, from: payloadData)
            guard movement.origin.payloadVersion == payloadVersion,
                  movement.id.rawValue == id, movement.productID.rawValue == productID else {
                throw StockError.storageFailure
            }
            return movement
        } catch {
            throw StockError.storageFailure
        }
    }
}

private extension StockMovementOrigin {
    var payloadVersion: Int {
        switch self {
        case .manual: 1
        case .sale: 2
        }
    }
}
