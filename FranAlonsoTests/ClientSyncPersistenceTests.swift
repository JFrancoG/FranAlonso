import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Clients synchronization persistence")
struct ClientSyncPersistenceTests {
    @Test("A pending row created before causal metadata keeps an absent remote base")
    func legacyPendingRowKeepsAbsentRemoteBase() throws {
        let clientID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000001"
        )
        let operationID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000002"
        )
        let payload = ClientDTO(
            Client.draft(
                id: ClientID(rawValue: clientID),
                displayName: "Pre-sync pending client"
            )
        )
        let model = ClientPendingUpsertModel(
            clientID: clientID,
            operationID: operationID,
            predecessorOperationID: nil,
            baseVersion: nil,
            baseData: nil,
            payloadVersion: 1,
            payloadData: try JSONEncoder().encode(payload)
        )

        #expect(try model.decodeBase() == .absent)
    }

    @MainActor
    @Test("Acknowledging an ancestor preserves its pending descendant and visible snapshot")
    func acknowledgingAncestorPreservesDescendantAndVisibleSnapshot() async throws {
        let container = try syncPersistenceContainer()
        let dataSource = ClientLocalDataSource()
        let clientID = try syncPersistenceClientID(
            "52000000-0000-0000-0000-000000000001"
        )
        let ancestor = Client.draft(
            id: clientID,
            displayName: "Ancestor A"
        )
        let descendant = Client.draft(
            id: clientID,
            displayName: "Descendant B"
        )
        let ancestorOperationID = try syncPersistenceUUID(
            "53000000-0000-0000-0000-000000000001"
        )
        let descendantOperationID = try syncPersistenceUUID(
            "53000000-0000-0000-0000-000000000002"
        )
        try dataSource.persistPendingUpsert(
            ancestor,
            operationID: ancestorOperationID,
            in: ModelContext(container)
        )
        let persistenceActor = ClientPersistenceActor(modelContainer: container)

        let loadedOperations = try await persistenceActor.pendingUpserts()
        #expect(loadedOperations.map(\.operationID) == [ancestorOperationID])

        try dataSource.persistPendingUpsert(
            descendant,
            operationID: descendantOperationID,
            in: container.mainContext
        )
        let acknowledgedRecord = ClientRemoteRecord(
            client: ClientDTO(ancestor),
            version: .versioned(
                revision: 1,
                lastOperationID: ancestorOperationID
            )
        )

        try await persistenceActor.acknowledge(
            operationID: ancestorOperationID,
            record: acknowledgedRecord
        )

        let verificationContext = ModelContext(container)
        let remainingOperations = try verificationContext.fetch(
            FetchDescriptor<ClientPendingUpsertModel>()
        )
        let remainingOperation = try #require(remainingOperations.only)
        #expect(remainingOperation.operationID == descendantOperationID)
        #expect(remainingOperation.predecessorOperationID == ancestorOperationID)
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [descendant]
        )
        let remoteState = try #require(
            verificationContext.fetch(
                FetchDescriptor<ClientRemoteStateModel>()
            ).only
        )
        #expect(try remoteState.decodeRecord() == acknowledgedRecord)
    }

    @Test("A persisted conflict blocks only the affected client")
    func persistedConflictBlocksOnlyAffectedClient() async throws {
        let container = try syncPersistenceContainer()
        let dataSource = ClientLocalDataSource()
        let conflictedClient = Client.draft(
            id: try syncPersistenceClientID(
                "52000000-0000-0000-0000-000000000002"
            ),
            displayName: "Conflicted client"
        )
        let unaffectedClient = Client.draft(
            id: try syncPersistenceClientID(
                "52000000-0000-0000-0000-000000000003"
            ),
            displayName: "Unaffected client"
        )
        let operationID = try syncPersistenceUUID(
            "53000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            conflictedClient,
            operationID: operationID,
            in: ModelContext(container)
        )
        let persistenceActor = ClientPersistenceActor(modelContainer: container)
        let operation = try #require(
            try await persistenceActor.pendingUpserts().only
        )
        let remoteRecord = ClientRemoteRecord(
            client: ClientDTO(
                Client.draft(
                    id: conflictedClient.id,
                    displayName: "Concurrent remote edit"
                )
            ),
            version: .versioned(
                revision: 4,
                lastOperationID: try syncPersistenceUUID(
                    "53000000-0000-0000-0000-000000000004"
                )
            )
        )
        try await persistenceActor.recordConflict(
            operation: operation,
            reason: .baseChanged,
            remoteRecord: remoteRecord
        )

        #expect(
            throws: ClientLocalDataSourceError.syncConflictPending(
                conflictedClient.id
            )
        ) {
            try dataSource.persistPendingUpsert(
                Client.draft(
                    id: conflictedClient.id,
                    displayName: "Blocked edit"
                ),
                operationID: try syncPersistenceUUID(
                    "53000000-0000-0000-0000-000000000005"
                ),
                in: ModelContext(container)
            )
        }

        try dataSource.persistPendingUpsert(
            unaffectedClient,
            operationID: try syncPersistenceUUID(
                "53000000-0000-0000-0000-000000000006"
            ),
            in: ModelContext(container)
        )
        let deliverableOperations = try await persistenceActor
            .deliverablePendingUpserts()
        #expect(
            deliverableOperations.map(\.clientID)
                == [unaffectedClient.id.rawValue]
        )
        let verificationContext = ModelContext(container)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ClientSyncConflictModel>()
            ).only
        )
        #expect(conflict.clientID == conflictedClient.id.rawValue)
        #expect(conflict.operationID == operationID)
        #expect(try conflict.decodeBase() == operation.base)
        #expect(try conflict.decodeLocalClient() == operation.client)
        #expect(try conflict.decodeRemoteRecord() == remoteRecord)
        #expect(
            try dataSource.fetchAll(in: verificationContext).contains(
                unaffectedClient
            )
        )
    }
}

private func syncPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self
        ])
    )
}

private func syncPersistenceClientID(_ value: String) throws -> ClientID {
    ClientID(rawValue: try syncPersistenceUUID(value))
}

private func syncPersistenceUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
