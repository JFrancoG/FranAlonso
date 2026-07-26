import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product persistence actor")
struct ProductPersistenceActorTests {
    @Test("Concurrent upserts serialize and return detached Domain snapshots")
    func concurrentUpsertsSerializeAndReturnDetachedDomainSnapshots() async throws {
        let container = try makeProductPersistenceContainer()
        let persistenceActor = ProductPersistenceActor(modelContainer: container)
        let products = [
            Product.testSnapshot(
                id: try persistenceProductID("20000000-0000-0000-0000-000000000001"),
                name: "Beatriz Alonso"
            ),
            Product.testSnapshot(
                id: try persistenceProductID("20000000-0000-0000-0000-000000000002"),
                name: "Ana Alonso"
            ),
            Product.testSnapshot(
                id: try persistenceProductID("20000000-0000-0000-0000-000000000003"),
                name: "Carmen Alonso"
            )
        ]

        try await withThrowingTaskGroup(of: Void.self) { group in
            for product in products {
                group.addTask {
                    try await persistenceActor.upsert(product)
                }
            }

            try await group.waitForAll()
        }

        let snapshots: [Product] = try await persistenceActor.fetchAll()
        let expectedProducts = products.sorted { $0.name < $1.name }
        #expect(snapshots == expectedProducts)
    }

    @Test("An actor save is visible from an independently owned context")
    func actorSaveIsVisibleFromAnIndependentlyOwnedContext() async throws {
        let container = try makeProductPersistenceContainer()
        let persistenceActor = ProductPersistenceActor(modelContainer: container)
        let product = Product.testSnapshot(
            id: try persistenceProductID("20000000-0000-0000-0000-000000000004"),
            name: "Independent context"
        )

        try await persistenceActor.upsert(product)

        let verificationContext = ModelContext(container)
        let persistedProducts = try ProductLocalDataSource().fetchAll(
            in: verificationContext
        )
        #expect(persistedProducts == [product])
    }

    @Test("Delete removes a stable identifier through the actor boundary")
    func deleteRemovesAStableIdentifierThroughTheActorBoundary() async throws {
        let container = try makeProductPersistenceContainer()
        let persistenceActor = ProductPersistenceActor(modelContainer: container)
        let product = Product.testSnapshot(
            id: try persistenceProductID("20000000-0000-0000-0000-000000000005"),
            name: "Product to delete"
        )
        try await persistenceActor.upsert(product)

        try await persistenceActor.delete(product.id)

        let verificationContext = ModelContext(container)
        #expect(
            try ProductLocalDataSource().fetchAll(in: verificationContext).isEmpty
        )
    }
}

private func makeProductPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ProductModel.self]))
}

private func persistenceProductID(_ value: String) throws -> ProductID {
    ProductID(rawValue: try #require(UUID(uuidString: value)))
}
