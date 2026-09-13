import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client documents schema migration")
struct ClientDocumentsSchemaMigrationTests {
    @Test("Raw 1.0.0 preserves every family and legacy consent without inventing documents")
    func rawBaselinePreservesRowsPayloadBytesAndLegacyConsentAfterTwoOpenings() throws {
        try withPhaseFiveMigrationStore { storeURL in
            let fixture: PhaseFiveMigrationFixture
            let payloads: [String: ClientDocumentsMigrationPayload]
            let legacyReference = try ClientConsentReference(rawValue: "legacy/consents/baseline-signed.pdf")

            do {
                let container = try rawPhaseFiveMigrationContainer(at: storeURL)
                let context = ModelContext(container)
                fixture = try insertPhaseFiveMigrationRows(
                    in: context,
                    clientStatus: .active(consentReference: legacyReference)
                )
                try context.save()
                payloads = try preservedPayloads(in: ModelContext(container))
            }

            do {
                let container = try clientDocumentsMigrationContainer(at: storeURL)
                let context = ModelContext(container)
                try verifyPhaseFiveMigrationRows(in: context, fixture: fixture)
                #expect(try preservedPayloads(in: context) == payloads)
                let migratedClient = try documentMigrationOnly(ClientModel.self, in: context).toDomain()
                #expect(migratedClient.status == .active(consentReference: legacyReference))
                #expect(try context.fetch(FetchDescriptor<ClientDocumentDraftModel>()).isEmpty)
                #expect(try context.fetch(FetchDescriptor<ClientSignedDocumentModel>()).isEmpty)
            }

            let reopened = try clientDocumentsMigrationContainer(at: storeURL)
            let context = ModelContext(reopened)
            try verifyPhaseFiveMigrationRows(in: context, fixture: fixture)
            #expect(try preservedPayloads(in: context) == payloads)
            #expect(try context.fetch(FetchDescriptor<ClientDocumentDraftModel>()).isEmpty)
            #expect(try context.fetch(FetchDescriptor<ClientSignedDocumentModel>()).isEmpty)
        }
    }

    @Test("An unknown 1.0.0 shape fails closed and its original row remains readable")
    func unknownBaselineIsRejectedWithoutDestructiveFallback() throws {
        try withPhaseFiveMigrationStore { storeURL in
            let unknownSchema = Schema([ClientModel.self])
            let client = Client.draft(
                id: ClientID(rawValue: try #require(UUID(uuidString: "85000000-0000-0000-0000-000000000001"))),
                displayName: "Unknown store must survive"
            )

            do {
                let container = try documentMigrationContainer(for: unknownSchema, at: storeURL)
                let context = ModelContext(container)
                context.insert(ClientModel(client))
                try context.save()
            }

            #expect(throws: (any Error).self) {
                try clientDocumentsMigrationContainer(at: storeURL)
            }

            let reopened = try documentMigrationContainer(for: unknownSchema, at: storeURL)
            #expect(try documentMigrationOnly(ClientModel.self, in: ModelContext(reopened)).toDomain() == client)
        }
    }
}

private struct ClientDocumentsMigrationPayload: Equatable {
    let bytes: Data?
    let version: Int?
}

private func clientDocumentsMigrationContainer(at storeURL: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: ClientDocumentsSchema.self)
    let configuration = ModelConfiguration(
        "ClientDocumentsMigration",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

private func documentMigrationContainer(for schema: Schema, at storeURL: URL) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "UnknownDocumentMigrationOrigin",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [configuration])
}

private func documentMigrationOnly<Model: PersistentModel>(
    _ type: Model.Type,
    in context: ModelContext
) throws -> Model {
    let rows = try context.fetch(FetchDescriptor<Model>())
    try #require(rows.count == 1)
    return try #require(rows.first)
}

