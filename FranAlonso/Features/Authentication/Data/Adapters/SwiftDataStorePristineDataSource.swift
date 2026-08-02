import SwiftData

/// Determines whether every model table in the published local schema is empty.
///
/// The check is fail-closed: callers may claim an unbound store only after this actor completes
/// all queries successfully and finds no row. Each query fetches at most one model.
@ModelActor
actor SwiftDataStorePristineDataSource {
    /// Returns whether the current store contains no persisted row in any schema model.
    func isPristine() throws -> Bool {
        guard try !contains(ClientModel.self) else { return false }
        guard try !contains(ClientPendingUpsertModel.self) else { return false }
        guard try !contains(ClientPendingDeleteModel.self) else { return false }
        guard try !contains(ClientRemoteStateModel.self) else { return false }
        guard try !contains(ClientSyncConflictModel.self) else { return false }
        guard try !contains(ClientSyncCursorModel.self) else { return false }
        guard try !contains(ClientSyncRetryModel.self) else { return false }
        guard try !contains(ProductModel.self) else { return false }
        guard try !contains(ProductPendingUpsertModel.self) else { return false }
        guard try !contains(ProductPendingDeleteModel.self) else { return false }
        guard try !contains(ProductRemoteStateModel.self) else { return false }
        guard try !contains(ProductSyncConflictModel.self) else { return false }
        guard try !contains(ProductSyncCursorModel.self) else { return false }
        guard try !contains(ProductSyncRetryModel.self) else { return false }
        guard try !contains(ServiceModel.self) else { return false }
        guard try !contains(ServicePendingUpsertModel.self) else { return false }
        guard try !contains(ServicePendingDeleteModel.self) else { return false }
        guard try !contains(ServiceRemoteStateModel.self) else { return false }
        guard try !contains(ServiceSyncConflictModel.self) else { return false }
        guard try !contains(ServiceSyncCursorModel.self) else { return false }
        guard try !contains(ServiceSyncRetryModel.self) else { return false }
        guard try !contains(SaleModel.self) else { return false }
        guard try !contains(SalePendingUpsertModel.self) else { return false }
        guard try !contains(SalePendingDiscardModel.self) else { return false }
        guard try !contains(SaleRemoteStateModel.self) else { return false }
        guard try !contains(SaleSyncConflictModel.self) else { return false }
        guard try !contains(SaleSyncCursorModel.self) else { return false }
        guard try !contains(SaleSyncRetryModel.self) else { return false }
        return true
    }

    private func contains<Model>(
        _ modelType: Model.Type
    ) throws -> Bool where Model: PersistentModel {
        var descriptor = FetchDescriptor<Model>()
        descriptor.fetchLimit = 1
        return try !modelContext.fetch(descriptor).isEmpty
    }
}
