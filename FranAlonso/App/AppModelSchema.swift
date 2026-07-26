import SwiftData

extension Schema {
    /// The complete SwiftData schema currently owned by Fran Alonso.
    static var franAlonso: Schema {
        Schema([
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self
        ])
    }
}
