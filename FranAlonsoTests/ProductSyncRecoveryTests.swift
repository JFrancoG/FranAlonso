import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Products tombstones and durable cursor")
struct ProductSyncRecoveryTests {
    @Test("A local delete hides the product and survives a persistence actor restart")
    func localDeleteHidesProductAndSurvivesRestart() async throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let product = recoveryProduct(name: "Delete locally")
        let operationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000001"
        )
        try dataSource.upsert(product, in: ModelContext(container))
        try dataSource.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [
                    recoveryLiveRecord(
                        product: product,
                        revision: 4,
                        operationID: recoveryUUID(
                            "61000000-0000-0000-0000-000000000002"
                        ),
                        changeSequence: 7
                    )
                ],
                nextCursor: ProductSyncCursor(changeSequence: 7)
            ),
            policy: ProductSyncPolicy(),
            in: ModelContext(container)
        )

        try dataSource.persistPendingDelete(
            product.id,
            operationID: operationID,
            in: ModelContext(container)
        )

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        let restartedActor = ProductPersistenceActor(modelContainer: container)
        let operation = try #require(
            try await restartedActor.pendingOperations().only
        )
        guard case .delete(let pendingDelete) = operation else {
            Issue.record("Expected a durable pending delete")
            return
        }
        #expect(pendingDelete.operationID == operationID)
        #expect(pendingDelete.base == .versioned(4))
    }

    @Test("A remote tombstone wins over a pending upsert without losing its snapshot")
    func remoteTombstoneWinsOverPendingUpsert() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let product = recoveryProduct(name: "Pending local snapshot")
        let localOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            product,
            operationID: localOperationID,
            in: ModelContext(container)
        )
        let tombstone = recoveryTombstoneRecord(
            productID: product.id.rawValue,
            revision: 2,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000004"
            ),
            changeSequence: 8
        )

        try dataSource.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ProductSyncCursor(changeSequence: 8)
            ),
            policy: ProductSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ProductSyncConflictModel>()
            ).only
        )
        #expect(try conflict.decodeLocalProduct() == ProductDTO(product))
        #expect(try conflict.decodeRemoteRecord() == tombstone)
        #expect(
            try dataSource.cursor(in: verificationContext)
                == ProductSyncCursor(changeSequence: 8)
        )
    }

    @Test("A failed remote batch rolls back its materialization and cursor")
    func failedRemoteBatchRollsBackMaterializationAndCursor() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let validProduct = recoveryProduct(name: "Must roll back")
        let invalidDTO = ProductDTO(
            id: "not-a-uuid",
            name: "Invalid identity",
            status: .active
        )
        let invalidRecord = ProductRemoteRecord(
            content: .live(invalidDTO),
            version: .legacy,
            changeSequence: nil
        )

        #expect(throws: ProductSyncPersistenceError.entityIdentityMismatch) {
            try dataSource.reconcileRemoteBatch(
                ProductRemoteChangeBatch(
                    records: [
                        recoveryLiveRecord(
                            product: validProduct,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000005"
                            ),
                            changeSequence: 1
                        ),
                        invalidRecord
                    ],
                    nextCursor: ProductSyncCursor(changeSequence: 1)
                ),
                policy: ProductSyncPolicy(),
                in: ModelContext(container)
            )
        }

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        #expect(try dataSource.cursor(in: verificationContext) == nil)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ProductRemoteStateModel>()
            ) == 0
        )
    }

    @Test("A stale live record cannot resurrect a sequenced tombstone")
    func staleLiveRecordCannotResurrectTombstone() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let product = recoveryProduct(name: "Stale live snapshot")
        let tombstone = recoveryTombstoneRecord(
            productID: product.id.rawValue,
            revision: 5,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000006"
            ),
            changeSequence: 10
        )
        try dataSource.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ProductSyncCursor(changeSequence: 10)
            ),
            policy: ProductSyncPolicy(),
            in: ModelContext(container)
        )

        let staleLive = recoveryLiveRecord(
            product: product,
            revision: 4,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000007"
            ),
            changeSequence: 9
        )
        try dataSource.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [staleLive],
                nextCursor: ProductSyncCursor(changeSequence: 10)
            ),
            policy: ProductSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let state = try #require(
            verificationContext.fetch(
                FetchDescriptor<ProductRemoteStateModel>()
            ).only
        )
        #expect(try state.decodeRecord() == tombstone)
    }

    @Test("Pending operation identities are unique across upsert and delete storage")
    func pendingOperationIdentityIsGloballyUnique() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let firstProduct = recoveryProduct(name: "First identity")
        let secondProduct = Product.testSnapshot(
            id: ProductID(
                rawValue: recoveryUUID(
                    "60000000-0000-0000-0000-000000000099"
                )
            ),
            name: "Second identity"
        )
        let duplicateOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000008"
        )
        try dataSource.upsert(firstProduct, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            firstProduct.id,
            operationID: duplicateOperationID,
            in: ModelContext(container)
        )

        #expect(
            throws: ProductSyncPersistenceError.duplicateOperationIdentity(
                duplicateOperationID
            )
        ) {
            try dataSource.persistPendingUpsert(
                secondProduct,
                operationID: duplicateOperationID,
                in: ModelContext(container)
            )
        }
    }

    @Test("A pending deletion blocks an ordinary upsert from restoring the product")
    func pendingDeletionBlocksOrdinaryUpsert() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let product = recoveryProduct(name: "Deleted locally")
        try dataSource.upsert(product, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            product.id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )

        #expect(
            throws: ProductLocalDataSourceError
                .restoreRequiresExplicitResolution(product.id)
        ) {
            try dataSource.persistPendingUpsert(
                product,
                operationID: recoveryUUID(
                    "61000000-0000-0000-0000-000000000010"
                ),
                in: ModelContext(container)
            )
        }
    }

    @Test("Deleting a wholly unknown product remains an idempotent no-op")
    func deletingUnknownProductIsNoOp() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)

        try ProductLocalDataSource().persistPendingDelete(
            recoveryProduct(name: "Unknown").id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000011"
            ),
            in: context
        )

        #expect(!context.hasChanges)
        #expect(
            try context.fetchCount(
                FetchDescriptor<ProductPendingDeleteModel>()
            ) == 0
        )
    }

    @Test("A negative persisted cursor fails closed")
    func negativePersistedCursorFailsClosed() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)
        context.insert(
            ProductSyncCursorModel(
                feedID: "products",
                changeSequence: -1
            )
        )
        try context.save()

        #expect(throws: ProductSyncPersistenceError.invalidCursor) {
            _ = try ProductLocalDataSource().cursor(
                in: ModelContext(container)
            )
        }
    }

    @Test("A remote batch cannot advance beyond the changes it carries")
    func remoteBatchCannotSkipUnappliedSequences() throws {
        let container = try recoveryContainer()
        let dataSource = ProductLocalDataSource()
        let product = recoveryProduct(name: "Cursor jump")

        #expect(throws: ProductSyncPersistenceError.invalidCursor) {
            try dataSource.reconcileRemoteBatch(
                ProductRemoteChangeBatch(
                    records: [
                        recoveryLiveRecord(
                            product: product,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000012"
                            ),
                            changeSequence: 1
                        )
                    ],
                    nextCursor: ProductSyncCursor(changeSequence: 2)
                ),
                policy: ProductSyncPolicy(),
                in: ModelContext(container)
            )
        }

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        #expect(try dataSource.cursor(in: ModelContext(container)) == nil)
    }

    @Test("A Product record without feed metadata remains valid for bootstrap")
    func productRecordWithoutFeedMetadataRemainsValidForBootstrap() throws {
        let fixture = Data(
            #"{"product":{"name":"Bootstrap product","id":"60000000-0000-0000-0000-000000000001","status":"active"},"version":{"versioned":{"lastOperationID":"60000000-0000-0000-0000-000000000002","revision":3}}}"#.utf8
        )

        let record = try JSONDecoder().decode(
            ProductRemoteRecord.self,
            from: fixture
        )

        #expect(record.content == .live(ProductDTO(
            id: "60000000-0000-0000-0000-000000000001",
            name: "Bootstrap product",
            status: .active
        )))
        #expect(
            record.version == .versioned(
                revision: 3,
                lastOperationID: recoveryUUID(
                    "60000000-0000-0000-0000-000000000002"
                )
            )
        )
        #expect(record.changeSequence == nil)
    }

    @Test("The exact 05.9 Clients store reopens with empty Product state")
    func phaseFiveNineClientsStoreReopensWithProductSchema() throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-05.10-Product-Migration-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let storeURL = directoryURL.appending(
            path: "Clients.store",
            directoryHint: .notDirectory
        )
        let fixture = try writePhaseFiveNineClientStore(at: storeURL)
        let configuration = ModelConfiguration(
            "PhaseFiveTenProduct",
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

        let clientModel = try #require(
            context.fetch(FetchDescriptor<ClientModel>()).only
        )
        #expect(try clientModel.toDomain() == fixture.client)
        let pendingUpsert = try #require(
            context.fetch(FetchDescriptor<ClientPendingUpsertModel>()).only
        )
        #expect(try pendingUpsert.decodePayload() == ClientDTO(fixture.client))
        let pendingDelete = try #require(
            context.fetch(FetchDescriptor<ClientPendingDeleteModel>()).only
        )
        #expect(try pendingDelete.decodeBase() == .versioned(9))
        let remoteState = try #require(
            context.fetch(FetchDescriptor<ClientRemoteStateModel>()).only
        )
        #expect(try remoteState.decodeRecord() == fixture.remoteRecord)
        let conflict = try #require(
            context.fetch(FetchDescriptor<ClientSyncConflictModel>()).only
        )
        #expect(try conflict.decodeLocalClient() == ClientDTO(fixture.client))
        #expect(try conflict.decodeRemoteRecord() == fixture.remoteRecord)
        #expect(
            try context.fetch(FetchDescriptor<ClientSyncCursorModel>())
                .only?.changeSequence == 9
        )
        let retry = try #require(
            context.fetch(FetchDescriptor<ClientSyncRetryModel>()).only
        )
        #expect(
            try retry.decodeState(for: .pull) == fixture.retryState
        )

        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductRemoteStateModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductSyncConflictModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductSyncCursorModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductSyncRetryModel>()) == 0)
    }
}

