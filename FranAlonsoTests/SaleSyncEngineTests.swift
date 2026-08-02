import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sales synchronization engine")
struct SaleSyncEngineTests {
    @Test("Repeated push and pull converges without local or remote duplicates")
    func repeatedPushAndPullConvergesWithoutDuplicates() async throws {
        let container = try syncEngineContainer()
        let sale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000001"
            ).rawValue,
            name: "Convergent sale"
        )
        let operationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000001"
        )
        try SaleLocalDataSource().persistPendingUpsert(
            sale,
            operationID: operationID,
            in: ModelContext(container)
        )
        let remote = SaleSyncRemoteFake()
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: SaleObservationSignal()
        )

        try await engine.synchronize()
        try await engine.synchronize()

        let verificationContext = ModelContext(container)
        #expect(
            try SaleLocalDataSource().fetchAll(in: verificationContext)
                == [sale]
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<SalePendingUpsertModel>()
            ) == 0
        )
        #expect(await remote.recordCount == 1)
        #expect(
            await remote.record(for: sale.id.rawValue)?.version
                == .versioned(
                    revision: 1,
                    lastOperationID: operationID
                )
        )
        #expect(await remote.receivedOperationIDs == [operationID])
        #expect(
            await remote.requestedCursors == [
                nil,
                SaleSyncCursor(changeSequence: 0)
            ]
        )
    }

    @MainActor
    @Test("An edit created while A awaits acknowledgement remains visible and later converges")
    func editDuringAcknowledgementRemainsVisibleAndConverges() async throws {
        let container = try syncEngineContainer()
        let saleID = try syncEngineSaleID(
            "54000000-0000-0000-0000-000000000002"
        )
        let ancestor = try makeSale(
            id: saleID.rawValue,
            name: "Ancestor A"
        )
        let descendant = try makeSale(
            id: saleID.rawValue,
            name: "Descendant B"
        )
        let ancestorOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000002"
        )
        let descendantOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000003"
        )
        let localDataSource = SaleLocalDataSource()
        try localDataSource.persistPendingUpsert(
            ancestor,
            operationID: ancestorOperationID,
            in: container.mainContext
        )
        let acknowledgementGate = SaleSyncAcknowledgementGate()
        let remote = SaleSyncRemoteFake(acknowledgementGate: acknowledgementGate)
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: SaleObservationSignal()
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
            FetchDescriptor<SalePendingUpsertModel>()
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
                FetchDescriptor<SalePendingUpsertModel>()
            ) == 0
        )
        #expect(
            await remote.record(for: saleID.rawValue)?.version
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
        let sale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000004"
            ).rawValue,
            name: "Delete through engine"
        )
        let remoteSeedOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000005"
        )
        let remote = SaleSyncRemoteFake(
            records: [
                SaleRemoteRecord(
                    sale: try SaleDTO(sale),
                    version: .versioned(
                        revision: 1,
                        lastOperationID: remoteSeedOperationID
                    ),
                    changeSequence: 1
                )
            ]
        )
        let persistenceActor = SalePersistenceActor(
            modelContainer: container
        )
        let engine = SaleSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: SaleObservationSignal()
        )
        try await engine.synchronize()
        let deleteOperationID = try syncEngineUUID(
            "55000000-0000-0000-0000-000000000006"
        )
        try await persistenceActor.persistPendingDiscard(
            sale.id,
            operationID: deleteOperationID
        )

        try await engine.synchronize()

        #expect(try await persistenceActor.fetchAll().isEmpty)
        #expect(try await persistenceActor.pendingOperations().isEmpty)
        let remoteRecord = try #require(
            await remote.record(for: sale.id.rawValue)
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
        let localSale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000005"
            ).rawValue,
            name: "Pending push"
        )
        let remoteSale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000006"
            ).rawValue,
            name: "Committed pull"
        )
        let persistenceActor = SalePersistenceActor(
            modelContainer: container
        )
        let observationSignal = SaleObservationSignal()
        try await persistenceActor.persistPendingUpsert(
            localSale,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000007"
            )
        )
        let repository = DefaultSaleRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let stream = await repository.observeSales()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [localSale])
        let remote = SaleSyncFailingPushRemote(
            record: SaleRemoteRecord(
                sale: try SaleDTO(remoteSale),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000008"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = SaleSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: remote,
            observationSignal: observationSignal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: SaleRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(
            try await observation.next() == [remoteSale, localSale]
        )
        #expect(
            try await persistenceActor.cursor()
                == SaleSyncCursor(changeSequence: 1)
        )
    }

    @Test("A committed delete is signalled before a later push fails")
    func committedDeleteIsSignalledBeforeLaterPushFails() async throws {
        let container = try syncEngineContainer()
        let dataSource = SaleLocalDataSource()
        let deletedSale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000007"
            ).rawValue,
            name: "Committed deletion"
        )
        let failingSale = try makeSale(
            id: try syncEngineSaleID(
                "54000000-0000-0000-0000-000000000008"
            ).rawValue,
            name: "Later failure"
        )
        try dataSource.upsert(
            deletedSale,
            in: ModelContext(container)
        )
        try dataSource.persistPendingDiscard(
            deletedSale.id,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )
        try dataSource.persistPendingUpsert(
            failingSale,
            operationID: try syncEngineUUID(
                "55000000-0000-0000-0000-000000000010"
            ),
            in: ModelContext(container)
        )
        let signal = SaleSyncChangeSignalSpy()
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: SaleSyncDeleteThenFailRemote(),
            observationSignal: signal,
            timing: syncEngineImmediateTiming
        )

        await #expect(throws: SaleRemoteDataSourceError.unavailable) {
            try await engine.synchronize()
        }

        #expect(await signal.publishCount == 2)
        #expect(
            try dataSource.fetchAll(in: ModelContext(container))
                == [failingSale]
        )
    }

    @Test("A push conflict blocks descendants without replacing the root snapshots")
    func pushConflictBlocksDescendantsAndPreservesRoot() async throws {
        let container = try syncEngineContainer()
        let dataSource = SaleLocalDataSource()
        let saleID = try syncEngineSaleID(
            "54000000-0000-0000-0000-000000000009"
        )
        let root = try makeSale(
            id: saleID.rawValue,
            name: "Root snapshot A"
        )
        let descendant = try makeSale(
            id: saleID.rawValue,
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
        let concurrentRemote = try makeSale(
            id: saleID.rawValue,
            name: "Concurrent remote"
        )
        let remote = SaleSyncPushConflictRemote(
            record: SaleRemoteRecord(
                sale: try SaleDTO(concurrentRemote),
                version: .versioned(
                    revision: 1,
                    lastOperationID: try syncEngineUUID(
                        "55000000-0000-0000-0000-000000000013"
                    )
                ),
                changeSequence: 1
            )
        )
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(
                modelContainer: container
            ),
            remoteDataSource: remote,
            observationSignal: SaleObservationSignal()
        )

        try await engine.synchronize()

        #expect(await remote.receivedOperationIDs == [rootOperationID])
        let conflict = try #require(
            ModelContext(container).fetch(
                FetchDescriptor<SaleSyncConflictModel>()
            ).only
        )
        #expect(conflict.operationID == rootOperationID)
        let expectedRoot = try SaleDTO(root)
        #expect(try conflict.decodeLocalSale() == expectedRoot)
    }
}

