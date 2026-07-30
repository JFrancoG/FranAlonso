import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services tombstones and durable cursor")
struct ServiceSyncRecoveryTests {
    @Test("A local delete hides the service and survives a persistence actor restart")
    func localDeleteHidesServiceAndSurvivesRestart() async throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let service = try recoveryService(name: "Delete locally")
        let operationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000001"
        )
        try dataSource.upsert(service, in: ModelContext(container))
        try dataSource.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [
                    try recoveryLiveRecord(
                        service: service,
                        revision: 4,
                        operationID: recoveryUUID(
                            "61000000-0000-0000-0000-000000000002"
                        ),
                        changeSequence: 7
                    )
                ],
                nextCursor: ServiceSyncCursor(changeSequence: 7)
            ),
            policy: ServiceSyncPolicy(),
            in: ModelContext(container)
        )

        try dataSource.persistPendingDelete(
            service.id,
            operationID: operationID,
            in: ModelContext(container)
        )

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        let restartedActor = ServicePersistenceActor(modelContainer: container)
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
        let dataSource = ServiceLocalDataSource()
        let service = try recoveryService(name: "Pending local snapshot")
        let localOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            service,
            operationID: localOperationID,
            in: ModelContext(container)
        )
        let tombstone = recoveryTombstoneRecord(
            serviceID: service.id.rawValue,
            revision: 2,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000004"
            ),
            changeSequence: 8
        )

        try dataSource.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ServiceSyncCursor(changeSequence: 8)
            ),
            policy: ServiceSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServiceSyncConflictModel>()
            ).only
        )
        let expectedLocal = try ServiceDTO(service)
        #expect(try conflict.decodeLocalService() == expectedLocal)
        #expect(try conflict.decodeRemoteRecord() == tombstone)
        #expect(
            try dataSource.cursor(in: verificationContext)
                == ServiceSyncCursor(changeSequence: 8)
        )
    }

    @Test("A failed remote batch rolls back its materialization and cursor")
    func failedRemoteBatchRollsBackMaterializationAndCursor() throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let validService = try recoveryService(name: "Must roll back")
        let validDTO = try makeServiceDTO(discountPercentage: nil)
        let invalidDTO = ServiceDTO(
            id: "not-a-uuid",
            name: "Invalid identity",
            type: validDTO.type,
            linkedProductID: validDTO.linkedProductID,
            price: validDTO.price,
            taxRate: validDTO.taxRate,
            discount: validDTO.discount,
            status: validDTO.status
        )
        let invalidRecord = ServiceRemoteRecord(
            content: .live(invalidDTO),
            version: .legacy,
            changeSequence: nil
        )

        #expect(throws: ServiceSyncPersistenceError.entityIdentityMismatch) {
            try dataSource.reconcileRemoteBatch(
                ServiceRemoteChangeBatch(
                    records: [
                        try recoveryLiveRecord(
                            service: validService,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000005"
                            ),
                            changeSequence: 1
                        ),
                        invalidRecord
                    ],
                    nextCursor: ServiceSyncCursor(changeSequence: 1)
                ),
                policy: ServiceSyncPolicy(),
                in: ModelContext(container)
            )
        }

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        #expect(try dataSource.cursor(in: verificationContext) == nil)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServiceRemoteStateModel>()
            ) == 0
        )
    }

    @Test("A stale live record cannot resurrect a sequenced tombstone")
    func staleLiveRecordCannotResurrectTombstone() throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let service = try recoveryService(name: "Stale live snapshot")
        let tombstone = recoveryTombstoneRecord(
            serviceID: service.id.rawValue,
            revision: 5,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000006"
            ),
            changeSequence: 10
        )
        try dataSource.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [tombstone],
                nextCursor: ServiceSyncCursor(changeSequence: 10)
            ),
            policy: ServiceSyncPolicy(),
            in: ModelContext(container)
        )

        let staleLive = try recoveryLiveRecord(
            service: service,
            revision: 4,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000007"
            ),
            changeSequence: 9
        )
        try dataSource.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [staleLive],
                nextCursor: ServiceSyncCursor(changeSequence: 10)
            ),
            policy: ServiceSyncPolicy(),
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let state = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServiceRemoteStateModel>()
            ).only
        )
        #expect(try state.decodeRecord() == tombstone)
    }

    @Test("Pending operation identities are unique across upsert and delete storage")
    func pendingOperationIdentityIsGloballyUnique() throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let firstService = try recoveryService(name: "First identity")
        let secondService = try makeService(
            id: recoveryUUID(
                "60000000-0000-0000-0000-000000000099"
            ),
            name: "Second identity"
        )
        let duplicateOperationID = recoveryUUID(
            "61000000-0000-0000-0000-000000000008"
        )
        try dataSource.upsert(firstService, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            firstService.id,
            operationID: duplicateOperationID,
            in: ModelContext(container)
        )

        #expect(
            throws: ServiceSyncPersistenceError.duplicateOperationIdentity(
                duplicateOperationID
            )
        ) {
            try dataSource.persistPendingUpsert(
                secondService,
                operationID: duplicateOperationID,
                in: ModelContext(container)
            )
        }
    }

    @Test("A pending deletion blocks an ordinary upsert from restoring the service")
    func pendingDeletionBlocksOrdinaryUpsert() throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let service = try recoveryService(name: "Deleted locally")
        try dataSource.upsert(service, in: ModelContext(container))
        try dataSource.persistPendingDelete(
            service.id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000009"
            ),
            in: ModelContext(container)
        )

        #expect(
            throws: ServiceLocalDataSourceError
                .restoreRequiresExplicitResolution(service.id)
        ) {
            try dataSource.persistPendingUpsert(
                service,
                operationID: recoveryUUID(
                    "61000000-0000-0000-0000-000000000010"
                ),
                in: ModelContext(container)
            )
        }
    }

    @Test("Deleting a wholly unknown service remains an idempotent no-op")
    func deletingUnknownServiceIsNoOp() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)

        try ServiceLocalDataSource().persistPendingDelete(
            try recoveryService(name: "Unknown").id,
            operationID: recoveryUUID(
                "61000000-0000-0000-0000-000000000011"
            ),
            in: context
        )

        #expect(!context.hasChanges)
        #expect(
            try context.fetchCount(
                FetchDescriptor<ServicePendingDeleteModel>()
            ) == 0
        )
    }

    @Test("A negative persisted cursor fails closed")
    func negativePersistedCursorFailsClosed() throws {
        let container = try recoveryContainer()
        let context = ModelContext(container)
        context.insert(
            ServiceSyncCursorModel(
                feedID: "services",
                changeSequence: -1
            )
        )
        try context.save()

        #expect(throws: ServiceSyncPersistenceError.invalidCursor) {
            _ = try ServiceLocalDataSource().cursor(
                in: ModelContext(container)
            )
        }
    }

    @Test("A remote batch cannot advance beyond the changes it carries")
    func remoteBatchCannotSkipUnappliedSequences() throws {
        let container = try recoveryContainer()
        let dataSource = ServiceLocalDataSource()
        let service = try recoveryService(name: "Cursor jump")

        #expect(throws: ServiceSyncPersistenceError.invalidCursor) {
            try dataSource.reconcileRemoteBatch(
                ServiceRemoteChangeBatch(
                    records: [
                        try recoveryLiveRecord(
                            service: service,
                            revision: 1,
                            operationID: recoveryUUID(
                                "61000000-0000-0000-0000-000000000012"
                            ),
                            changeSequence: 1
                        )
                    ],
                    nextCursor: ServiceSyncCursor(changeSequence: 2)
                ),
                policy: ServiceSyncPolicy(),
                in: ModelContext(container)
            )
        }

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        #expect(try dataSource.cursor(in: ModelContext(container)) == nil)
    }

    @Test("A Service record without feed metadata remains valid for bootstrap")
    func serviceRecordWithoutFeedMetadataRemainsValidForBootstrap() throws {
        let fixture = Data(
            #"{"service":{"id":"60000000-0000-0000-0000-000000000001","name":"Bootstrap service","type":"professional","linkedProductID":null,"price":{"amount":"29.95","currency":"EUR"},"taxRate":{"percentage":"21"},"discount":null,"status":"active"},"version":{"versioned":{"lastOperationID":"60000000-0000-0000-0000-000000000002","revision":3}}}"#.utf8
        )

        let record = try JSONDecoder().decode(
            ServiceRemoteRecord.self,
            from: fixture
        )

        let expected = try makeServiceDTO(
            id: recoveryUUID(
                "60000000-0000-0000-0000-000000000001"
            ),
            name: "Bootstrap service",
            discountPercentage: nil
        )
        #expect(record.content == .live(expected))
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

}

private func recoveryContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

private func recoveryService(name: String) throws -> Service {
    try makeService(
        id: recoveryUUID(
            "60000000-0000-0000-0000-000000000001"
        ),
        name: name,
        discountPercentage: nil
    )
}

private func recoveryLiveRecord(
    service: Service,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) throws -> ServiceRemoteRecord {
    let dto = try ServiceDTO(service)
    return ServiceRemoteRecord(
        content: .live(dto),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private func recoveryTombstoneRecord(
    serviceID: UUID,
    revision: Int64,
    operationID: UUID,
    changeSequence: Int64
) -> ServiceRemoteRecord {
    ServiceRemoteRecord(
        content: .tombstone(serviceID: serviceID),
        version: .versioned(
            revision: revision,
            lastOperationID: operationID
        ),
        changeSequence: changeSequence
    )
}

private func recoveryUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
