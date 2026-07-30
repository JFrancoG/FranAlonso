import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Clients synchronization engine")
struct ClientSyncEngineTests {
    @Test("Repeated push and pull converges without local or remote duplicates")
    func repeatedPushAndPullConvergesWithoutDuplicates() async throws {
        let container = try syncEngineContainer()
        let client = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000001"
            ),
            displayName: "Convergent client"
        )
        let operationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000001"
        )
        try ClientLocalDataSource().persistPendingUpsert(
            client,
            operationID: operationID,
            in: ModelContext(container)
        )
        let remote = ClientSyncRemoteFake()
        let engine = ClientSyncEngine(
            persistenceActor: ClientPersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ClientObservationSignal()
        )

        try await engine.synchronize()
        try await engine.synchronize()

        let verificationContext = ModelContext(container)
        #expect(
            try ClientLocalDataSource().fetchAll(in: verificationContext)
                == [client]
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 0
        )
        #expect(await remote.recordCount == 1)
        #expect(
            await remote.record(for: client.id.rawValue)?.version
                == .versioned(
                    revision: 1,
                    lastOperationID: operationID
                )
        )
        #expect(await remote.receivedOperationIDs == [operationID])
        #expect(
            await remote.requestedCursors == [
                nil,
                ClientSyncCursor(changeSequence: 0)
            ]
        )
    }

    @MainActor
    @Test("An edit created while A awaits acknowledgement remains visible and later converges")
    func editDuringAcknowledgementRemainsVisibleAndConverges() async throws {
        let container = try syncEngineContainer()
        let clientID = try syncEngineClientID(
            "54000000-0000-0000-0000-000000000002"
        )
        let ancestor = Client.draft(id: clientID, displayName: "Ancestor A")
        let descendant = Client.draft(id: clientID, displayName: "Descendant B")
        let ancestorOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000002"
        )
        let descendantOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000003"
        )
        let localDataSource = ClientLocalDataSource()
        try localDataSource.persistPendingUpsert(
            ancestor,
            operationID: ancestorOperationID,
            in: container.mainContext
        )
        let acknowledgementGate = ClientSyncAcknowledgementGate()
        let remote = ClientSyncRemoteFake(acknowledgementGate: acknowledgementGate)
        let engine = ClientSyncEngine(
            persistenceActor: ClientPersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ClientObservationSignal()
        )

        async let firstSynchronization: Void = engine.synchronize()
        await acknowledgementGate.waitUntilBlocked()

        try localDataSource.persistPendingUpsert(
            descendant,
            operationID: descendantOperationID,
            in: container.mainContext
        )
        await acknowledgementGate.release()
        try await firstSynchronization

        let postAcknowledgementContext = ModelContext(container)
        #expect(
            try localDataSource.fetchAll(in: postAcknowledgementContext)
                == [descendant]
        )
        let pendingAfterAcknowledgement = try postAcknowledgementContext.fetch(
            FetchDescriptor<ClientPendingUpsertModel>()
        )
        let descendantOperation = try #require(
            pendingAfterAcknowledgement.only
        )
        #expect(descendantOperation.operationID == descendantOperationID)
        #expect(
            descendantOperation.predecessorOperationID
                == ancestorOperationID
        )

        try await engine.synchronize()

        let finalContext = ModelContext(container)
        #expect(try localDataSource.fetchAll(in: finalContext) == [descendant])
        #expect(
            try finalContext.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 0
        )
        #expect(
            await remote.record(for: clientID.rawValue)?.version
                == .versioned(
                    revision: 2,
                    lastOperationID: descendantOperationID
                )
        )
        #expect(
            await remote.receivedOperationIDs == [
                ancestorOperationID,
                descendantOperationID
            ]
        )
    }

    @Test("A local deletion converges to a remote tombstone and clears its chain")
    func localDeletionConvergesToRemoteTombstone() async throws {
        let container = try syncEngineContainer()
        let client = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000004"
            ),
            displayName: "Delete through engine"
        )
        let remoteSeedOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000005"
        )
        let remote = ClientSyncRemoteFake(
            records: [
                ClientRemoteRecord(
                    client: ClientDTO(client),
                    version: .versioned(
                        revision: 1,
                        lastOperationID: remoteSeedOperationID
                    ),
                    changeSequence: 1
                )
            ]
        )
        let persistenceActor = ClientPersistenceActor(
            modelContainer: container
        )
        let engine = ClientSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: ClientObservationSignal()
        )
        try await engine.synchronize()
        let deleteOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000006"
        )
        try await persistenceActor.persistPendingDelete(
            client.id,
            operationID: deleteOperationID
        )

        try await engine.synchronize()

        #expect(try await persistenceActor.fetchAll().isEmpty)
        #expect(try await persistenceActor.pendingOperations().isEmpty)
        let remoteRecord = try #require(
            await remote.record(for: client.id.rawValue)
        )
        #expect(remoteRecord.isTombstone)
        #expect(
            remoteRecord.version == .versioned(
                revision: 2,
                lastOperationID: deleteOperationID
            )
        )
        #expect(remoteRecord.changeSequence == 2)
    }

    @Test("A committed pull is observable even when the following push fails")
    func committedPullIsObservableWhenPushFails() async throws {
        let container = try syncEngineContainer()
        let localClient = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000005"
            ),
            displayName: "Pending push"
        )
        let remoteClient = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000006"
            ),
            displayName: "Committed pull"
        )
        let persistenceActor = ClientPersistenceActor(
            modelContainer: container
        )
        let observationSignal = ClientObservationSignal()
        try await persistenceActor.persistPendingUpsert(
            localClient,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000007"
            )
        )
        let repository = DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let stream = await repository.observeClients()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [localClient])
        let remote = ClientSyncFailingPushRemote(
            record: ClientRemoteRecord(
                client: ClientDTO(remoteClient),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000008"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = ClientSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: observationSignal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(
            try await observation.next() == [remoteClient, localClient]
        )
        #expect(
            try await persistenceActor.cursor()
                == ClientSyncCursor(changeSequence: 1)
        )
    }

    @Test("A committed delete is signalled before a later push fails")
    func committedDeleteIsSignalledBeforeLaterPushFails() async throws {
        let container = try syncEngineContainer()
        let dataSource = ClientLocalDataSource()
        let deletedClient = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000007"
            ),
            displayName: "Committed deletion"
        )
        let failingClient = Client.draft(
            id: try syncEngineClientID(
                "54000000-0000-0000-0000-000000000008"
            ),
            displayName: "Later failure"
        )
        try dataSource.upsert(
            deletedClient,
            in: ModelContext(container)
        )
        try dataSource.persistPendingDelete(
            deletedClient.id,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )
        try dataSource.persistPendingUpsert(
            failingClient,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000010"
            ),
            in: ModelContext(container)
        )
        let signal = ClientSyncChangeSignalSpy()
        let engine = ClientSyncEngine(
            persistenceActor: ClientPersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: ClientSyncDeleteThenFailRemote(),
            observationSignal: signal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(await signal.publishCount == 2)
        #expect(
            try dataSource.fetchAll(in: ModelContext(container))
                == [failingClient]
        )
    }

    @Test("A push conflict blocks descendants without replacing the root snapshots")
    func pushConflictBlocksDescendantsAndPreservesRoot() async throws {
        let container = try syncEngineContainer()
        let dataSource = ClientLocalDataSource()
        let clientID = try syncEngineClientID(
            "54000000-0000-0000-0000-000000000009"
        )
        let root = Client.draft(id: clientID, displayName: "Root snapshot A")
        let descendant = Client.draft(
            id: clientID,
            displayName: "Descendant snapshot B"
        )
        let rootOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000011"
        )
        let descendantOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000012"
        )
        try dataSource.persistPendingUpsert(
            root,
            operationID: rootOperationID,
            in: ModelContext(container)
        )
        try dataSource.persistPendingUpsert(
            descendant,
            operationID: descendantOperationID,
            in: ModelContext(container)
        )
        let remote = ClientSyncPushConflictRemote(
            record: ClientRemoteRecord(
                client: ClientDTO(
                    Client.draft(
                        id: clientID,
                        displayName: "Concurrent remote"
                    )
                ),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000013"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = ClientSyncEngine(
            persistenceActor: ClientPersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ClientObservationSignal()
        )

        try await engine.synchronize()

        #expect(await remote.receivedOperationIDs == [rootOperationID])
        let conflict = try #require(
            ModelContext(container).fetch(
                FetchDescriptor<ClientSyncConflictModel>()
            ).only
        )
        #expect(conflict.operationID == rootOperationID)
        #expect(try conflict.decodeLocalClient() == ClientDTO(root))
    }
}