private func preservedPayloads(in context: ModelContext) throws -> [String: ClientDocumentsMigrationPayload] {
    let clientUpsert = try documentMigrationOnly(ClientPendingUpsertModel.self, in: context)
    let clientDelete = try documentMigrationOnly(ClientPendingDeleteModel.self, in: context)
    let clientRemote = try documentMigrationOnly(ClientRemoteStateModel.self, in: context)
    let clientConflict = try documentMigrationOnly(ClientSyncConflictModel.self, in: context)
    let productUpsert = try documentMigrationOnly(ProductPendingUpsertModel.self, in: context)
    let productDelete = try documentMigrationOnly(ProductPendingDeleteModel.self, in: context)
    let productRemote = try documentMigrationOnly(ProductRemoteStateModel.self, in: context)
    let productConflict = try documentMigrationOnly(ProductSyncConflictModel.self, in: context)
    let serviceUpsert = try documentMigrationOnly(ServicePendingUpsertModel.self, in: context)
    let serviceDelete = try documentMigrationOnly(ServicePendingDeleteModel.self, in: context)
    let serviceRemote = try documentMigrationOnly(ServiceRemoteStateModel.self, in: context)
    let serviceConflict = try documentMigrationOnly(ServiceSyncConflictModel.self, in: context)
    let sale = try documentMigrationOnly(SaleModel.self, in: context)
    let saleUpsert = try documentMigrationOnly(SalePendingUpsertModel.self, in: context)
    let saleDiscard = try documentMigrationOnly(SalePendingDiscardModel.self, in: context)
    let saleRemote = try documentMigrationOnly(SaleRemoteStateModel.self, in: context)
    let saleConflict = try documentMigrationOnly(SaleSyncConflictModel.self, in: context)

    return [
        "clients.upsert.base": .init(bytes: clientUpsert.baseData, version: clientUpsert.baseVersion),
        "clients.upsert.payload": .init(bytes: clientUpsert.payloadData, version: clientUpsert.payloadVersion),
        "clients.delete.base": .init(bytes: clientDelete.baseData, version: clientDelete.baseVersion),
        "clients.remote": .init(bytes: clientRemote.recordData, version: clientRemote.recordVersion),
        "clients.conflict.base": .init(bytes: clientConflict.baseData, version: clientConflict.payloadVersion),
        "clients.conflict.local": .init(bytes: clientConflict.localClientData, version: clientConflict.payloadVersion),
        "clients.conflict.remote": .init(
            bytes: clientConflict.remoteRecordData,
            version: clientConflict.payloadVersion
        ),
        "products.upsert.base": .init(bytes: productUpsert.baseData, version: productUpsert.baseVersion),
        "products.upsert.payload": .init(bytes: productUpsert.payloadData, version: productUpsert.payloadVersion),
        "products.delete.base": .init(bytes: productDelete.baseData, version: productDelete.baseVersion),
        "products.remote": .init(bytes: productRemote.recordData, version: productRemote.recordVersion),
        "products.conflict.base": .init(bytes: productConflict.baseData, version: productConflict.payloadVersion),
        "products.conflict.local": .init(
            bytes: productConflict.localProductData,
            version: productConflict.payloadVersion
        ),
        "products.conflict.remote": .init(
            bytes: productConflict.remoteRecordData,
            version: productConflict.payloadVersion
        ),
        "services.upsert.base": .init(bytes: serviceUpsert.baseData, version: serviceUpsert.baseVersion),
        "services.upsert.payload": .init(bytes: serviceUpsert.payloadData, version: serviceUpsert.payloadVersion),
        "services.delete.base": .init(bytes: serviceDelete.baseData, version: serviceDelete.baseVersion),
        "services.remote": .init(bytes: serviceRemote.recordData, version: serviceRemote.recordVersion),
        "services.conflict.base": .init(bytes: serviceConflict.baseData, version: serviceConflict.payloadVersion),
        "services.conflict.local": .init(
            bytes: serviceConflict.localServiceData,
            version: serviceConflict.payloadVersion
        ),
        "services.conflict.remote": .init(
            bytes: serviceConflict.remoteRecordData,
            version: serviceConflict.payloadVersion
        ),
        "sales.lines": .init(bytes: sale.linesData, version: sale.linesPayloadVersion),
        "sales.upsert.base": .init(bytes: saleUpsert.baseData, version: saleUpsert.baseVersion),
        "sales.upsert.payload": .init(bytes: saleUpsert.payloadData, version: saleUpsert.payloadVersion),
        "sales.discard.base": .init(bytes: saleDiscard.baseData, version: saleDiscard.baseVersion),
        "sales.remote": .init(bytes: saleRemote.recordData, version: saleRemote.recordVersion),
        "sales.conflict.base": .init(bytes: saleConflict.baseData, version: saleConflict.payloadVersion),
        "sales.conflict.local": .init(bytes: saleConflict.localSaleData, version: saleConflict.payloadVersion),
        "sales.conflict.remote": .init(bytes: saleConflict.remoteRecordData, version: saleConflict.payloadVersion)
    ]
}
