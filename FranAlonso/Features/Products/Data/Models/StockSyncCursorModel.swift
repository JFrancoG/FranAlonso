import Foundation
import SwiftData

/// Commits the Stock feed position together with accepted ledger and conflict records.
@Model
final class StockSyncCursorModel {
    @Attribute(.unique) private(set) var feedID: String
    private(set) var changeSequence: Int64

    init(feedID: String, changeSequence: Int64) {
        self.feedID = feedID
        self.changeSequence = changeSequence
    }

    func advance(to sequence: Int64) {
        changeSequence = sequence
    }
}
