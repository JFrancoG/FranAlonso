import Foundation
import SwiftData

/// An immutable, versioned inventory event awaiting the future stock synchronization flow.
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
    /// Creates the first payload version without changing any Product synchronization state.
    convenience init(_ movement: StockMovement) throws {
        self.init(
            id: movement.id.rawValue,
            productID: movement.productID.rawValue,
            payloadVersion: 1,
            payloadData: try JSONEncoder().encode(movement),
            isPendingSync: true
        )
    }

    /// Rejects unsupported or inconsistent storage before exposing a detached Domain value.
    func toDomain() throws -> StockMovement {
        guard payloadVersion == 1 else { throw StockError.storageFailure }
        do {
            let movement = try JSONDecoder().decode(StockMovement.self, from: payloadData)
            guard movement.id.rawValue == id, movement.productID.rawValue == productID else {
                throw StockError.storageFailure
            }
            return movement
        } catch {
            throw StockError.storageFailure
        }
    }
}
