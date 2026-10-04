import SwiftData

/// Preserves every supported local table and adds one durable billing delivery envelope.
struct BillingDocumentsSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(5, 0, 0) }
    static var models: [any PersistentModel.Type] {
        StockSyncSchema.models + [BillingDocumentDeliveryModel.self]
    }
}
