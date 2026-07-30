import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services schema migration")
struct ServiceSchemaMigrationTests {
    @Test("The exact 14-model Clients and Products store reopens with seven empty Service tables")
    func clientsAndProductsStoreReopensWithEmptyServiceTables() throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-05.10b-Service-Migration-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let storeURL = directoryURL.appending(
            path: "Clients-and-Products.store",
            directoryHint: .notDirectory
        )
        let fixture = try writeFourteenModelStore(at: storeURL)
        let configuration = ModelConfiguration(
            "PhaseFiveTenBServices",
            schema: .franAlonso,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let reopened = try ModelContainer(
            for: Schema.franAlonso,
            configurations: [configuration]
        )
        let context = ModelContext(reopened)

        try verifyClientRows(in: context, fixture: fixture.client)
        try verifyProductRows(in: context, fixture: fixture.product)
        try verifyEmptyServiceRows(in: context)
    }
}

private struct FourteenModelFixture {
    let client: ClientMigrationFixture
    let product: ProductMigrationFixture
}

private struct ClientMigrationFixture {
    let value: Client
    let dto: ClientDTO
    let upsertBase: ClientRemoteBase
    let deleteBase: ClientRemoteBase
    let record: ClientRemoteRecord
    let conflictReason: ClientSyncConflictReason
    let cursor: Int64
    let retry: SyncRetryState
}

private struct ProductMigrationFixture {
    let value: Product
    let dto: ProductDTO
    let upsertBase: ProductRemoteBase
    let deleteBase: ProductRemoteBase
    let record: ProductRemoteRecord
    let conflictReason: ProductSyncConflictReason
    let cursor: Int64
    let retry: SyncRetryState
}

private func writeFourteenModelStore(
    at storeURL: URL
) throws -> FourteenModelFixture {
    let oldSchema = Schema([
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
        ProductSyncRetryModel.self
    ])
    let configuration = ModelConfiguration(
        "PhaseFiveTenProducts",
        schema: oldSchema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    let container = try ModelContainer(
        for: oldSchema,
        configurations: [configuration]
    )
    let context = ModelContext(container)
    let clientFixture = try insertClientRows(in: context)
    let productFixture = try insertProductRows(in: context)
    try context.save()

    return FourteenModelFixture(
        client: clientFixture,
        product: productFixture
    )
}

private func insertClientRows(
    in context: ModelContext
) throws -> ClientMigrationFixture {
    let clientID = migrationUUID("71000000-0000-0000-0000-000000000001")
    let client = Client.draft(
        id: ClientID(rawValue: clientID),
        displayName: "Published Clients snapshot"
    )
    let dto = ClientDTO(client)
    let upsertBase = ClientRemoteBase.versioned(10)
    let deleteBase = ClientRemoteBase.versioned(11)
    let upsertOperationID = migrationUUID(
        "71000000-0000-0000-0000-000000000002"
    )
    let record = ClientRemoteRecord(
        client: dto,
        version: .versioned(
            revision: 12,
            lastOperationID: migrationUUID(
                "71000000-0000-0000-0000-000000000003"
            )
        ),
        changeSequence: 13
    )
    let conflictReason = ClientSyncConflictReason.baseChanged
    let cursor: Int64 = 14
    let retry = try SyncRetryState(
        scope: .pull,
        backoffStep: 2,
        notBefore: Date(timeIntervalSinceReferenceDate: 710),
        lastRecoverableCategory: .unavailable
    )

    context.insert(ClientModel(client))
    context.insert(
        try ClientPendingUpsertModel(
            clientID: clientID,
            operationID: upsertOperationID,
            base: upsertBase,
            payload: dto
        )
    )
    context.insert(
        try ClientPendingDeleteModel(
            clientID: clientID,
            operationID: migrationUUID(
                "71000000-0000-0000-0000-000000000004"
            ),
            predecessorOperationID: upsertOperationID,
            base: deleteBase
        )
    )
    context.insert(try ClientRemoteStateModel(record: record))
    context.insert(
        ClientSyncConflictModel(
            clientID: clientID,
            operationID: upsertOperationID,
            reasonRawValue: conflictReason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(upsertBase),
            localClientData: try JSONEncoder().encode(dto),
            remoteRecordData: try JSONEncoder().encode(record)
        )
    )
    context.insert(
        ClientSyncCursorModel(
            feedID: "clients",
            changeSequence: cursor
        )
    )
    context.insert(ClientSyncRetryModel(retry))

    return ClientMigrationFixture(
        value: client,
        dto: dto,
        upsertBase: upsertBase,
        deleteBase: deleteBase,
        record: record,
        conflictReason: conflictReason,
        cursor: cursor,
        retry: retry
    )
}

private func insertProductRows(
    in context: ModelContext
) throws -> ProductMigrationFixture {
    let productID = migrationUUID("72000000-0000-0000-0000-000000000001")
    let product = Product.testSnapshot(
        id: ProductID(rawValue: productID),
        name: "Published Products snapshot"
    )
    let dto = ProductDTO(product)
    let upsertBase = ProductRemoteBase.versioned(20)
    let deleteBase = ProductRemoteBase.versioned(21)
    let upsertOperationID = migrationUUID(
        "72000000-0000-0000-0000-000000000002"
    )
    let record = ProductRemoteRecord(
        product: dto,
        version: .versioned(
            revision: 22,
            lastOperationID: migrationUUID(
                "72000000-0000-0000-0000-000000000003"
            )
        ),
        changeSequence: 23
    )
    let conflictReason = ProductSyncConflictReason.baseChanged
    let cursor: Int64 = 24
    let retry = try SyncRetryState(
        scope: .operation(upsertOperationID),
        backoffStep: 3,
        notBefore: Date(timeIntervalSinceReferenceDate: 720),
        lastRecoverableCategory: .deadlineExceeded
    )

    context.insert(ProductModel(product))
    context.insert(
        try ProductPendingUpsertModel(
            productID: productID,
            operationID: upsertOperationID,
            base: upsertBase,
            payload: dto
        )
    )
    context.insert(
        try ProductPendingDeleteModel(
            productID: productID,
            operationID: migrationUUID(
                "72000000-0000-0000-0000-000000000004"
            ),
            predecessorOperationID: upsertOperationID,
            base: deleteBase
        )
    )
    context.insert(try ProductRemoteStateModel(record: record))
    context.insert(
        ProductSyncConflictModel(
            productID: productID,
            operationID: upsertOperationID,
            reasonRawValue: conflictReason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(upsertBase),
            localProductData: try JSONEncoder().encode(dto),
            remoteRecordData: try JSONEncoder().encode(record)
        )
    )
    context.insert(
        ProductSyncCursorModel(
            feedID: "products",
            changeSequence: cursor
        )
    )
    context.insert(ProductSyncRetryModel(retry))

    return ProductMigrationFixture(
        value: product,
        dto: dto,
        upsertBase: upsertBase,
        deleteBase: deleteBase,
        record: record,
        conflictReason: conflictReason,
        cursor: cursor,
        retry: retry
    )
}

private func verifyClientRows(
    in context: ModelContext,
    fixture: ClientMigrationFixture
) throws {
    let model = try #require(
        context.fetch(FetchDescriptor<ClientModel>()).migrationOnly
    )
    #expect(try model.toDomain() == fixture.value)
    let upsert = try #require(
        context.fetch(FetchDescriptor<ClientPendingUpsertModel>()).migrationOnly
    )
    #expect(try upsert.decodeBase() == fixture.upsertBase)
    #expect(try upsert.decodePayload() == fixture.dto)
    let deletion = try #require(
        context.fetch(FetchDescriptor<ClientPendingDeleteModel>()).migrationOnly
    )
    #expect(try deletion.decodeBase() == fixture.deleteBase)
    let remote = try #require(
        context.fetch(FetchDescriptor<ClientRemoteStateModel>()).migrationOnly
    )
    #expect(try remote.decodeRecord() == fixture.record)
    let conflict = try #require(
        context.fetch(FetchDescriptor<ClientSyncConflictModel>()).migrationOnly
    )
    #expect(try conflict.decodeReason() == fixture.conflictReason)
    #expect(try conflict.decodeBase() == fixture.upsertBase)
    #expect(try conflict.decodeLocalClient() == fixture.dto)
    #expect(try conflict.decodeRemoteRecord() == fixture.record)
    #expect(
        try context.fetch(FetchDescriptor<ClientSyncCursorModel>())
            .migrationOnly?.changeSequence == fixture.cursor
    )
    let retry = try #require(
        context.fetch(FetchDescriptor<ClientSyncRetryModel>()).migrationOnly
    )
    #expect(try retry.decodeState(for: fixture.retry.scope) == fixture.retry)
}

