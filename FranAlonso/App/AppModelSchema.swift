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
        ])
    }
}
