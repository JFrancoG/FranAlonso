import SwiftData

/// Preserves the v3 ledger and adds only durable stock feed, conflict and retry metadata.
struct StockSyncSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }
    static var models: [any PersistentModel.Type] {
        StockMovementsSchema.models + [
            StockRemoteStateModel.self,
            StockSyncConflictModel.self,
            StockSyncCursorModel.self,
            StockSyncRetryModel.self,
        ]
    }
}