private func recoveryContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

private func recoveryProduct(name: String) -> Product {
    Product.testSnapshot(
        id: ProductID(
            rawValue: recoveryUUID(
                "60000000-0000-0000-0000-000000000001"
            )
        ),
        name: name
    )
}

private func recoveryLiveRecord(
    product: Product,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) -> ProductRemoteRecord {
    ProductRemoteRecord(
        content: .live(ProductDTO(product)),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private func recoveryTombstoneRecord(
    productID: UUID,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) -> ProductRemoteRecord {
    ProductRemoteRecord(
        content: .tombstone(productID: productID),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private struct PhaseFiveNineClientFixture {
    let client: Client
    let remoteRecord: ClientRemoteRecord
    let retryState: ClientSyncRetryState
}

private func writePhaseFiveNineClientStore(
    at storeURL: URL
) throws -> PhaseFiveNineClientFixture {
    let oldSchema = Schema([
        ClientModel.self,
        ClientPendingUpsertModel.self,
        ClientPendingDeleteModel.self,
        ClientRemoteStateModel.self,
        ClientSyncConflictModel.self,
        ClientSyncCursorModel.self,
        ClientSyncRetryModel.self
    ])
    let configuration = ModelConfiguration(
        "PhaseFiveNine",
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
    let client = Client.draft(
        id: ClientID(
            rawValue: recoveryUUID(
                "62000000-0000-0000-0000-000000000001"
            )
        ),
        displayName: "Published 05.9 client"
    )
    let dto = ClientDTO(client)
    let operationID = recoveryUUID(
        "62000000-0000-0000-0000-000000000002"
    )
    let remoteRecord = ClientRemoteRecord(
        content: .live(dto),
        version: .versioned(
            revision: 9,
            lastOperationID: recoveryUUID(
                "62000000-0000-0000-0000-000000000003"
            )
        ),
        changeSequence: 9
    )
    let retryState = try ClientSyncRetryState(
        scope: .pull,
        backoffStep: 2,
        notBefore: Date(timeIntervalSinceReferenceDate: 900),
        lastRecoverableCategory: .unavailable
    )

    context.insert(ClientModel(client))
    context.insert(
        try ClientPendingUpsertModel(
            clientID: client.id.rawValue,
            operationID: operationID,
            payload: dto
        )
    )
    context.insert(
        try ClientPendingDeleteModel(
            clientID: client.id.rawValue,
            operationID: recoveryUUID(
                "62000000-0000-0000-0000-000000000004"
            ),
            predecessorOperationID: operationID,
            base: .versioned(9)
        )
    )
    context.insert(try ClientRemoteStateModel(record: remoteRecord))
    context.insert(
        ClientSyncConflictModel(
            clientID: client.id.rawValue,
            operationID: operationID,
            reasonRawValue: ClientSyncConflictReason.baseChanged.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(ClientRemoteBase.absent),
            localClientData: try JSONEncoder().encode(dto),
            remoteRecordData: try JSONEncoder().encode(remoteRecord)
        )
    )
    context.insert(ClientSyncCursorModel(feedID: "clients", changeSequence: 9))
    context.insert(ClientSyncRetryModel(retryState))
    try context.save()

    return PhaseFiveNineClientFixture(
        client: client,
        remoteRecord: remoteRecord,
        retryState: retryState
    )
}

private func recoveryUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
