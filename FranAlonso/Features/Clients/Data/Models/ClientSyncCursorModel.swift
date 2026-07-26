import SwiftData

/// The last Clients change sequence committed with its complete remote batch.
@Model
final class ClientSyncCursorModel {
    @Attribute(.unique) private(set) var feedID: String
    private(set) var changeSequence: Int64

    init(feedID: String, changeSequence: Int64) {
        self.feedID = feedID
        self.changeSequence = changeSequence
    }

    /// Advances the cursor after its remote batch has been applied in this context.
    func advance(to changeSequence: Int64) {
        self.changeSequence = changeSequence
    }
}
