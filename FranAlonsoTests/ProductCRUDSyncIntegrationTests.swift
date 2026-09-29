import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product commands through synchronization")
struct ProductCRUDSyncIntegrationTests {
    @Test
    func `CRUD converges to one inactive remote document and repeated deactivation does not write`() async throws {
        let fixture = try ProductCRUDSyncFixture()
        let id = ProductID(rawValue: try productSyncUUID("01"))
        let createID = try productSyncUUID("11")
        let editID = try productSyncUUID("12")
        let deactivateID = try productSyncUUID("13")
        let read = fixture.repository(operationID: createID)
        _ = try await CreateProductUseCase(repository: read)(id: id, profile: ProductProfile(name: "Before"))
        _ = try await UpdateProductUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: ProductProfile(name: "After")
        )
        let deactivate = DeactivateProductUseCase(repository: fixture.repository(operationID: deactivateID))
        try await deactivate(id)
        let remote = ProductSyncRemoteFake()
        let engine = fixture.engine(remote: remote)

        try await engine.synchronize()
        try await engine.synchronize()
        try await deactivate(id)
        try await engine.synchronize()

        let expected = ProductRemoteRecord(
            product: ProductDTO(id: id.rawValue.uuidString, name: "After", status: .inactive),
            version: .versioned(revision: 3, lastOperationID: deactivateID),
            changeSequence: 3
        )
        #expect(await remote.record(for: id.rawValue) == expected)
        #expect(await remote.recordCount == 1)
        #expect(await remote.appliedOperationIDs == [createID, editID, deactivateID])
        #expect(await remote.receivedOperationIDs == [createID, editID, deactivateID])
        #expect(try await fixture.actor.pendingOperations().isEmpty)
        #expect(try await GetProductUseCase(repository: read)(id) == Product(id: id, name: "After", status: .inactive))
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
    }

    @Test
    @MainActor
    func `an older acknowledgement never reactivates a product deactivated through the contextual route`() async throws {
        let fixture = try ProductCRUDSyncFixture()
        let id = ProductID(rawValue: try productSyncUUID("02"))
        let createID = try productSyncUUID("21")
        let deactivateID = try productSyncUUID("22")
        let repository = fixture.repository(operationID: createID)
        let created = try await CreateProductUseCase(repository: repository)(
            id: id,
            profile: ProductProfile(name: "Retained profile")
        )
        var observation = await repository.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [created])
        let gate = ProductSyncAcknowledgementGate()
        let remote = ProductSyncRemoteFake(acknowledgementGate: gate)
        let engine = fixture.engine(remote: remote)
        let adapter = ProductContextualPersistenceAdapter(
            observationSignal: fixture.signal,
            operationID: { deactivateID }
        )
        async let synchronization: Void = engine.synchronize()
        await gate.waitUntilBlocked()
        do {
            try await adapter.deactivate(id, in: fixture.container.mainContext)
        } catch {
            await gate.release()
            _ = try? await synchronization
            throw error
        }
        await gate.release()
        try await synchronization

        let inactive = Product(id: id, name: "Retained profile", status: .inactive)
        #expect(try await repository.product(id: id) == inactive)
        let pending = try await fixture.actor.pendingUpserts()
        try #require(pending.count == 1)
        #expect(pending.first?.operationID == deactivateID)
        #expect(pending.first?.predecessorOperationID == createID)
        #expect(pending.first?.product.status == .inactive)
        var observed = try await observation.next()
        while let snapshot = observed, snapshot != [inactive] {
            observed = try await observation.next()
        }
        #expect(observed == [inactive])

        try await engine.synchronize()

        #expect(try await repository.product(id: id) == inactive)
        #expect(try await fixture.actor.pendingOperations().isEmpty)
        #expect(await remote.record(for: id.rawValue) == ProductRemoteRecord(
            product: ProductDTO(id: id.rawValue.uuidString, name: "Retained profile", status: .inactive),
            version: .versioned(revision: 2, lastOperationID: deactivateID),
            changeSequence: 2
        ))
        #expect(await remote.appliedOperationIDs == [createID, deactivateID])
    }

    @Test
    func `a pulled conflict preserves the command chain and blocks only that product`() async throws {
        let fixture = try ProductCRUDSyncFixture()
        let id = ProductID(rawValue: try productSyncUUID("03"))
        let createID = try productSyncUUID("31")
        let editID = try productSyncUUID("32")
        let deactivateID = try productSyncUUID("33")
        let remoteID = try productSyncUUID("34")
        let repository = fixture.repository(operationID: createID)
        _ = try await CreateProductUseCase(repository: repository)(id: id, profile: ProductProfile(name: "Original"))
        let remote = ProductSyncRemoteFake()
        let engine = fixture.engine(remote: remote)
        try await engine.synchronize()
        _ = try await UpdateProductUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: ProductProfile(name: "Local edit")
        )
        try await DeactivateProductUseCase(repository: fixture.repository(operationID: deactivateID))(id)
        let before = try await fixture.actor.pendingOperations()
        let concurrent = ProductRemoteRecord(
            product: ProductDTO(id: id.rawValue.uuidString, name: "Concurrent remote", status: .active),
            version: .versioned(revision: 2, lastOperationID: remoteID),
            changeSequence: 2
        )
        try await remote.receive(concurrent)

        try await engine.synchronize()

        #expect(try await repository.product(id: id) == Product(id: id, name: "Local edit", status: .inactive))
        #expect(try await fixture.actor.pendingOperations() == before)
        let context = ModelContext(fixture.container)
        let conflicts = try context.fetch(FetchDescriptor<ProductSyncConflictModel>())
        try #require(conflicts.count == 1)
        let conflict = try #require(conflicts.first)
        #expect(try conflict.decodeLocalProduct() == ProductDTO(
            id: id.rawValue.uuidString,
            name: "Local edit",
            status: .active
        ))
        #expect(try conflict.decodeRemoteRecord() == concurrent)
        await #expect(throws: ProductError.conflict) {
            try await UpdateProductUseCase(repository: repository)(id: id, profile: ProductProfile(name: "Blocked"))
        }
        await #expect(throws: ProductError.conflict) {
            try await DeactivateProductUseCase(repository: repository)(id)
        }

        let otherID = ProductID(rawValue: try productSyncUUID("04"))
        let otherOperationID = try productSyncUUID("41")
        _ = try await CreateProductUseCase(repository: fixture.repository(operationID: otherOperationID))(
            id: otherID,
            profile: ProductProfile(name: "Still operable")
        )
        try await engine.synchronize()

        #expect(try await fixture.actor.pendingOperations() == before)
        #expect(await remote.record(for: id.rawValue) == concurrent)
        #expect(await remote.record(for: otherID.rawValue)?.liveProduct?.name == "Still operable")
        #expect(await remote.appliedOperationIDs == [createID, otherOperationID])
        #expect(await remote.receivedOperationIDs == [createID, otherOperationID])
    }

    @Test
    func `a pulled tombstone disappears from local observation and cannot be restored by CRUD`() async throws {
        let fixture = try ProductCRUDSyncFixture()
        let id = ProductID(rawValue: try productSyncUUID("05"))
        let createID = try productSyncUUID("51")
        let editID = try productSyncUUID("52")
        let deactivateID = try productSyncUUID("53")
        let deleteID = try productSyncUUID("54")
        let repository = fixture.repository(operationID: createID)
        _ = try await CreateProductUseCase(repository: repository)(id: id, profile: ProductProfile(name: "Original"))
        let remote = ProductSyncRemoteFake()
        let engine = fixture.engine(remote: remote)
        try await engine.synchronize()
        _ = try await UpdateProductUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: ProductProfile(name: "Pending edit")
        )
        try await DeactivateProductUseCase(repository: fixture.repository(operationID: deactivateID))(id)
        let before = try await fixture.actor.pendingOperations()
        var observation = await ObserveProductsUseCase(repository: repository)().makeAsyncIterator()
        #expect(try await observation.next() == [Product(id: id, name: "Pending edit", status: .inactive)])
        let tombstone = ProductRemoteRecord(
            content: .tombstone(productID: id.rawValue),
            version: .versioned(revision: 2, lastOperationID: deleteID),
            changeSequence: 2
        )
        try await remote.receive(tombstone)

        try await engine.synchronize()

        #expect(try await observation.next() == [])
        #expect(try await GetProductUseCase(repository: repository)(id) == nil)
        await #expect(throws: ProductError.alreadyExists) {
            try await CreateProductUseCase(repository: repository)(id: id, profile: ProductProfile(name: "Restore"))
        }
        await #expect(throws: ProductError.deleted) {
            try await UpdateProductUseCase(repository: repository)(id: id, profile: ProductProfile(name: "Restore"))
        }
        await #expect(throws: ProductError.deleted) {
            try await DeactivateProductUseCase(repository: repository)(id)
        }
        try await engine.synchronize()

        #expect(try await fixture.actor.pendingOperations() == before)
        #expect(try await repository.product(id: id) == nil)
        let conflicts = try ModelContext(fixture.container).fetch(FetchDescriptor<ProductSyncConflictModel>())
        try #require(conflicts.count == 1)
        let conflict = try #require(conflicts.first)
        #expect(try conflict.decodeLocalProduct() == ProductDTO(
            id: id.rawValue.uuidString,
            name: "Pending edit",
            status: .active
        ))
        #expect(try conflict.decodeRemoteRecord() == tombstone)
        #expect(await remote.record(for: id.rawValue) == tombstone)
        #expect(await remote.appliedOperationIDs == [createID])
        #expect(await remote.receivedOperationIDs == [createID])
    }
}

private struct ProductCRUDSyncFixture {
    let container: ModelContainer
    let actor: ProductPersistenceActor
    let signal: ProductObservationSignal

    func repository(operationID: UUID) -> DefaultProductRepository {
        DefaultProductRepository(
            persistenceActor: actor,
            observationSignal: signal,
            operationID: { operationID }
        )
    }

    func engine(remote: ProductSyncRemoteFake) -> ProductSyncEngine {
        ProductSyncEngine(
            persistenceActor: actor,
            remoteDataSource: remote,
            observationSignal: signal,
            timing: SyncTiming(
                now: { Date(timeIntervalSinceReferenceDate: 1_000) },
                sleep: { _ in },
                jitterFactor: { 1 }
            )
        )
    }
}

private extension ProductCRUDSyncFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        self.init(
            container: container,
            actor: ProductPersistenceActor(modelContainer: container),
            signal: ProductObservationSignal()
        )
    }
}

private func productSyncUUID(_ suffix: String) throws -> UUID {
    try #require(UUID(uuidString: "09020000-0000-0000-0000-0000000000\(suffix)"))
}
