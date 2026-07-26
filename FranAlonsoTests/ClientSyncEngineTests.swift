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
}

private actor ClientSyncRemoteFake: ClientRemoteDataSource {
    private var records: [UUID: ClientRemoteRecord]
    private var operationIDs: [UUID] = []
    private let acknowledgementGate: ClientSyncAcknowledgementGate?
    private let policy = ClientSyncPolicy()

    init(
        records: [ClientRemoteRecord] = [],
        acknowledgementGate: ClientSyncAcknowledgementGate? = nil
    ) {
        self.records = Dictionary(
            uniqueKeysWithValues: records.compactMap { record in
                guard let identifier = UUID(uuidString: record.client.id) else {
                    return nil
                }
                return (identifier, record)
            }
        )
        self.acknowledgementGate = acknowledgementGate
    }

    var recordCount: Int { records.count }
    var receivedOperationIDs: [UUID] { operationIDs }

    func fetchAll() async throws -> [ClientRemoteRecord] {
        records.values.sorted { $0.id > $1.id }
    }

    func upsert(
        _ operation: ClientPendingUpsert
    ) async throws -> ClientRemoteUpsertResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.clientID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            records[operation.clientID] = nextRecord
            if let acknowledgementGate {
                await acknowledgementGate.blockOnce()
            }
            return .applied(nextRecord)
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
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self
        ])
    )
}

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
