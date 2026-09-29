import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Durable stock history and invalid storage")
struct StockDurabilityTests {
    @Test
    @MainActor
    func `pending movements and exact retries survive two complete store reopenings`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "stock.store")
        let product = try stockTestProduct()
        let first = try stockTestMovement(productID: product.id, delta: 8, ordinal: 1)
        let second = try stockTestMovement(productID: product.id, delta: -11, ordinal: 2)
        let lifetime = StockTestLifetime()

        let payloads = try await acceptStockOnDisk(
            at: url,
            product: product,
            movements: [first, second],
            lifetime: lifetime
        )
        #expect(lifetime.container == nil)
        #expect(lifetime.writer == nil)
        try await retryReopenedStock(at: url, original: first, payloads: payloads, lifetime: lifetime)
        #expect(lifetime.container == nil)
        #expect(lifetime.writer == nil)
        try verifyReopenedStock(at: url, product: product, payloads: payloads, lifetime: lifetime)
        #expect(lifetime.container == nil)
    }

    @Test(arguments: StockStorageCorruption.allCases)
    @MainActor
    func `unsupported or inconsistent stored rows fail neutrally without replacing history`(
        corruption: StockStorageCorruption
    ) async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let otherID = try #require(UUID(uuidString: "95300000-0000-0000-0000-000000000001"))
        let payloadProductID = corruption == .productIndex ? ProductID(rawValue: otherID) : product.id
        let movement = try stockTestMovement(productID: payloadProductID, delta: 7, ordinal: 1)
        let rowID = corruption == .movementIndex ? otherID : movement.id.rawValue
        let payload = corruption == .truncatedPayload ? Data("{".utf8) : try JSONEncoder().encode(movement)
        let context = ModelContext(container)
        context.insert(StockMovementModel(
            id: rowID,
            productID: product.id.rawValue,
            payloadVersion: corruption == .unsupportedVersion ? 99 : 1,
            payloadData: payload,
            isPendingSync: true
        ))
        try context.save()
        let repository = DefaultStockRepository(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            observationSignal: ProductObservationSignal()
        )

        await #expect(throws: StockError.storageFailure) {
            try await repository.movement(id: StockMovementID(rawValue: rowID))
        }
        await #expect(throws: StockError.storageFailure) {
            try await repository.quantity(for: product.id)
        }
        let next = try stockTestMovement(productID: product.id, delta: 2, ordinal: 2)
        await #expect(throws: StockError.storageFailure) {
            try await repository.append(next)
        }
        let rows = try ModelContext(container).fetch(FetchDescriptor<StockMovementModel>())
        try #require(rows.count == 1)
        #expect(rows[0].payloadData == payload)
    }

    @Test
    @MainActor
    func `an already unrepresentable balance cannot be silently repaired by a new movement`() throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        context.insert(try StockMovementModel(stockTestMovement(productID: product.id, delta: Int.max, ordinal: 1)))
        context.insert(try StockMovementModel(stockTestMovement(productID: product.id, delta: 1, ordinal: 2)))
        try context.save()
        let source = StockLocalDataSource()
        let correction = try stockTestMovement(productID: product.id, delta: -1, ordinal: 3)

        #expect(throws: StockError.quantityOverflow) {
            try source.quantity(for: product.id, in: context)
        }
        #expect(throws: StockError.quantityOverflow) {
            try source.append(correction, in: context)
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 2)
        #expect(!context.hasChanges)
    }
}

enum StockStorageCorruption: CaseIterable {
    case unsupportedVersion, truncatedPayload, movementIndex, productIndex
}

@MainActor
private final class StockTestLifetime {
    weak var container: ModelContainer?
    weak var writer: StockPersistenceActor?
}

private func stockDiskContainer(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: StockMovementsSchema.self)
    let configuration = ModelConfiguration(
        "StockDurability",
        schema: schema,
        url: url,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

@MainActor
private func acceptStockOnDisk(
    at url: URL,
    product: Product,
    movements: [StockMovement],
    lifetime: StockTestLifetime
) async throws -> [UUID: Data] {
    let container = try stockDiskContainer(at: url)
    try seedStockTestProduct(product, in: container)
    let writer = StockPersistenceActor(modelContainer: container)
    let repository = DefaultStockRepository(persistenceActor: writer, observationSignal: ProductObservationSignal())
    lifetime.container = container
    lifetime.writer = writer
    for movement in movements {
        _ = try await repository.append(movement)
    }
    return try stockPayloads(in: ModelContext(container))
}

@MainActor
private func retryReopenedStock(
    at url: URL,
    original: StockMovement,
    payloads: [UUID: Data],
    lifetime: StockTestLifetime
) async throws {
    let container = try stockDiskContainer(at: url)
    let writer = StockPersistenceActor(modelContainer: container)
    let repository = DefaultStockRepository(persistenceActor: writer, observationSignal: ProductObservationSignal())
    lifetime.container = container
    lifetime.writer = writer

    #expect(try await repository.movement(id: original.id) == original)
    #expect(try await repository.append(original) == original)
    #expect(try await repository.quantity(for: original.productID) == -3)
    #expect(try stockPayloads(in: ModelContext(container)) == payloads)
}

@MainActor
private func verifyReopenedStock(
    at url: URL,
    product: Product,
    payloads: [UUID: Data],
    lifetime: StockTestLifetime
) throws {
    let container = try stockDiskContainer(at: url)
    lifetime.container = container
    let context = ModelContext(container)
    #expect(try stockPayloads(in: context) == payloads)
    #expect(try StockLocalDataSource().quantity(for: product.id, in: context) == -3)
    let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
    #expect(rows.count == 2)
    #expect(rows.allSatisfy { $0.isPendingSync && $0.payloadVersion == 1 })
    #expect(try ProductLocalDataSource().product(id: product.id, in: context) == product)
    #expect(try context.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
}
