import SwiftData

/// The first supported SwiftData schema, matching the 05.10c store persisted as version 1.0.0.
enum PhaseFiveBaselineSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self,
            ClientSyncRetryModel.self,
            ProductModel.self,
            ProductPendingUpsertModel.self,
            ProductPendingDeleteModel.self,
            ProductRemoteStateModel.self,
            ProductSyncConflictModel.self,
            ProductSyncCursorModel.self,
            ProductSyncRetryModel.self,
            ServiceModel.self,
            ServicePendingUpsertModel.self,
            ServicePendingDeleteModel.self,
            ServiceRemoteStateModel.self,
            ServiceSyncConflictModel.self,
            ServiceSyncCursorModel.self,
            ServiceSyncRetryModel.self,
            SaleModel.self,
            SalePendingUpsertModel.self,
            SalePendingDiscardModel.self,
            SaleRemoteStateModel.self,
            SaleSyncConflictModel.self,
            SaleSyncCursorModel.self,
            SaleSyncRetryModel.self
        ]
    }
}

/// The ordered migration contract starting at the first supported phase-five store.
enum PhaseFiveSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PhaseFiveBaselineSchema.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
