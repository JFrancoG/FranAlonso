import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Products local-first repository")
struct DefaultProductRepositoryTests {
    @Test("A pending upsert persists the product and its operation snapshot together")
    func pendingUpsertPersistsProductAndOperationSnapshotTogether() throws {
        let container = try makeRepositoryContainer()
        let context = ModelContext(container)
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000001",
            name: "Ana Alonso"
        )
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000001"
        )

        try ProductLocalDataSource().persistPendingUpsert(
            product,
            operationID: operationID,
            in: context
        )

        let verificationContext = ModelContext(container)
        let operation = try #require(
            verificationContext.fetch(
                FetchDescriptor<ProductPendingUpsertModel>()
            ).only
        )
        #expect(
            try ProductLocalDataSource().fetchAll(in: verificationContext) == [product]
        )
        #expect(operation.productID == product.id.rawValue)
        #expect(operation.operationID == operationID)
        #expect(operation.payloadVersion == 1)
        #expect(try operation.decodePayload() == ProductDTO(product))
    }

    @Test("A rejected save rolls back the attempted product and pending operation")
    func rejectedSaveRollsBackAttemptedMutation() throws {
        let schema = Schema([
            ProductModel.self,
            ProductPendingUpsertModel.self,
            ProductPendingDeleteModel.self,
            ProductRemoteStateModel.self,
            ProductSyncConflictModel.self,
            ProductSyncCursorModel.self
        ])
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-ReadOnly-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        let storeURL = directoryURL.appending(
            path: "Products.store",
            directoryHint: .notDirectory
        )
        let writableConfiguration = ModelConfiguration(
            "WritableProducts",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        _ = try ModelContainer(
            for: schema,
            configurations: [writableConfiguration]
        )
        let readOnlyConfiguration = ModelConfiguration(
            "ReadOnlyProducts",
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [readOnlyConfiguration]
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000009",
            name: "Rejected write"
        )

        do {
            try ProductLocalDataSource().persistPendingUpsert(
                product,
                operationID: try repositoryUUID(
                    "40000000-0000-0000-0000-000000000009"
                ),
                in: context
            )
            Issue.record("A read-only container unexpectedly accepted a save")
        } catch {}

        #expect(!context.hasChanges)
        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ProductModel>()
            ) == 0
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ProductPendingUpsertModel>()
            ) == 0
        )
    }

    @Test("Existing caller changes are preserved instead of joined to a pending upsert")
    func existingCallerChangesArePreserved() throws {
        let container = try makeRepositoryContainer()
        let corruptionContext = ModelContext(container)
        corruptionContext.insert(
            ProductModel(
                id: try repositoryUUID(
                    "30000000-0000-0000-0000-000000000013"
                ),
                name: "Corrupt durable row",
                statusRawValue: "suspended"
            )
        )
        try corruptionContext.save()
        let operationContext = ModelContext(container)
        operationContext.autosaveEnabled = false
        let unrelatedProduct = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000014",
            name: "Unrelated draft"
        )
        operationContext.insert(ProductModel(unrelatedProduct))
        let attemptedProduct = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000015",
            name: "Attempted pending upsert"
        )

        #expect(throws: ProductLocalDataSourceError.contextHasUncommittedChanges) {
            try ProductLocalDataSource().persistPendingUpsert(
                attemptedProduct,
                operationID: try repositoryUUID(
                    "40000000-0000-0000-0000-000000000015"
                ),
                in: operationContext
            )
        }

        #expect(operationContext.hasChanges)
        let operationContextIDs = Set(
            try operationContext.fetch(
                FetchDescriptor<ProductModel>()
            ).map(\.id)
        )
        #expect(operationContextIDs.contains(unrelatedProduct.id.rawValue))
        #expect(!operationContextIDs.contains(attemptedProduct.id.rawValue))
        let verificationContext = ModelContext(container)
        let durableProducts = try verificationContext.fetch(
            FetchDescriptor<ProductModel>()
        )
        #expect(durableProducts.map(\.id) == [try repositoryUUID(
            "30000000-0000-0000-0000-000000000013"
        )])
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ProductPendingUpsertModel>()
            ) == 0
        )
    }

    @Test("An identical pending upsert preserves its operation identity")
    func identicalPendingUpsertPreservesOperationIdentity() throws {
        let container = try makeRepositoryContainer()
        let dataSource = ProductLocalDataSource()
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000002",
            name: "Same snapshot"
        )
        let originalOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000002"
        )
        let replacementOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            product,
            operationID: originalOperationID,
            in: ModelContext(container)
        )

        try dataSource.persistPendingUpsert(
            product,
            operationID: replacementOperationID,
            in: ModelContext(container)
        )

        let operation = try #require(
            ModelContext(container).fetch(
                FetchDescriptor<ProductPendingUpsertModel>()
            ).only
        )
        #expect(operation.operationID == originalOperationID)
        #expect(try operation.decodePayload() == ProductDTO(product))
    }

    @Test("A changed pending upsert appends an immutable causal successor")
    func changedPendingUpsertAppendsImmutableCausalSuccessor() throws {
        let container = try makeRepositoryContainer()
        let dataSource = ProductLocalDataSource()
        let identifier = "30000000-0000-0000-0000-000000000003"
        let initialProduct = try repositoryProduct(
            id: identifier,
            name: "Initial snapshot"
        )
        let updatedProduct = try repositoryProduct(
            id: identifier,
            name: "Updated snapshot"
        )
        let originalOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000004"
        )
        let updatedOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000005"
        )
        try dataSource.persistPendingUpsert(
            initialProduct,
            operationID: originalOperationID,
            in: ModelContext(container)
        )

        try dataSource.persistPendingUpsert(
            updatedProduct,
            operationID: updatedOperationID,
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        let operations = try verificationContext.fetch(
            FetchDescriptor<ProductPendingUpsertModel>()
        )
        #expect(operations.count == 2)
        let originalOperation = try #require(
            operations.first { $0.operationID == originalOperationID }
        )
        let updatedOperation = try #require(
            operations.first { $0.operationID == updatedOperationID }
        )
        #expect(originalOperation.predecessorOperationID == nil)
        #expect(try originalOperation.decodePayload() == ProductDTO(initialProduct))
        #expect(updatedOperation.predecessorOperationID == originalOperationID)
        #expect(try updatedOperation.decodePayload() == ProductDTO(updatedProduct))
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [updatedProduct]
        )
    }

    @Test("Repository observation publishes its local write")
    func repositoryObservationPublishesItsLocalWrite() async throws {
        let container = try makeRepositoryContainer()
        let repository = makeRepository(
            container: container,
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000006"
            )
        )
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000004",
            name: "Repository route"
        )
        let stream = await repository.observeProducts()
        var observation = stream.makeAsyncIterator()

        #expect(try await observation.next() == [])
        try await repository.saveProduct(product)

        #expect(try await observation.next() == [product])
    }

    @Test("A delayed change signal reloads the current SwiftData snapshot")
    func delayedChangeSignalReloadsCurrentSnapshot() async throws {
        let container = try makeRepositoryContainer()
        let persistenceActor = ProductPersistenceActor(
            modelContainer: container
        )
        let observationSignal = ProductObservationSignal()
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000010"
        )
        let repository = DefaultProductRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            operationID: { operationID }
        )
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000010",
            name: "Newest durable snapshot"
        )
        let stream = await repository.observeProducts()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [])

        try await persistenceActor.persistPendingUpsert(
            product,
            operationID: operationID
        )
        await observationSignal.publishChange()

        #expect(try await observation.next() == [product])
    }

    @Test("A mapping failure prevents the new local write from being committed")
    func mappingFailurePreventsCommit() async throws {
        let container = try makeRepositoryContainer()
        let corruptionContext = ModelContext(container)
        corruptionContext.insert(
            ProductModel(
                id: try repositoryUUID(
                    "30000000-0000-0000-0000-000000000011"
                ),
                name: "Corrupt existing row",
                statusRawValue: "suspended"
            )
        )
        try corruptionContext.save()
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000012",
            name: "Must not commit"
        )
        let repository = makeRepository(
            container: container,
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000012"
            )
        )

        await #expect(
            throws: ProductMappingError.invalidPersistedStatus("suspended")
        ) {
            try await repository.saveProduct(product)
        }

        let verificationContext = ModelContext(container)
        let productModels = try verificationContext.fetch(
            FetchDescriptor<ProductModel>()
        )
        #expect(productModels.map(\.id) == [try repositoryUUID(
            "30000000-0000-0000-0000-000000000011"
        )])
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ProductPendingUpsertModel>()
            ) == 0
        )
    }

    @MainActor
    @Test("The contextual route matches the repository and updates its observation")
    func contextualRouteMatchesRepositoryAndUpdatesObservation() async throws {
        let repositoryContainer = try makeRepositoryContainer()
        let contextualContainer = try makeRepositoryContainer()
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000007"
        )
        let repositorySignal = ProductObservationSignal()
        let contextualSignal = ProductObservationSignal()
        let repository = DefaultProductRepository(
            persistenceActor: ProductPersistenceActor(
                modelContainer: repositoryContainer
            ),
            observationSignal: repositorySignal,
            operationID: { operationID }
        )
        let contextualRepository = DefaultProductRepository(
            persistenceActor: ProductPersistenceActor(
                modelContainer: contextualContainer
            ),
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let adapter = ProductContextualPersistenceAdapter(
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000005",
            name: "Both routes"
        )
        let stream = await contextualRepository.observeProducts()
        var contextualObservation = stream.makeAsyncIterator()
        #expect(try await contextualObservation.next() == [])

        try await repository.saveProduct(product)
        try await adapter.save(
            product,
            in: contextualContainer.mainContext
        )

        #expect(try await contextualObservation.next() == [product])
        let repositoryState = try persistedState(in: repositoryContainer)
        let contextualState = try persistedState(in: contextualContainer)
        #expect(repositoryState == contextualState)
    }

    @Test("Cancelling an observation releases its pending iteration")
    func cancellingObservationReleasesPendingIteration() async throws {
        let repository = makeRepository(
            container: try makeRepositoryContainer(),
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000008"
            )
        )
        let started = AsyncStream.makeStream(of: Void.self)
        let pendingIteration = Task {
            let stream = await repository.observeProducts()
            var observation = stream.makeAsyncIterator()
            _ = try await observation.next()
            started.continuation.yield()
            return try await observation.next()
        }
        var startedIterator = started.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        pendingIteration.cancel()

        switch await pendingIteration.result {
        case .success(nil):
            break
        case .failure(let error):
            #expect(error is CancellationError)
        case .success(.some):
            Issue.record("A cancelled observation unexpectedly emitted a snapshot")
        }
    }

    @Test("Live dependencies observe the supplied SwiftData container")
    func liveDependenciesObserveTheSuppliedSwiftDataContainer() async throws {
        let container = try makeRepositoryContainer()
        let product = try repositoryProduct(
            id: "30000000-0000-0000-0000-000000000006",
            name: "Live composition"
        )
        try ProductLocalDataSource().upsert(
            product,
            in: ModelContext(container)
        )
        let dependencies = AppDependencies.live(modelContainer: container)
        let stream = await dependencies.observeProducts()
        var observation = stream.makeAsyncIterator()

        #expect(try await observation.next() == [product])
    }
}

private struct PersistedProductState: Equatable {
    let products: [Product]
    let operationID: UUID
    let payloadVersion: Int
    let payload: ProductDTO
}

private func makeRepository(
    container: ModelContainer,
    operationID: UUID
) -> DefaultProductRepository {
    DefaultProductRepository(
        persistenceActor: ProductPersistenceActor(modelContainer: container),
        observationSignal: ProductObservationSignal(),
        operationID: { operationID }
    )
}

private func makeRepositoryContainer() throws -> ModelContainer {
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

private func persistedState(in container: ModelContainer) throws -> PersistedProductState {
    let context = ModelContext(container)
    let operation = try #require(
        context.fetch(FetchDescriptor<ProductPendingUpsertModel>()).only
    )

    return PersistedProductState(
        products: try ProductLocalDataSource().fetchAll(in: context),
        operationID: operation.operationID,
        payloadVersion: operation.payloadVersion,
        payload: try operation.decodePayload()
    )
}

private func repositoryProduct(id: String, name: String) throws -> Product {
    Product.testSnapshot(
        id: ProductID(rawValue: try repositoryUUID(id)),
        name: name
    )
}

private func repositoryUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
