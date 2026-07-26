import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Products synchronization retry persistence")
struct ProductSyncRetryPersistenceTests {
    @Test("One durable retry row is replaced per scope and survives actor restart")
    func retryStateIsReplacedPerScopeAndSurvivesRestart() async throws {
        let container = try retryPersistenceContainer()
        let first = try ProductSyncRetryState(
            scope: .pull,
            backoffStep: 1,
            notBefore: Date(timeIntervalSinceReferenceDate: 1_001),
            lastRecoverableCategory: .unavailable
        )
        let second = try ProductSyncRetryState(
            scope: .pull,
            backoffStep: 2,
            notBefore: Date(timeIntervalSinceReferenceDate: 1_004),
            lastRecoverableCategory: .deadlineExceeded
        )
        let firstActor = ProductPersistenceActor(modelContainer: container)

        try await firstActor.saveRetryState(first)
        try await firstActor.saveRetryState(second)

        let restartedActor = ProductPersistenceActor(modelContainer: container)
        #expect(try await restartedActor.retryState(for: .pull) == second)
        #expect(
            try ModelContext(container).fetchCount(
                FetchDescriptor<ProductSyncRetryModel>()
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
        let actor = ProductPersistenceActor(modelContainer: container)
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
            ProductSyncRetryModel(
                scopeID: "pull",
                backoffStep: 0,
                notBefore: .now,
                lastRecoverableCategoryRawValue: "unavailable"
            )
        )
        try context.save()
        let actor = ProductPersistenceActor(modelContainer: container)

        await #expect(
            throws: ProductSyncRetryPolicyError.invalidBackoffStep(0)
        ) {
            _ = try await actor.retryState(for: .pull)
        }
    }

    @Test("A committed pull clears its retry row with the cursor")
    func committedPullClearsRetryWithCursor() async throws {
        let container = try retryPersistenceContainer()
        let actor = ProductPersistenceActor(modelContainer: container)
        try await actor.saveRetryState(
            try retryPersistenceState(scope: .pull, step: 2)
        )

        try await actor.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [],
                nextCursor: ProductSyncCursor(changeSequence: 0)
            ),
            policy: ProductSyncPolicy(),
            clearingRetryFor: .pull
        )

        #expect(try await actor.cursor() == ProductSyncCursor(changeSequence: 0))
        #expect(try await actor.retryState(for: .pull) == nil)
    }

    @Test("A failed pull reconciliation preserves its previous retry row")
    func failedPullReconciliationPreservesRetry() async throws {
        let container = try retryPersistenceContainer()
        let actor = ProductPersistenceActor(modelContainer: container)
        let state = try retryPersistenceState(scope: .pull, step: 2)
        try await actor.saveRetryState(state)

        await #expect(throws: ProductSyncPersistenceError.invalidCursor) {
            try await actor.reconcileRemoteBatch(
                ProductRemoteChangeBatch(
                    records: [],
                    nextCursor: ProductSyncCursor(changeSequence: 1)
                ),
                policy: ProductSyncPolicy(),
                clearingRetryFor: .pull
            )
        }

        #expect(try await actor.retryState(for: .pull) == state)
    }

    @Test("An acknowledgement clears its operation retry in the same commit")
    func acknowledgementClearsOperationRetryAtomically() async throws {
        let container = try retryPersistenceContainer()
        let actor = ProductPersistenceActor(modelContainer: container)
        let product = Product.testSnapshot(
            id: ProductID(
                rawValue: retryPersistenceUUID(
                    "71000000-0000-0000-0000-000000000003"
                )
            ),
            name: "Retry acknowledgement"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000004"
        )
        try await actor.persistPendingUpsert(
            product,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )
        let record = ProductRemoteRecord(
            product: ProductDTO(product),
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
        let actor = ProductPersistenceActor(modelContainer: container)
        let product = Product.testSnapshot(
            id: ProductID(
                rawValue: retryPersistenceUUID(
                    "71000000-0000-0000-0000-000000000005"
                )
            ),
            name: "Pulled acknowledgement"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000006"
        )
        try await actor.persistPendingUpsert(
            product,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )

        try await actor.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [
                    ProductRemoteRecord(
                        product: ProductDTO(product),
                        version: .versioned(
                            revision: 1,
                            lastOperationID: operationID
                        ),
                        changeSequence: 1
                    )
                ],
                nextCursor: ProductSyncCursor(changeSequence: 1)
            ),
            policy: ProductSyncPolicy(),
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
        let actor = ProductPersistenceActor(modelContainer: container)
        let productID = ProductID(
            rawValue: retryPersistenceUUID(
                "71000000-0000-0000-0000-000000000007"
            )
        )
        let product = Product.testSnapshot(
            id: productID,
            name: "Local conflict"
        )
        let operationID = retryPersistenceUUID(
            "71000000-0000-0000-0000-000000000008"
        )
        try await actor.persistPendingUpsert(
            product,
            operationID: operationID
        )
        try await actor.saveRetryState(
            try retryPersistenceState(
                scope: .operation(operationID),
                step: 2
            )
        )
        let remoteProduct = Product.testSnapshot(
            id: productID,
            name: "Remote conflict"
        )

        try await actor.reconcileRemoteBatch(
            ProductRemoteChangeBatch(
                records: [
                    ProductRemoteRecord(
                        product: ProductDTO(remoteProduct),
                        version: .versioned(
                            revision: 1,
                            lastOperationID: retryPersistenceUUID(
                                "71000000-0000-0000-0000-000000000009"
                            )
                        ),
                        changeSequence: 1
                    )
                ],
                nextCursor: ProductSyncCursor(changeSequence: 1)
            ),
            policy: ProductSyncPolicy(),
            clearingRetryFor: .pull
        )

        #expect(
            try ModelContext(container).fetchCount(
                FetchDescriptor<ProductSyncConflictModel>()
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
    scope: ProductSyncRetryScope,
    step: Int
) throws -> ProductSyncRetryState {
    try ProductSyncRetryState(
        scope: scope,
        backoffStep: step,
        notBefore: Date(timeIntervalSinceReferenceDate: 1_000 + Double(step)),
        lastRecoverableCategory: .unavailable
    )
}

private func retryPersistenceUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
