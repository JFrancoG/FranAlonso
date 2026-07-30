import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services synchronization persistence")
struct ServiceSyncPersistenceTests {
    @Test("A pending row created before causal metadata keeps an absent remote base")
    func legacyPendingRowKeepsAbsentRemoteBase() throws {
        let serviceID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000001"
        )
        let operationID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000002"
        )
        let service = try makeService(
            id: serviceID,
            name: "Pre-sync pending service"
        )
        let payload = try ServiceDTO(service)
        let model = ServicePendingUpsertModel(
            serviceID: serviceID,
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
        let dataSource = ServiceLocalDataSource()
        let serviceID = try syncPersistenceServiceID(
            "52000000-0000-0000-0000-000000000001"
        )
        let ancestor = try makeService(
            id: serviceID.rawValue,
            name: "Ancestor A"
        )
        let descendant = try makeService(
            id: serviceID.rawValue,
            name: "Descendant B"
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
        let persistenceActor = ServicePersistenceActor(modelContainer: container)

        let loadedOperations = try await persistenceActor.pendingUpserts()
        #expect(loadedOperations.map(\.operationID) == [ancestorOperationID])

        try dataSource.persistPendingUpsert(
            descendant,
            operationID: descendantOperationID,
            in: container.mainContext
        )
        let acknowledgedRecord = ServiceRemoteRecord(
            service: try ServiceDTO(ancestor),
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
            FetchDescriptor<ServicePendingUpsertModel>()
        )
        let remainingOperation = try #require(remainingOperations.only)
        #expect(remainingOperation.operationID == descendantOperationID)
        #expect(remainingOperation.predecessorOperationID == ancestorOperationID)
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [descendant]
        )
        let remoteState = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServiceRemoteStateModel>()
            ).only
        )
        #expect(try remoteState.decodeRecord() == acknowledgedRecord)
    }

    @Test("A persisted conflict blocks only the affected service")
    func persistedConflictBlocksOnlyAffectedService() async throws {
        let container = try syncPersistenceContainer()
        let dataSource = ServiceLocalDataSource()
        let conflictedService = try makeService(
            id: try syncPersistenceServiceID(
                "52000000-0000-0000-0000-000000000002"
            ).rawValue,
            name: "Conflicted service"
        )
        let unaffectedService = try makeService(
            id: try syncPersistenceServiceID(
                "52000000-0000-0000-0000-000000000003"
            ).rawValue,
            name: "Unaffected service"
        )
        let operationID = try syncPersistenceUUID(
            "53000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            conflictedService,
            operationID: operationID,
            in: ModelContext(container)
        )
        let persistenceActor = ServicePersistenceActor(modelContainer: container)
        let operation = try #require(
            try await persistenceActor.pendingUpserts().only
        )
        let concurrentRemote = try makeService(
            id: conflictedService.id.rawValue,
            name: "Concurrent remote edit"
        )
        let remoteRecord = ServiceRemoteRecord(
            service: try ServiceDTO(concurrentRemote),
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
            throws: ServiceLocalDataSourceError.syncConflictPending(
                conflictedService.id
            )
        ) {
            try dataSource.persistPendingUpsert(
                try makeService(
                    id: conflictedService.id.rawValue,
                    name: "Blocked edit"
                ),
                operationID: try syncPersistenceUUID(
                    "53000000-0000-0000-0000-000000000005"
                ),
                in: ModelContext(container)
            )
        }

        try dataSource.persistPendingUpsert(
            unaffectedService,
            operationID: try syncPersistenceUUID(
                "53000000-0000-0000-0000-000000000006"
            ),
            in: ModelContext(container)
        )
        let deliverableOperations = try await persistenceActor
            .deliverablePendingUpserts()
        #expect(
            deliverableOperations.map(\.serviceID)
                == [unaffectedService.id.rawValue]
        )
        let verificationContext = ModelContext(container)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServiceSyncConflictModel>()
            ).only
        )
        #expect(conflict.serviceID == conflictedService.id.rawValue)
        #expect(conflict.operationID == operationID)
        #expect(try conflict.decodeBase() == operation.base)
        #expect(try conflict.decodeLocalService() == operation.service)
        #expect(try conflict.decodeRemoteRecord() == remoteRecord)
        #expect(
            try dataSource.fetchAll(in: verificationContext).contains(
                unaffectedService
            )
        )
    }
}

private func syncPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            ServiceModel.self,
            ServicePendingUpsertModel.self,
            ServicePendingDeleteModel.self,
            ServiceRemoteStateModel.self,
            ServiceSyncConflictModel.self,
            ServiceSyncCursorModel.self
        ])
    )
}

private func syncPersistenceServiceID(_ value: String) throws -> ServiceID {
    ServiceID(rawValue: try syncPersistenceUUID(value))
}

private func syncPersistenceUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
