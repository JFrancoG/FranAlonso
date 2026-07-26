import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Clients tombstones and durable cursor")
struct ClientSyncRecoveryTests {
    @Test("A local delete hides the client and survives a persistence actor restart")
    func localDeleteHidesClientAndSurvivesRestart() async throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let client = recoveryClient(name: "Delete locally")
        let operationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000001"
        )
        try dataSource.upsert(client, in: ModelContext(container))
        try dataSource.reconcileRemoteBatch(
            ClientRemoteChangeBatch(
                records: [
                    recoveryLiveRecord(
                        client: client,
                        revision: 4,
                        operationID: recoveryUUID(
                            "61000000-0000-0000-0000-000000000002"
                        ),
                        changeSequence: 7
                    )
                ],
                nextCursor: ClientSyncCursor(changeSequence: 7)
            ),
            policy: ClientSyncPolicy(),
            in: ModelContext(container)
        )

        try dataSource.persistPendingDelete(
            client.id,
            operationID: operationID,
            in: ModelContext(container)
        )

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        let restartedActor = ClientPersistenceActor(modelContainer: container)
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
        let dataSource = ClientLocalDataSource()
        let client = recoveryClient(name: "Pending local snapshot")
        let localOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            client,
            operationID: localOperationID,
            in: ModelContext(container)
        )
        let tombstone = recoveryTombstoneRecord(
            clientID: client.id.rawValue,
            revision: 2,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000004"
            ),
            changeSequence: 8
        )

        try dataSource.reconcileRemoteBatch(
            ClientRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ClientSyncCursor(changeSequence: 8)
            ),
            policy: ClientSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ClientSyncConflictModel>()
            ).only
        )
        #expect(try conflict.decodeLocalClient() == ClientDTO(client))
        #expect(try conflict.decodeRemoteRecord() == tombstone)
        #expect(
            try dataSource.cursor(in: verificationContext)
                == ClientSyncCursor(changeSequence: 8)
        )
    }

    @Test("A failed remote batch rolls back its materialization and cursor")
    func failedRemoteBatchRollsBackMaterializationAndCursor() throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let validClient = recoveryClient(name: "Must roll back")
        let invalidDTO = ClientDTO(
            id: "not-a-uuid",
            displayName: "Invalid identity",
            taxIdentifier: nil,
            billingAddress: nil,
            status: .draft,
            consentReference: nil
        )
        let invalidRecord = ClientRemoteRecord(
            content: .live(invalidDTO),
            version: .legacy,
            changeSequence: nil
        )

        #expect(throws: ClientSyncPersistenceError.entityIdentityMismatch) {
            try dataSource.reconcileRemoteBatch(
                ClientRemoteChangeBatch(
                    records: [
                        recoveryLiveRecord(
                            client: validClient,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000005"
                            ),
                            changeSequence: 1
                        ),
                        invalidRecord
                    ],
                    nextCursor: ClientSyncCursor(changeSequence: 1)
                ),
                policy: ClientSyncPolicy(),
                in: ModelContext(container)
            )
        }

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        #expect(try dataSource.cursor(in: verificationContext) == nil)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientRemoteStateModel>()
            ) == 0
        )
    }

    @Test("A stale live record cannot resurrect a sequenced tombstone")
    func staleLiveRecordCannotResurrectTombstone() throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let client = recoveryClient(name: "Stale live snapshot")
        let tombstone = recoveryTombstoneRecord(
            clientID: client.id.rawValue,
            revision: 5,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000006"
            ),
            changeSequence: 10
        )
        try dataSource.reconcileRemoteBatch(
            ClientRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ClientSyncCursor(changeSequence: 10)
            ),
            policy: ClientSyncPolicy(),
            in: ModelContext(container)
        )

        let staleLive = recoveryLiveRecord(
            client: client,
            revision: 4,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000007"
            ),
            changeSequence: 9
        )
        try dataSource.reconcileRemoteBatch(
            ClientRemoteChangeBatch(
                records: [staleLive],
                nextCursor: ClientSyncCursor(changeSequence: 10)
            ),
            policy: ClientSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let state = try #require(
            verificationContext.fetch(
                FetchDescriptor<ClientRemoteStateModel>()
            ).only
        )
        #expect(try state.decodeRecord() == tombstone)
    }

    @Test("Pending operation identities are unique across upsert and delete storage")
    func pendingOperationIdentityIsGloballyUnique() throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let firstClient = recoveryClient(name: "First identity")
        let secondClient = Client.draft(
            id: ClientID(
                rawValue: recoveryUUID(
                    "60000000-0000-0000-0000-000000000099"
                )
            ),
            displayName: "Second identity"
        )
        let duplicateOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000008"
        )
        try dataSource.upsert(firstClient, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            firstClient.id,
            operationID: duplicateOperationID,
            in: ModelContext(container)
        )

        #expect(
            throws: ClientSyncPersistenceError.duplicateOperationIdentity(
                duplicateOperationID
            )
        ) {
            try dataSource.persistPendingUpsert(
                secondClient,
                operationID: duplicateOperationID,
                in: ModelContext(container)
            )
        }
    }

    @Test("A pending deletion blocks an ordinary upsert from restoring the client")
    func pendingDeletionBlocksOrdinaryUpsert() throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let client = recoveryClient(name: "Deleted locally")
        try dataSource.upsert(client, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            client.id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )

        #expect(
            throws: ClientLocalDataSourceError
                .restoreRequiresExplicitResolution(client.id)
        ) {
            try dataSource.persistPendingUpsert(
                client,
                operationID: recoveryUUID(
                    "61000000-0000-0000-0000-000000000010"
                ),
                in: ModelContext(container)
            )
        }
    }

    @Test("Deleting a wholly unknown client remains an idempotent no-op")
    func deletingUnknownClientIsNoOp() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)

        try ClientLocalDataSource().persistPendingDelete(
            recoveryClient(name: "Unknown").id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000011"
            ),
            in: context
        )

        #expect(!context.hasChanges)
        #expect(
            try context.fetchCount(
                FetchDescriptor<ClientPendingDeleteModel>()
            ) == 0
        )
    }

    @Test("A negative persisted cursor fails closed")
    func negativePersistedCursorFailsClosed() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)
        context.insert(
            ClientSyncCursorModel(
                feedID: "clients",
                changeSequence: -1
            )
        )
        try context.save()

        #expect(throws: ClientSyncPersistenceError.invalidCursor) {
            _ = try ClientLocalDataSource().cursor(
                in: ModelContext(container)
            )
        }
    }

    @Test("A remote batch cannot advance beyond the changes it carries")
    func remoteBatchCannotSkipUnappliedSequences() throws {
        let container = try recoveryContainer()
        let dataSource = ClientLocalDataSource()
        let client = recoveryClient(name: "Cursor jump")

        #expect(throws: ClientSyncPersistenceError.invalidCursor) {
            try dataSource.reconcileRemoteBatch(
                ClientRemoteChangeBatch(
                    records: [
                        recoveryLiveRecord(
                            client: client,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000012"
                            ),
                            changeSequence: 1
                        )
                    ],
                    nextCursor: ClientSyncCursor(changeSequence: 2)
                ),
                policy: ClientSyncPolicy(),
                in: ModelContext(container)
            )
        }

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        #expect(try dataSource.cursor(in: ModelContext(container)) == nil)
    }

    @Test("Phase 05.7 remote record bytes decode as a live record")
    func phaseFiveSevenRemoteRecordBytesRemainReadable() throws {
        let fixture = Data(
            #"{"client":{"displayName":"Legacy 05.7","id":"60000000-0000-0000-0000-000000000001","status":"draft"},"version":{"versioned":{"lastOperationID":"60000000-0000-0000-0000-000000000002","revision":3}}}"#.utf8
        )

        let record = try JSONDecoder().decode(
            ClientRemoteRecord.self,
            from: fixture
        )

        #expect(record.content == .live(ClientDTO(
            id: "60000000-0000-0000-0000-000000000001",
            displayName: "Legacy 05.7",
            taxIdentifier: nil,
            billingAddress: nil,
            status: .draft,
            consentReference: nil
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

    @Test("The published 05.7 store reopens with the 05.8 inferred schema")
    func phaseFiveSevenStoreReopensWithPhaseFiveEightSchema() throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-05.8-Migration-\(UUID())",
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
        try writePhaseFiveSevenStore(at: storeURL)
        let configuration = ModelConfiguration(
            "PhaseFiveEight",
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

        #expect(try context.fetchCount(FetchDescriptor<ClientModel>()) == 1)
        #expect(
            try context.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 1
        )
        let remoteState = try #require(
            context.fetch(FetchDescriptor<ClientRemoteStateModel>()).only
        )
        #expect(try remoteState.decodeRecord().isLive)
        let conflict = try #require(
            context.fetch(FetchDescriptor<ClientSyncConflictModel>()).only
        )
        #expect(try conflict.decodeRemoteRecord()?.isLive == true)
        #expect(
            try context.fetchCount(
                FetchDescriptor<ClientPendingDeleteModel>()
            ) == 0
        )
        #expect(
            try context.fetchCount(
                FetchDescriptor<ClientSyncCursorModel>()
            ) == 0
        )
    }
}