private actor ClientSyncChangeSignalSpy: ClientChangeSignaling {
    private var count = 0

    var publishCount: Int { count }

    func publishChange() {
        count += 1
    }
}

private actor ClientSyncRemoteFake: ClientRemoteDataSource {
    private var records: [UUID: ClientRemoteRecord]
    private var operationIDs: [UUID] = []
    private let acknowledgementGate: ClientSyncAcknowledgementGate?
    private let policy = ClientSyncPolicy()
    private var changeSequence: Int64
    private var cursors: [ClientSyncCursor?] = []

    init(
        records: [ClientRemoteRecord] = [],
        acknowledgementGate: ClientSyncAcknowledgementGate? = nil
    ) {
        self.records = Dictionary(
            uniqueKeysWithValues: records.compactMap { record in
                guard let identifier = UUID(uuidString: record.id) else {
                    return nil
                }
                return (identifier, record)
            }
        )
        changeSequence = records.compactMap(\.changeSequence).max() ?? 0
        self.acknowledgementGate = acknowledgementGate
    }

    var recordCount: Int { records.count }
    var receivedOperationIDs: [UUID] { operationIDs }
    var requestedCursors: [ClientSyncCursor?] { cursors }

    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        cursors.append(cursor)
        let records = records.values.filter { record in
            guard let cursor else { return true }
            return (record.changeSequence ?? 0) > cursor.changeSequence
        }.sorted { $0.id > $1.id }
        return ClientRemoteChangeBatch(
            records: records,
            nextCursor: ClientSyncCursor(changeSequence: changeSequence)
        )
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.clientID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            changeSequence += 1
            let sequencedRecord = ClientRemoteRecord(
                content: nextRecord.content,
                version: nextRecord.version,
                changeSequence: changeSequence
            )
            records[operation.clientID] = sequencedRecord
            if let acknowledgementGate {
                await acknowledgementGate.blockOnce()
            }
            return .applied(sequencedRecord)
        case .alreadyApplied(let record):
            return .alreadyApplied(record)
        case .conflict(let reason, let record):
            return .conflict(reason, record)
        case .invalid(let error):
            throw error
        }
    }

    func record(for clientID: UUID) -> ClientRemoteRecord? {
        records[clientID]
    }
}

