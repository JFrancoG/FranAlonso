import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product CRUD durable synchronization")
struct ProductCRUDDurabilityTests {
    @Test
    @MainActor
    func `offline CRUD and push retry survive two store reopenings without duplicate remote writes`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appending(path: "products.store")
        let fixture = ProductDurabilityFixture(
            id: ProductID(rawValue: try #require(UUID(uuidString: "92000000-0000-0000-0000-000000000001"))),
            creationID: try #require(UUID(uuidString: "92100000-0000-0000-0000-000000000001")),
            renameID: try #require(UUID(uuidString: "92100000-0000-0000-0000-000000000002")),
            deactivationID: try #require(UUID(uuidString: "92100000-0000-0000-0000-000000000003"))
        )
        let start = Date(timeIntervalSinceReferenceDate: 12_000)
        let timing = ProductRetryManualTiming(now: start)
        let remote = ProductDurabilityRemote()
        let lifetime = ProductDurabilityLifetime()

        let payloads = try await acceptOfflineProductChain(
            at: storeURL,
            fixture: fixture,
            remote: remote,
            timing: timing,
            lifetime: lifetime
        )

        #expect(lifetime.container == nil)
        #expect(lifetime.persistenceActor == nil)
        #expect(lifetime.engine == nil)
        #expect(await remote.failedOperationIDs == Array(repeating: fixture.creationID, count: 3))
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2)])
        #expect(await remote.storage.recordCount == 0)

        try await recoverReopenedProductChain(
            at: storeURL,
            fixture: fixture,
            payloads: payloads,
            retryDeadline: start.addingTimeInterval(7),
            remote: remote,
            timing: timing,
            lifetime: lifetime
        )

        #expect(lifetime.container == nil)
        #expect(lifetime.persistenceActor == nil)
        #expect(lifetime.engine == nil)
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2), .seconds(4)])
        #expect(await remote.storage.appliedOperationIDs == fixture.operationIDs)
        #expect(await remote.storage.receivedOperationIDs == fixture.operationIDs)
        #expect(await remote.storage.recordCount == 1)
        #expect(await remote.storage.record(for: fixture.id.rawValue) == fixture.finalRemoteRecord)
        #expect(await remote.storage.requestedCursors == [
            nil,
            ProductSyncCursor(changeSequence: 0),
            ProductSyncCursor(changeSequence: 0)
        ])

        try verifyRecoveredProductStore(at: storeURL, fixture: fixture, lifetime: lifetime)

        #expect(lifetime.container == nil)
    }
}

private struct ProductDurabilityFixture {
    let id: ProductID
    let creationID: UUID
    let renameID: UUID
    let deactivationID: UUID

    var operationIDs: [UUID] { [creationID, renameID, deactivationID] }
    var inactiveProduct: Product { Product(id: id, name: "Renamed offline", status: .inactive) }
    var finalRemoteRecord: ProductRemoteRecord {
        ProductRemoteRecord(
            product: ProductDTO(id: id.rawValue.uuidString, name: "Renamed offline", status: .inactive),
            version: .versioned(revision: 3, lastOperationID: deactivationID),
            changeSequence: 3
        )
    }
}

private struct ProductDurabilityPayload: Equatable {
    let baseVersion: Int?
    let baseData: Data?
    let payloadVersion: Int
    let payloadData: Data
}

@MainActor
private final class ProductDurabilityLifetime {
    weak var container: ModelContainer?
    weak var persistenceActor: ProductPersistenceActor?
    weak var engine: ProductSyncEngine?
}

private actor ProductDurabilityRemote: ProductRemoteDataSource {
    let storage = ProductSyncRemoteFake()
    private var unavailable = true
    private(set) var failedOperationIDs: [UUID] = []

    func fetchChanges(after cursor: ProductSyncCursor?) async throws -> ProductRemoteChangeBatch {
        try await storage.fetchChanges(after: cursor)
    }

    func apply(_ operation: ProductPendingOperation) async throws -> ProductRemoteMutationResult {
        if unavailable {
            failedOperationIDs.append(operation.operationID)
            throw ProductRemoteDataSourceError.unavailable
        }
        return try await storage.apply(operation)
    }

    func recover() {
        unavailable = false
    }
}

@MainActor
private func acceptOfflineProductChain(
    at storeURL: URL,
    fixture: ProductDurabilityFixture,
    remote: ProductDurabilityRemote,
    timing: ProductRetryManualTiming,
    lifetime: ProductDurabilityLifetime
) async throws -> [UUID: ProductDurabilityPayload] {
    let container = try productDurabilityContainer(at: storeURL)
    let persistenceActor = ProductPersistenceActor(modelContainer: container)
    let signal = ProductObservationSignal()
    let creationRepository = DefaultProductRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.creationID }
    )
    let renameRepository = DefaultProductRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.renameID }
    )
    let deactivationRepository = DefaultProductRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.deactivationID }
    )
    _ = try await CreateProductUseCase(repository: creationRepository)(
        id: fixture.id,
        profile: ProductProfile(name: "Created offline")
    )
    _ = try await UpdateProductUseCase(repository: renameRepository)(
        id: fixture.id,
        profile: ProductProfile(name: "Renamed offline")
    )
    try await DeactivateProductUseCase(repository: deactivationRepository)(fixture.id)
    let engine = ProductSyncEngine(
        persistenceActor: persistenceActor,
        remoteDataSource: remote,
        observationSignal: signal,
        timing: timing.dependency
    )
    lifetime.container = container
    lifetime.persistenceActor = persistenceActor
    lifetime.engine = engine

    await #expect(throws: ProductRemoteDataSourceError.unavailable) {
        try await engine.synchronize()
    }

    #expect(try await GetProductUseCase(repository: creationRepository)(fixture.id) == fixture.inactiveProduct)
    return try productDurabilityPayloads(in: ModelContext(container))
}

