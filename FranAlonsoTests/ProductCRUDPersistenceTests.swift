import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product CRUD local acceptance")
struct ProductCRUDPersistenceTests {
    @Test
    func `CRUD publishes committed snapshots and deactivation retains an upsert chain`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let repository = DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: ProductObservationSignal()
        )
        var observation = await repository.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let id = ProductID(rawValue: UUID())

        let created = try await repository.createProduct(id: id, profile: ProductProfile(name: "First"))
        #expect(try await observation.next() == [created])
        let edited = try await repository.updateProduct(id: id, profile: ProductProfile(name: "Edited"))
        #expect(try await observation.next() == [edited])
        try await repository.deactivateProduct(id)
        let inactive = Product(id: id, name: "Edited", status: .inactive)
        #expect(try await observation.next() == [inactive])
        let operationIDs = try await actor.pendingOperations().map(\.operationID)
        try await repository.deactivateProduct(id)

        #expect(try await repository.product(id: id) == inactive)
        #expect(try await actor.pendingOperations().map(\.operationID) == operationIDs)
        let upserts = try await actor.pendingUpserts()
        try #require(upserts.count == 3)
        #expect(upserts.last?.predecessorOperationID == upserts[1].operationID)
        let verification = ModelContext(container)
        #expect(try ProductLocalDataSource().fetchAll(in: verification) == [inactive])
        #expect(try verification.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
    }

    @Test
    func `duplicate and missing identities leave the accepted product and queue unchanged`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let repository = DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: ProductObservationSignal()
        )
        let id = ProductID(rawValue: UUID())
        let profile = try ProductProfile(name: "Original")
        let original = try await repository.createProduct(id: id, profile: profile)
        let operations = try await actor.pendingOperations()

        await #expect(throws: ProductError.alreadyExists) {
            try await repository.createProduct(id: id, profile: ProductProfile(name: "Replacement"))
        }
        await #expect(throws: ProductError.notFound) {
            try await repository.updateProduct(id: ProductID(rawValue: UUID()), profile: profile)
        }
        await #expect(throws: ProductError.notFound) {
            try await repository.deactivateProduct(ProductID(rawValue: UUID()))
        }

        #expect(try await repository.product(id: id) == original)
        #expect(try await actor.pendingOperations() == operations)
    }

    @Test(arguments: [false, true])
    func `pending and remote tombstones cannot be recreated edited or deactivated`(_ remote: Bool) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let id = ProductID(rawValue: UUID())
        if remote {
            try await actor.recordRemoteObservation(ProductRemoteRecord(
                content: .tombstone(productID: id.rawValue),
                version: .versioned(revision: 2, lastOperationID: UUID()),
                changeSequence: 2
            ))
        } else {
            try await actor.upsert(Product(id: id, name: "Removed", status: .active))
            try await actor.persistPendingDelete(id, operationID: UUID())
        }
        let repository = DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: ProductObservationSignal()
        )
        let pendingBefore = try await actor.pendingOperations()
        let profile = try ProductProfile(name: "Resurrection attempt")

        #expect(try await repository.product(id: id) == nil)
        await #expect(throws: ProductError.alreadyExists) {
            try await repository.createProduct(id: id, profile: profile)
        }
        await #expect(throws: ProductError.deleted) {
            try await repository.updateProduct(id: id, profile: profile)
        }
        await #expect(throws: ProductError.deleted) {
            try await repository.deactivateProduct(id)
        }

        #expect(try await actor.pendingOperations() == pendingBefore)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
    }

    @Test
    func `an acknowledged inactive product is not queued again by repeated deactivation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let inactive = Product(id: ProductID(rawValue: UUID()), name: "Retained", status: .inactive)
        let operationID = UUID()
        try await actor.persistPendingUpsert(inactive, operationID: operationID)
        let record = ProductRemoteRecord(
            product: ProductDTO(inactive),
            version: .versioned(revision: 1, lastOperationID: operationID)
        )
        try await actor.acknowledge(operationID: operationID, record: record)
        let repository = DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: ProductObservationSignal()
        )

        try await repository.deactivateProduct(inactive.id)

        #expect(try await repository.product(id: inactive.id) == inactive)
        #expect(try await actor.pendingOperations().isEmpty)
        let states = try ModelContext(container).fetch(FetchDescriptor<ProductRemoteStateModel>())
        #expect(try #require(states.first).decodeRecord() == record)
    }

    @Test
    @MainActor
    func `contextual commands share the causal route and preserve current inactive state`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let signal = ProductObservationSignal()
        let repository = DefaultProductRepository(persistenceActor: actor, observationSignal: signal)
        let adapter = ProductContextualPersistenceAdapter(observationSignal: signal)
        let id = ProductID(rawValue: UUID())
        var observation = await repository.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [])

        let created = try await adapter.create(
            id: id,
            profile: ProductProfile(name: "Before"),
            in: container.mainContext
        )
        #expect(try await observation.next() == [created])
        try await adapter.deactivate(id, in: container.mainContext)
        #expect(try await observation.next() == [Product(id: id, name: "Before", status: .inactive)])
        let edited = try await adapter.update(id: id, profile: ProductProfile(name: "After"), in: container.mainContext)
        #expect(try await observation.next() == [Product(id: id, name: "After", status: .inactive)])

        #expect(edited.status == .inactive)
        #expect(try ProductLocalDataSource().fetchAll(in: ModelContext(container)) == [edited])
        #expect(try await actor.pendingUpserts().count == 3)
    }

    @Test(arguments: [ProductStatus.active, .inactive])
    func `conflicts block renaming and deactivation without modifying the queued snapshot`(
        _ status: ProductStatus
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let original = Product(id: ProductID(rawValue: UUID()), name: "Local", status: status)
        let operationID = UUID()
        try await actor.persistPendingUpsert(original, operationID: operationID)
        let operation = try #require(try await actor.pendingUpserts().first)
        let remote = Product(id: original.id, name: "Remote", status: .active)
        try await actor.recordConflict(
            operation: operation,
            reason: .baseChanged,
            remoteRecord: ProductRemoteRecord(
                product: ProductDTO(remote),
                version: .versioned(revision: 4, lastOperationID: UUID())
            )
        )
        let repository = DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: ProductObservationSignal()
        )

        await #expect(throws: ProductError.conflict) {
            try await repository.updateProduct(id: original.id, profile: ProductProfile(name: "Blocked"))
        }
        await #expect(throws: ProductError.conflict) {
            try await repository.deactivateProduct(original.id)
        }

        #expect(try await repository.product(id: original.id) == original)
        #expect(try await actor.pendingOperations().map(\.operationID) == [operationID])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductSyncConflictModel>()) == 1)
    }

    @Test
    @MainActor
    func `a dirty caller context is rejected without discarding unsaved work`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let context = container.mainContext
        context.autosaveEnabled = false
        let unrelated = Product(id: ProductID(rawValue: UUID()), name: "Unsaved", status: .active)
        context.insert(ProductModel(unrelated))
        let adapter = ProductContextualPersistenceAdapter(observationSignal: ProductObservationSignal())

        await #expect(throws: ProductError.persistenceUnavailable) {
            try await adapter.create(
                id: ProductID(rawValue: UUID()),
                profile: ProductProfile(name: "Rejected"),
                in: context
            )
        }

        #expect(context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<ProductModel>()).map(\.id) == [unrelated.id.rawValue])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
    }

    @Test
    @MainActor
    func `a rejected durable save rolls back product and causal work and exposes a neutral error`() async throws {
        let schema = Schema.franAlonso
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-ProductCRUD-ReadOnly-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "Products.store", directoryHint: .notDirectory)
        let writable = ModelConfiguration(
            "WritableProductCRUD",
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        _ = try ModelContainer(for: schema, configurations: [writable])
        let readOnly = ModelConfiguration(
            "ReadOnlyProductCRUD",
            schema: schema,
            url: url,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [readOnly])
        let context = container.mainContext
        context.autosaveEnabled = false
        let adapter = ProductContextualPersistenceAdapter(observationSignal: ProductObservationSignal())

        await #expect(throws: ProductError.persistenceUnavailable) {
            try await adapter.create(
                id: ProductID(rawValue: UUID()),
                profile: ProductProfile(name: "Rejected"),
                in: context
            )
        }

        #expect(!context.hasChanges)
        #expect(try ProductLocalDataSource().fetchAll(in: context).isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
        let verification = ModelContext(container)
        #expect(try verification.fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
    }
}
