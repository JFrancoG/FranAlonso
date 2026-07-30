import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services synchronization retry persistence")
struct ServiceSyncRetryPersistenceTests {
    @Test("One durable retry row is replaced per scope and survives actor restart")
    func retryStateIsReplacedPerScopeAndSurvivesRestart() async throws {
        let container = try retryPersistenceContainer()
        let first = try SyncRetryState(
            scope: .pull,
            backoffStep: 1,
            notBefore: Date(timeIntervalSinceReferenceDate: 1_001),
            lastRecoverableCategory: .unavailable
        )
        let second = try SyncRetryState(
            scope: .pull,
            backoffStep: 2,
            notBefore: Date(timeIntervalSinceReferenceDate: 1_004),
            lastRecoverableCategory: .deadlineExceeded
        )
        let firstActor = ServicePersistenceActor(modelContainer: container)

        try await firstActor.saveRetryState(first)
        try await firstActor.saveRetryState(second)

        let restartedActor = ServicePersistenceActor(modelContainer: container)
        #expect(try await restartedActor.retryState(for: .pull) == second)
        #expect(
            try ModelContext(container).fetchCount(
                FetchDescriptor<ServiceSyncRetryModel>()
            ) == 1
        )
    }

    @Test("Operation scopes retain independent retry rows")
    func operationScopesRetainIndependentRows() async throws {
        let container = try retryPersistenceContainer()
        let firstID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000001"
        )
        let secondID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000002"
        )
        let actor = ServicePersistenceActor(modelContainer: container)
        let first = try retryPersistenceState(
            scope: .operation(firstID),
            step: 1
        )
        let second = try retryPersistenceState(
            scope: .operation(secondID),
            step: 2
        )

        try await actor.saveRetryState(first)
        try await actor.saveRetryState(second)

        #expect(
            try await actor.retryState(for: .operation(firstID)) == first
        )
        #expect(
            try await actor.retryState(for: .operation(secondID)) == second
        )
    }

    @Test("Malformed durable retry state fails closed")
    func malformedDurableRetryStateFailsClosed() async throws {
        let container = try retryPersistenceContainer()
        let context = ModelContext(container)
        context.insert(
            ServiceSyncRetryModel(
                scopeID: "pull",
                backoffStep: 0,
                notBefore: .now,
                lastRecoverableCategoryRawValue: "unavailable"
            )
        )
        try context.save()
        let actor = ServicePersistenceActor(modelContainer: container)

        await #expect(
            throws: SyncRetryPolicyError.invalidBackoffStep(0)
        ) {
            _ = try await actor.retryState(for: .pull)
        }
    }

    @Test("A committed pull clears its retry row with the cursor")
    func committedPullClearsRetryWithCursor() async throws {
        let container = try retryPersistenceContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        try await actor.saveRetryState(
            try retryPersistenceState(scope: .pull, step: 2)
        )

        try await actor.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [],
                nextCursor: ServiceSyncCursor(changeSequence: 0)
            ),
            policy: ServiceSyncPolicy(),
            clearingRetryFor: .pull
        )

        #expect(try await actor.cursor() == ServiceSyncCursor(changeSequence: 0))
        #expect(try await actor.retryState(for: .pull) == nil)
    }

    @Test("A failed pull reconciliation preserves its previous retry row")
    func failedPullReconciliationPreservesRetry() async throws {
        let container = try retryPersistenceContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        let state = try retryPersistenceState(scope: .pull, step: 2)
        try await actor.saveRetryState(state)

        await #expect(throws: ServiceSyncPersistenceError.invalidCursor) {
            try await actor.reconcileRemoteBatch(
                ServiceRemoteChangeBatch(
                    records: [],
                    nextCursor: ServiceSyncCursor(changeSequence: 1)
                ),
                policy: ServiceSyncPolicy(),
                clearingRetryFor: .pull
            )
        }

        #expect(try await actor.retryState(for: .pull) == state)
    }

    @Test("An acknowledgement clears its operation retry in the same commit")
    func acknowledgementClearsOperationRetryAtomically() async throws {
        let container = try retryPersistenceContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        let service = try makeService(
            id: retryPersistenceUUID(
                "71000000-0000-0000-0000-000000000003"
            ),
            name: "Retry acknowledgement"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000004"
        )
        try await actor.persistPendingUpsert(
            service,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )
        let record = ServiceRemoteRecord(
            service: try ServiceDTO(service),
            version: .versioned(
                revision: 1,
                lastOperationID: operationID
            ),
            changeSequence: 1
        )

        try await actor.acknowledge(
            operationID: operationID,
            record: record,
            clearingRetryFor: .operation(operationID)
        )

        #expect(try await actor.pendingOperations().isEmpty)
        #expect(
            try await actor.retryState(for: .operation(operationID)) == nil
        )
    }

    @Test("A pulled acknowledgement clears the acknowledged operation retry")
    func pulledAcknowledgementClearsOperationRetry() async throws {
        let container = try retryPersistenceContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        let service = try makeService(
            id: retryPersistenceUUID(
                "71000000-0000-0000-0000-000000000005"
            ),
            name: "Pulled acknowledgement"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000006"
        )
        try await actor.persistPendingUpsert(
            service,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )

        try await actor.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [
                    ServiceRemoteRecord(
                        service: try ServiceDTO(service),
                        version: .versioned(
                            revision: 1,
                            lastOperationID: operationID
                        ),
                        changeSequence: 1
                    )
                ],
                nextCursor: ServiceSyncCursor(changeSequence: 1)
            ),
            policy: ServiceSyncPolicy(),
            clearingRetryFor: .pull
        )

        #expect(try await actor.pendingOperations().isEmpty)
        #expect(
            try await actor.retryState(for: .operation(operationID)) == nil
        )
    }

    @Test("A pulled conflict clears the blocked operation retry")
    func pulledConflictClearsOperationRetry() async throws {
        let container = try retryPersistenceContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        let serviceID = ServiceID(
            rawValue: retryPersistenceUUID(
                "71000000-0000-0000-0000-000000000007"
            )
        )
        let service = try makeService(
            id: serviceID.rawValue,
            name: "Local conflict"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000008"
        )
        try await actor.persistPendingUpsert(
            service,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )
        let remoteService = try makeService(
            id: serviceID.rawValue,
            name: "Remote conflict"
        )

        try await actor.reconcileRemoteBatch(
            ServiceRemoteChangeBatch(
                records: [
                    ServiceRemoteRecord(
                        service: try ServiceDTO(remoteService),
                        version: .versioned(
                            revision: 1,
                            lastOperationID: retryPersistenceUUID(
                                "71000000-0000-0000-0000-000000000009"
                            )
                        ),
                        changeSequence: 1
                    )
                ],
                nextCursor: ServiceSyncCursor(changeSequence: 1)
            ),
            policy: ServiceSyncPolicy(),
            clearingRetryFor: .pull
        )

        #expect(
            try ModelContext(container).fetchCount(
                FetchDescriptor<ServiceSyncConflictModel>()
            ) == 1
        )
        #expect(
            try await actor.retryState(for: .operation(operationID)) == nil
        )
    }
}

private func retryPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

private func retryPersistenceState(
    scope: SyncRetryScope,
    step: Int
) throws -> SyncRetryState {
    try SyncRetryState(
        scope: scope,
        backoffStep: step,
        notBefore: Date(timeIntervalSinceReferenceDate: 1_000 + Double(step)),
        lastRecoverableCategory: .unavailable
    )
}

private func retryPersistenceUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