private func recoveryContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

private func recoveryClient(name: String) -> Client {
    Client.draft(
        id: ClientID(
            rawValue: recoveryUUID(
                "60000000-0000-0000-0000-000000000001"
            )
        ),
        displayName: name
    )
}

private func recoveryLiveRecord(
    client: Client,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) -> ClientRemoteRecord {
    ClientRemoteRecord(
        content: .live(ClientDTO(client)),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private func recoveryTombstoneRecord(
    clientID: UUID,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) -> ClientRemoteRecord {
    ClientRemoteRecord(
        content: .tombstone(clientID: clientID),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private func writePhaseFiveSevenStore(at storeURL: URL) throws {
    let oldSchema = Schema([
        ClientModel.self,
        ClientPendingUpsertModel.self,
        ClientRemoteStateModel.self,
        ClientSyncConflictModel.self
    ])
    let configuration = ModelConfiguration(
        "PhaseFiveSeven",
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
    let client = recoveryClient(name: "Published 05.7 client")
    let dto = ClientDTO(client)
    let operationID = recoveryUUID(
        "60000000-0000-0000-0000-000000000002"
    )
    let recordFixture = Data(
        #"{"client":{"displayName":"Legacy 05.7","id":"60000000-0000-0000-0000-000000000001","status":"draft"},"version":{"versioned":{"lastOperationID":"60000000-0000-0000-0000-000000000002","revision":3}}}"#.utf8
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
        ClientRemoteStateModel(
            clientID: client.id.rawValue,
            recordVersion: 1,
            recordData: recordFixture
        )
    )
    context.insert(
        ClientSyncConflictModel(
            clientID: client.id.rawValue,
            operationID: operationID,
            reasonRawValue: ClientSyncConflictReason.baseChanged.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(ClientRemoteBase.absent),
            localClientData: try JSONEncoder().encode(dto),
            remoteRecordData: recordFixture
        )
    )
    try context.save()
}

private func recoveryUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