private actor ClientSyncFailingPushRemote: ClientRemoteDataSource {
    private let record: ClientRemoteRecord

    init(record: ClientRemoteRecord) {
        self.record = record
    }

    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        ClientRemoteChangeBatch(
            records: cursor == nil ? [record] : [],
            nextCursor: ClientSyncCursor(changeSequence: 1)
        )
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        throw ClientRemoteDataSourceError.unavailable
    }
}

private actor ClientSyncDeleteThenFailRemote: ClientRemoteDataSource {
    private var changeSequence: Int64 = 0
    private var mutationCount = 0

    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        ClientRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ClientSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        mutationCount += 1
        if mutationCount > 1 {
            throw ClientRemoteDataSourceError.unavailable
        }
        guard case .delete(let delete) = operation else {
            throw ClientRemoteDataSourceError.unexpected
        }
        changeSequence += 1
        return .applied(
            ClientRemoteRecord(
                content: .tombstone(clientID: delete.clientID),
                version: .versioned(
                    revision: 1,
                    lastOperationID: delete.operationID
                ),
                changeSequence: changeSequence
            )
        )
    }
}

private actor ClientSyncPushConflictRemote: ClientRemoteDataSource {
    private let record: ClientRemoteRecord
    private var operationIDs: [UUID] = []

    init(record: ClientRemoteRecord) {
        self.record = record
    }

    var receivedOperationIDs: [UUID] { operationIDs }

    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        ClientRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ClientSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        operationIDs.append(operation.operationID)
        return .conflict(.baseChanged, record)
    }
}

private actor ClientSyncAcknowledgementGate {
    private var shouldBlock = true
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func blockOnce() async {
        guard shouldBlock else {
            return
        }
        shouldBlock = false
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        guard shouldBlock else {
            return
        }
        await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private func syncEngineContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self,
            ClientSyncRetryModel.self
        ])
    )
}

private let syncEngineImmediateTiming = SyncTiming(
    now: { Date.now },
    sleep: { _ in },
    jitterFactor: { 1 }
)

private func syncEngineClientID(_ value: String) throws -> ClientID {
    ClientID(rawValue: try syncEngineUUID(value))
}

private func syncEngineUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