private actor SaleSyncChangeSignalSpy: SaleChangeSignaling {
    private var count = 0

    var publishCount: Int { count }

    func publishChange() {
        count += 1
    }
}

private actor SaleSyncRemoteFake: SaleRemoteDataSource {
    private var records: [UUID: SaleRemoteRecord]
    private var operationIDs: [UUID] = []
    private let acknowledgementGate: SaleSyncAcknowledgementGate?
    private let policy = SaleSyncPolicy()
    private var changeSequence: Int64
    private var cursors: [SaleSyncCursor?] = []

    init(records: [SaleRemoteRecord] = [], acknowledgementGate: SaleSyncAcknowledgementGate? = nil) {
        self.records = Dictionary(
            uniqueKeysWithValues: records.compactMap { record in
                guard let identifier = UUID(uuidString: record.id) else { return nil }
                return (identifier, record)
            }
        )
        changeSequence = records.compactMap(\.changeSequence).max() ?? 0
        self.acknowledgementGate = acknowledgementGate
    }

    var recordCount: Int { records.count }
    var receivedOperationIDs: [UUID] { operationIDs }
    var requestedCursors: [SaleSyncCursor?] { cursors }

    func fetchChanges(after cursor: SaleSyncCursor?) async throws -> SaleRemoteChangeBatch {
        cursors.append(cursor)
        let records = records.values.filter { record in
            guard let cursor else { return true }
            return (record.changeSequence ?? 0) > cursor.changeSequence
        }.sorted { $0.id > $1.id }
        return SaleRemoteChangeBatch(
            records: records,
            nextCursor: SaleSyncCursor(changeSequence: changeSequence)
        )
    }

    func apply(_ operation: SalePendingOperation) async throws -> SaleRemoteMutationResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.saleID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            changeSequence += 1
            let sequencedRecord = SaleRemoteRecord(
                content: nextRecord.content,
                version: nextRecord.version,
                changeSequence: changeSequence
            )
            records[operation.saleID] = sequencedRecord
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

    func record(for saleID: UUID) -> SaleRemoteRecord? {
        records[saleID]
    }
}

