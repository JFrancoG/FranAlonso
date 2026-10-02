import Foundation
import SwiftData

/// Retains full authoritative acceptance so remote absence never republishes an acknowledged event.
@Model
final class StockRemoteStateModel {
    @Attribute(.unique) private(set) var movementID: UUID
    private(set) var payloadVersion: Int
    private(set) var recordData: Data

    init(movementID: UUID, payloadVersion: Int, recordData: Data) {
        self.movementID = movementID
        self.payloadVersion = payloadVersion
        self.recordData = recordData
    }
}
