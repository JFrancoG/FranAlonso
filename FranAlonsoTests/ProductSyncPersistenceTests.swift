import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Products synchronization persistence")
struct ProductSyncPersistenceTests {
    @Test("A pending row created before causal metadata keeps an absent remote base")
    func legacyPendingRowKeepsAbsentRemoteBase() throws {
        let productID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000001"
        )
        let operationID = try syncPersistenceUUID(
            "51000000-0000-0000-0000-000000000002"
        )
        let payload = ProductDTO(
            Product.testSnapshot(
                id: ProductID(rawValue: productID),
                name: "Pre-sync pending product"
            )
        )
        let model = ProductPendingUpsertModel(
            productID: productID,
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
        let dataSource = ProductLocalDataSource()
        let productID = try syncPersistenceProductID(
            "52000000-0000-0000-0000-000000000001"
        )
        let ancestor = Product.testSnapshot(
            id: productID,
            name: "Ancestor A"
        )
        let descendant = Product.testSnapshot(
            id: productID,
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
        let persistenceActor = ProductPersistenceActor(modelContainer: container)

        let loadedOperations = try await persistenceActor.pendingUpserts()
        #expect(loadedOperations.map(\.operationID) == [ancestorOperationID])

        try dataSource.persistPendingUpsert(
            descendant,
            operationID: descendantOperationID,
            in: container.mainContext
        )
        let acknowledgedRecord = ProductRemoteRecord(
            product: ProductDTO(ancestor),
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
            FetchDescriptor<ProductPendingUpsertModel>()
        )
        let remainingOperation = try #require(remainingOperations.only)
        #expect(remainingOperation.operationID == descendantOperationID)
        #expect(remainingOperation.predecessorOperationID == ancestorOperationID)
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [descendant]
        )
        let remoteState = try #require(
            verificationContext.fetch(
                FetchDescriptor<ProductRemoteStateModel>()
            ).only
        )
        #expect(try remoteState.decodeRecord() == acknowledgedRecord)
    }

    @Test("A persisted conflict blocks only the affected product")
    func persistedConflictBlocksOnlyAffectedProduct() async throws {
        let container = try syncPersistenceContainer()
        let dataSource = ProductLocalDataSource()
        let conflictedProduct = Product.testSnapshot(
            id: try syncPersistenceProductID(
                "52000000-0000-0000-0000-000000000002"
            ),
            name: "Conflicted product"
        )
        let unaffectedProduct = Product.testSnapshot(
            id: try syncPersistenceProductID(
                "52000000-0000-0000-0000-000000000003"
            ),
            name: "Unaffected product"
        )
        let operationID = try syncPersistenceUUID(
            "53000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            conflictedProduct,
            operationID: operationID,
            in: ModelContext(container)
        )
        let persistenceActor = ProductPersistenceActor(modelContainer: container)
        let operation = try #require(
            try await persistenceActor.pendingUpserts().only
        )
        let remoteRecord = ProductRemoteRecord(
            product: ProductDTO(
                Product.testSnapshot(
                    id: conflictedProduct.id,
                    name: "Concurrent remote edit"
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
            throws: ProductLocalDataSourceError.syncConflictPending(
                conflictedProduct.id
            )
        ) {
            try dataSource.persistPendingUpsert(
                Product.testSnapshot(
                    id: conflictedProduct.id,
                    name: "Blocked edit"
                ),
                operationID: try syncPersistenceUUID(
                    "53000000-0000-0000-0000-000000000005"
                ),
                in: ModelContext(container)
            )
        }

        try dataSource.persistPendingUpsert(
            unaffectedProduct,
            operationID: try syncPersistenceUUID(
                "53000000-0000-0000-0000-000000000006"
            ),
            in: ModelContext(container)
        )
        let deliverableOperations = try await persistenceActor
            .deliverablePendingUpserts()
        #expect(
            deliverableOperations.map(\.productID)
                == [unaffectedProduct.id.rawValue]
        )
        let verificationContext = ModelContext(container)
        let conflict = try #require(
            verificationContext.fetch(
                FetchDescriptor<ProductSyncConflictModel>()
            ).only
        )
        #expect(conflict.productID == conflictedProduct.id.rawValue)
        #expect(conflict.operationID == operationID)
        #expect(try conflict.decodeBase() == operation.base)
        #expect(try conflict.decodeLocalProduct() == operation.product)
        #expect(try conflict.decodeRemoteRecord() == remoteRecord)
        #expect(
            try dataSource.fetchAll(in: verificationContext).contains(
                unaffectedProduct
            )
        )
    }
}

private func syncPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            ProductModel.self,
            ProductPendingUpsertModel.self,
            ProductPendingDeleteModel.self,
            ProductRemoteStateModel.self,
            ProductSyncConflictModel.self,
            ProductSyncCursorModel.self
        ])
    )
}

private func syncPersistenceProductID(_ value: String) throws -> ProductID {
    ProductID(rawValue: try syncPersistenceUUID(value))
}

private func syncPersistenceUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
