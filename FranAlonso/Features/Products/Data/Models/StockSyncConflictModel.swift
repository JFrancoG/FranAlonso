import Foundation
import SwiftData

/// Retains both divergent immutable payloads without replacing the original ledger event.
@Model
final class StockSyncConflictModel {
    @Attribute(.unique) private(set) var movementID: UUID
    private(set) var payloadVersion: Int
    private(set) var conflictData: Data

    init(movementID: UUID, payloadVersion: Int, conflictData: Data) {
        self.movementID = movementID
        self.payloadVersion = payloadVersion
        self.conflictData = conflictData
    }
}