private actor SaleSyncFailingPushRemote: SaleRemoteDataSource {
    private let record: SaleRemoteRecord

    init(record: SaleRemoteRecord) {
        self.record = record
    }

    func fetchChanges(after cursor: SaleSyncCursor?) async throws -> SaleRemoteChangeBatch {
        SaleRemoteChangeBatch(
            records: cursor == nil ? [record] : [],
            nextCursor: SaleSyncCursor(changeSequence: 1)
        )
    }

    func apply(_ operation: SalePendingOperation) async throws -> SaleRemoteMutationResult {
        throw SaleRemoteDataSourceError.unavailable
    }
}

private actor SaleSyncDeleteThenFailRemote: SaleRemoteDataSource {
    private var changeSequence: Int64 = 0
    private var mutationCount = 0

    func fetchChanges(after cursor: SaleSyncCursor?) async throws -> SaleRemoteChangeBatch {
        SaleRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? SaleSyncCursor(changeSequence: 0)
        )
    }

    func apply(_ operation: SalePendingOperation) async throws -> SaleRemoteMutationResult {
        mutationCount += 1
        if mutationCount > 1 {
            throw SaleRemoteDataSourceError.unavailable
        }
        guard case .discard(let delete) = operation else { throw SaleRemoteDataSourceError.unexpected }
        changeSequence += 1
        return .applied(
            SaleRemoteRecord(
                content: .tombstone(saleID: delete.saleID),
                version: .versioned(
                    revision: 1,
                    lastOperationID: delete.operationID
                ),
                changeSequence: changeSequence
            )
        )
    }
}

private actor SaleSyncPushConflictRemote: SaleRemoteDataSource {
    private let record: SaleRemoteRecord
    private var operationIDs: [UUID] = []

    init(record: SaleRemoteRecord) {
        self.record = record
    }

    var receivedOperationIDs: [UUID] { operationIDs }

    func fetchChanges(after cursor: SaleSyncCursor?) async throws -> SaleRemoteChangeBatch {
        SaleRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? SaleSyncCursor(changeSequence: 0)
        )
    }

    func apply(_ operation: SalePendingOperation) async throws -> SaleRemoteMutationResult {
        operationIDs.append(operation.operationID)
        return .conflict(.baseChanged, record)
    }
}

private actor SaleSyncAcknowledgementGate {
    private var shouldBlock = true
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func blockOnce() async {
        guard shouldBlock else { return }
        shouldBlock = false
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        guard shouldBlock else { return }
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
            SaleModel.self,
            SalePendingUpsertModel.self,
            SalePendingDiscardModel.self,
            SaleRemoteStateModel.self,
            SaleSyncConflictModel.self,
            SaleSyncCursorModel.self,
            SaleSyncRetryModel.self
        ])
    )
}

private let syncEngineImmediateTiming = SyncTiming(
    now: { Date.now },
    sleep: { _ in },
    jitterFactor: { 1 }
)

private func makeSale(id: UUID, name: String) throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(
            rawValue: UUID(uuidString: "56000000-0000-0000-0000-000000000001")!
        ),
        serviceID: ServiceID(
            rawValue: UUID(uuidString: "56000000-0000-0000-0000-000000000002")!
        ),
        serviceName: name,
        quantity: 1,
        unitPrice: Money(amount: 10, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
    let orderingValue = Int(id.uuidString.suffix(2), radix: 16) ?? 0
    return try Sale.draft(
        id: SaleID(rawValue: id),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: -TimeInterval(orderingValue)),
        lines: [line]
    )
}

private func syncEngineSaleID(_ value: String) throws -> SaleID {
    SaleID(rawValue: try syncEngineUUID(value))
}

private func syncEngineUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