private func verifyProductRows(
    in context: ModelContext,
    fixture: ProductMigrationFixture
) throws {
    let model = try #require(
        context.fetch(FetchDescriptor<ProductModel>()).migrationOnly
    )
    #expect(try model.toDomain() == fixture.value)
    let upsert = try #require(
        context.fetch(FetchDescriptor<ProductPendingUpsertModel>()).migrationOnly
    )
    #expect(try upsert.decodeBase() == fixture.upsertBase)
    #expect(try upsert.decodePayload() == fixture.dto)
    let deletion = try #require(
        context.fetch(FetchDescriptor<ProductPendingDeleteModel>()).migrationOnly
    )
    #expect(try deletion.decodeBase() == fixture.deleteBase)
    let remote = try #require(
        context.fetch(FetchDescriptor<ProductRemoteStateModel>()).migrationOnly
    )
    #expect(try remote.decodeRecord() == fixture.record)
    let conflict = try #require(
        context.fetch(FetchDescriptor<ProductSyncConflictModel>()).migrationOnly
    )
    #expect(try conflict.decodeReason() == fixture.conflictReason)
    #expect(try conflict.decodeBase() == fixture.upsertBase)
    #expect(try conflict.decodeLocalProduct() == fixture.dto)
    #expect(try conflict.decodeRemoteRecord() == fixture.record)
    #expect(
        try context.fetch(FetchDescriptor<ProductSyncCursorModel>())
            .migrationOnly?.changeSequence == fixture.cursor
    )
    let retry = try #require(
        context.fetch(FetchDescriptor<ProductSyncRetryModel>()).migrationOnly
    )
    #expect(
        try retry.decodeState(for: fixture.retry.scope) == fixture.retry
    )
}

private func verifyEmptyServiceRows(in context: ModelContext) throws {
    #expect(try context.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
    #expect(
        try context.fetchCount(FetchDescriptor<ServicePendingUpsertModel>()) == 0
    )
    #expect(
        try context.fetchCount(FetchDescriptor<ServicePendingDeleteModel>()) == 0
    )
    #expect(
        try context.fetchCount(FetchDescriptor<ServiceRemoteStateModel>()) == 0
    )
    #expect(
        try context.fetchCount(FetchDescriptor<ServiceSyncConflictModel>()) == 0
    )
    #expect(
        try context.fetchCount(FetchDescriptor<ServiceSyncCursorModel>()) == 0
    )
    #expect(
        try context.fetchCount(FetchDescriptor<ServiceSyncRetryModel>()) == 0
    )
}

private func migrationUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private extension Array {
    var migrationOnly: Element? { count == 1 ? first : nil }
}