@MainActor
private func recoverReopenedProductChain(
    at storeURL: URL,
    fixture: ProductDurabilityFixture,
    payloads: [UUID: ProductDurabilityPayload],
    retryDeadline: Date,
    remote: ProductDurabilityRemote,
    timing: ProductRetryManualTiming,
    lifetime: ProductDurabilityLifetime
) async throws {
    let container = try productDurabilityContainer(at: storeURL)
    let persistenceActor = ProductPersistenceActor(modelContainer: container)
    let signal = ProductObservationSignal()
    let repository = DefaultProductRepository(persistenceActor: persistenceActor, observationSignal: signal)
    let context = ModelContext(container)
    let operations = try await persistenceActor.pendingUpserts()
    try #require(operations.count == 3)
    #expect(operations.map(\.operationID) == fixture.operationIDs)
    #expect(operations.map(\.productID) == Array(repeating: fixture.id.rawValue, count: 3))
    #expect(operations.map(\.predecessorOperationID) == [nil, fixture.creationID, fixture.renameID])
    #expect(operations.map(\.base) == [.absent, .absent, .absent])
    #expect(operations.map(\.product) == [
        ProductDTO(id: fixture.id.rawValue.uuidString, name: "Created offline", status: .active),
        ProductDTO(id: fixture.id.rawValue.uuidString, name: "Renamed offline", status: .active),
        ProductDTO(id: fixture.id.rawValue.uuidString, name: "Renamed offline", status: .inactive)
    ])
    #expect(try productDurabilityPayloads(in: context) == payloads)
    #expect(try await GetProductUseCase(repository: repository)(fixture.id) == fixture.inactiveProduct)
    #expect(try await persistenceActor.cursor() == ProductSyncCursor(changeSequence: 0))
    #expect(try context.fetchCount(FetchDescriptor<ProductRemoteStateModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ProductSyncRetryModel>()) == 1)
    #expect(try await persistenceActor.retryState(for: .operation(fixture.creationID)) == SyncRetryState(
        scope: .operation(fixture.creationID),
        backoffStep: 3,
        notBefore: retryDeadline,
        lastRecoverableCategory: .unavailable
    ))
    let engine = ProductSyncEngine(
        persistenceActor: persistenceActor,
        remoteDataSource: remote,
        observationSignal: signal,
        timing: timing.dependency
    )
    lifetime.container = container
    lifetime.persistenceActor = persistenceActor
    lifetime.engine = engine

    await remote.recover()
    try await engine.synchronize()
    try await engine.synchronize()

    #expect(try await persistenceActor.pendingOperations().isEmpty)
    #expect(try await persistenceActor.retryState(for: .operation(fixture.creationID)) == nil)
    #expect(try await persistenceActor.cursor() == ProductSyncCursor(changeSequence: 3))
}

@MainActor
private func verifyRecoveredProductStore(
    at storeURL: URL,
    fixture: ProductDurabilityFixture,
    lifetime: ProductDurabilityLifetime
) throws {
    let container = try productDurabilityContainer(at: storeURL)
    lifetime.container = container
    let context = ModelContext(container)
    let source = ProductLocalDataSource()

    #expect(try source.fetchAll(in: context) == [fixture.inactiveProduct])
    #expect(try source.pendingOperations(in: context).isEmpty)
    #expect(try source.cursor(in: context) == ProductSyncCursor(changeSequence: 3))
    #expect(try context.fetchCount(FetchDescriptor<ProductSyncRetryModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ProductSyncConflictModel>()) == 0)
    let remoteStates = try context.fetch(FetchDescriptor<ProductRemoteStateModel>())
    try #require(remoteStates.count == 1)
    #expect(try remoteStates[0].decodeRecord() == fixture.finalRemoteRecord)
}

private func productDurabilityContainer(at storeURL: URL) throws -> ModelContainer {
    let schema = Schema.franAlonso
    let configuration = ModelConfiguration(
        "ProductCRUDDurability",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

private func productDurabilityPayloads(in context: ModelContext) throws -> [UUID: ProductDurabilityPayload] {
    let rows = try context.fetch(FetchDescriptor<ProductPendingUpsertModel>())
    return Dictionary(uniqueKeysWithValues: rows.map { row in
        (row.operationID, ProductDurabilityPayload(
            baseVersion: row.baseVersion,
            baseData: row.baseData,
            payloadVersion: row.payloadVersion,
            payloadData: row.payloadData
        ))
    })
}
