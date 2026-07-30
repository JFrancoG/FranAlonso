import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services synchronization engine")
struct ServiceSyncEngineTests {
    @Test("Repeated push and pull converges without local or remote duplicates")
    func repeatedPushAndPullConvergesWithoutDuplicates() async throws {
        let container = try syncEngineContainer()
        let service = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000001"
            ).rawValue,
            name: "Convergent service"
        )
        let operationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000001"
        )
        try ServiceLocalDataSource().persistPendingUpsert(
            service,
            operationID: operationID,
            in: ModelContext(container)
        )
        let remote = ServiceSyncRemoteFake()
        let engine = ServiceSyncEngine(
            persistenceActor: ServicePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ServiceObservationSignal()
        )

        try await engine.synchronize()
        try await engine.synchronize()

        let verificationContext = ModelContext(container)
        #expect(
            try ServiceLocalDataSource().fetchAll(in: verificationContext)
                == [service]
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServicePendingUpsertModel>()
            ) == 0
        )
        #expect(await remote.recordCount == 1)
        #expect(
            await remote.record(for: service.id.rawValue)?.version
                == .versioned(
                    revision: 1,
                    lastOperationID: operationID
                )
        )
        #expect(await remote.receivedOperationIDs == [operationID])
        #expect(
            await remote.requestedCursors == [
                nil,
                ServiceSyncCursor(changeSequence: 0)
            ]
        )
    }

    @MainActor
    @Test("An edit created while A awaits acknowledgement remains visible and later converges")
    func editDuringAcknowledgementRemainsVisibleAndConverges() async throws {
        let container = try syncEngineContainer()
        let serviceID = try syncEngineServiceID(
            "54000000-0000-0000-0000-000000000002"
        )
        let ancestor = try makeService(
            id: serviceID.rawValue,
            name: "Ancestor A"
        )
        let descendant = try makeService(
            id: serviceID.rawValue,
            name: "Descendant B"
        )
        let ancestorOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000002"
        )
        let descendantOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000003"
        )
        let localDataSource = ServiceLocalDataSource()
        try localDataSource.persistPendingUpsert(
            ancestor,
            operationID: ancestorOperationID,
            in: container.mainContext
        )
        let acknowledgementGate = ServiceSyncAcknowledgementGate()
        let remote = ServiceSyncRemoteFake(acknowledgementGate: acknowledgementGate)
        let engine = ServiceSyncEngine(
            persistenceActor: ServicePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ServiceObservationSignal()
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
            FetchDescriptor<ServicePendingUpsertModel>()
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
                FetchDescriptor<ServicePendingUpsertModel>()
            ) == 0
        )
        #expect(
            await remote.record(for: serviceID.rawValue)?.version
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
        let service = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000004"
            ).rawValue,
            name: "Delete through engine"
        )
        let remoteSeedOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000005"
        )
        let remote = ServiceSyncRemoteFake(
            records: [
                ServiceRemoteRecord(
                    service: try ServiceDTO(service),
                    version: .versioned(
                        revision: 1,
                        lastOperationID: remoteSeedOperationID
                    ),
                    changeSequence: 1
                )
            ]
        )
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let engine = ServiceSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: ServiceObservationSignal()
        )
        try await engine.synchronize()
        let deleteOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000006"
        )
        try await persistenceActor.persistPendingDelete(
            service.id,
            operationID: deleteOperationID
        )

        try await engine.synchronize()

        #expect(try await persistenceActor.fetchAll().isEmpty)
        #expect(try await persistenceActor.pendingOperations().isEmpty)
        let remoteRecord = try #require(
            await remote.record(for: service.id.rawValue)
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
        let localService = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000005"
            ).rawValue,
            name: "Pending push"
        )
        let remoteService = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000006"
            ).rawValue,
            name: "Committed pull"
        )
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let observationSignal = ServiceObservationSignal()
        try await persistenceActor.persistPendingUpsert(
            localService,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000007"
            )
        )
        let repository = DefaultServiceRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let stream = await repository.observeServices()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [localService])
        let remote = ServiceSyncFailingPushRemote(
            record: ServiceRemoteRecord(
                service: try ServiceDTO(remoteService),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000008"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = ServiceSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: observationSignal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: ServiceRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(
            try await observation.next() == [remoteService, localService]
        )
        #expect(
            try await persistenceActor.cursor()
                == ServiceSyncCursor(changeSequence: 1)
        )
    }

    @Test("A committed delete is signalled before a later push fails")
    func committedDeleteIsSignalledBeforeLaterPushFails() async throws {
        let container = try syncEngineContainer()
        let dataSource = ServiceLocalDataSource()
        let deletedService = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000007"
            ).rawValue,
            name: "Committed deletion"
        )
        let failingService = try makeService(
            id: try syncEngineServiceID(
                "54000000-0000-0000-0000-000000000008"
            ).rawValue,
            name: "Later failure"
        )
        try dataSource.upsert(
            deletedService,
            in: ModelContext(container)
        )
        try dataSource.persistPendingDelete(
            deletedService.id,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )
        try dataSource.persistPendingUpsert(
            failingService,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000010"
            ),
            in: ModelContext(container)
        )
        let signal = ServiceSyncChangeSignalSpy()
        let engine = ServiceSyncEngine(
            persistenceActor: ServicePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: ServiceSyncDeleteThenFailRemote(),
            observationSignal: signal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: ServiceRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(await signal.publishCount == 2)
        #expect(
            try dataSource.fetchAll(in: ModelContext(container))
                == [failingService]
        )
    }

    @Test("A push conflict blocks descendants without replacing the root snapshots")
    func pushConflictBlocksDescendantsAndPreservesRoot() async throws {
        let container = try syncEngineContainer()
        let dataSource = ServiceLocalDataSource()
        let serviceID = try syncEngineServiceID(
            "54000000-0000-0000-0000-000000000009"
        )
        let root = try makeService(
            id: serviceID.rawValue,
            name: "Root snapshot A"
        )
        let descendant = try makeService(
            id: serviceID.rawValue,
            name: "Descendant snapshot B"
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
        let concurrentRemote = try makeService(
            id: serviceID.rawValue,
            name: "Concurrent remote"
        )
        let remote = ServiceSyncPushConflictRemote(
            record: ServiceRemoteRecord(
                service: try ServiceDTO(concurrentRemote),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000013"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = ServiceSyncEngine(
            persistenceActor: ServicePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: ServiceObservationSignal()
        )

        try await engine.synchronize()

        #expect(await remote.receivedOperationIDs == [rootOperationID])
        let conflict = try #require(
            ModelContext(container).fetch(
                FetchDescriptor<ServiceSyncConflictModel>()
            ).only
        )
        #expect(conflict.operationID == rootOperationID)
        let expectedRoot = try ServiceDTO(root)
        #expect(try conflict.decodeLocalService() == expectedRoot)
    }
}

