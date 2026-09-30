import SwiftData

/// Adds an append-only stock ledger without altering the historical business or synchronization tables.
struct StockMovementsSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        ClientDocumentsSchema.models + [StockMovementModel.self]
    }
}