private actor ServiceSyncChangeSignalSpy: ServiceChangeSignaling {
    private var count = 0

    var publishCount: Int { count }

    func publishChange() {
        count += 1
    }
}

private actor ServiceSyncRemoteFake: ServiceRemoteDataSource {
    private var records: [UUID: ServiceRemoteRecord]
    private var operationIDs: [UUID] = []
    private let acknowledgementGate: ServiceSyncAcknowledgementGate?
    private let policy = ServiceSyncPolicy()
    private var changeSequence: Int64
    private var cursors: [ServiceSyncCursor?] = []

    init(
        records: [ServiceRemoteRecord] = [],
        acknowledgementGate: ServiceSyncAcknowledgementGate? = nil
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
    var requestedCursors: [ServiceSyncCursor?] { cursors }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        cursors.append(cursor)
        let records = records.values.filter { record in
            guard let cursor else { return true }
            return (record.changeSequence ?? 0) > cursor.changeSequence
        }.sorted { $0.id > $1.id }
        return ServiceRemoteChangeBatch(
            records: records,
            nextCursor: ServiceSyncCursor(changeSequence: changeSequence)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.serviceID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            changeSequence += 1
            let sequencedRecord = ServiceRemoteRecord(
                content: nextRecord.content,
                version: nextRecord.version,
                changeSequence: changeSequence
            )
            records[operation.serviceID] = sequencedRecord
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

    func record(for serviceID: UUID) -> ServiceRemoteRecord? {
        records[serviceID]
    }
}

private actor ServiceSyncFailingPushRemote: ServiceRemoteDataSource {
    private let record: ServiceRemoteRecord

    init(record: ServiceRemoteRecord) {
        self.record = record
    }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        ServiceRemoteChangeBatch(
            records: cursor == nil ? [record] : [],
            nextCursor: ServiceSyncCursor(changeSequence: 1)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        throw ServiceRemoteDataSourceError.unavailable
    }
}

private actor ServiceSyncDeleteThenFailRemote: ServiceRemoteDataSource {
    private var changeSequence: Int64 = 0
    private var mutationCount = 0

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        ServiceRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        mutationCount += 1
        if mutationCount > 1 {
            throw ServiceRemoteDataSourceError.unavailable
        }
        guard case .delete(let delete) = operation else {
            throw ServiceRemoteDataSourceError.unexpected
        }
        changeSequence += 1
        return .applied(
            ServiceRemoteRecord(
                content: .tombstone(serviceID: delete.serviceID),
                version: .versioned(
                    revision: 1,
                    lastOperationID: delete.operationID
                ),
                changeSequence: changeSequence
            )
        )
    }
}

private actor ServiceSyncPushConflictRemote: ServiceRemoteDataSource {
    private let record: ServiceRemoteRecord
    private var operationIDs: [UUID] = []

    init(record: ServiceRemoteRecord) {
        self.record = record
    }

    var receivedOperationIDs: [UUID] { operationIDs }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        ServiceRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        operationIDs.append(operation.operationID)
        return .conflict(.baseChanged, record)
    }
}

private actor ServiceSyncAcknowledgementGate {
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
            ServiceModel.self,
            ServicePendingUpsertModel.self,
            ServicePendingDeleteModel.self,
            ServiceRemoteStateModel.self,
            ServiceSyncConflictModel.self,
            ServiceSyncCursorModel.self,
            ServiceSyncRetryModel.self
        ])
    )
}

private let syncEngineImmediateTiming = SyncTiming(
    now: { Date.now },
    sleep: { _ in },
    jitterFactor: { 1 }
)

private func syncEngineServiceID(_ value: String) throws -> ServiceID {
    ServiceID(rawValue: try syncEngineUUID(value))
}

private func syncEngineUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
