import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Immutable stock feed persistence")
@MainActor
struct StockSyncPersistenceTests {
    @Test
    func `repeated remote consumption accepts one negative ledger and durable cursor`() throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: -7, ordinal: 1)
        let record = try stockSyncTestRecord(movement, sequence: 1)
        let source = StockSyncLocalDataSource()
        let batch = StockRemoteChangeBatch(records: [record], nextCursor: StockSyncCursor(changeSequence: 1))
        try source.reconcile(batch, in: ModelContext(container))
        try source.reconcile(
            StockRemoteChangeBatch(records: [], nextCursor: batch.nextCursor),
            in: ModelContext(container)
        )
        try source.acknowledge(movement, record: record, in: ModelContext(container))
        let context = ModelContext(container)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: context) == -7)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(try source.cursor(in: context)?.changeSequence == 1)
    }

    @Test
    func `divergent pull preserves ledger bytes and blocks only its identity`() throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let original = try stockTestMovement(productID: product.id, delta: 5, ordinal: 1)
        let other = try stockTestMovement(productID: product.id, delta: -1, ordinal: 2)
        let context = ModelContext(container)
        context.insert(try StockMovementModel(original))
        context.insert(try StockMovementModel(other))
        try context.save()
        let bytes = try stockPayloads(in: context)
        let remote = try stockSyncTestRecord(
            stockTestMovement(productID: product.id, delta: 50, ordinal: 1),
            sequence: 3
        )
        let source = StockSyncLocalDataSource()
        try source.reconcile(
            StockRemoteChangeBatch(records: [remote], nextCursor: StockSyncCursor(changeSequence: 3)),
            in: context
        )
        let verification = ModelContext(container)
        #expect(try stockPayloads(in: verification) == bytes)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: verification) == 4)
        #expect(try source.conflicts(in: verification).first?.remote == remote)
        #expect(try source.conflicts(in: verification).first?.local.toDomain() == original)
        #expect(try source.pending(in: verification) == [other])
        #expect(try source.cursor(in: verification)?.changeSequence == 3)
    }

    @Test
    func `missing Product retains history without restoring metadata or Sale`() throws {
        let container = try stockSyncTestContainer()
        let productID = ProductID(rawValue: UUID())
        let movement = try stockTestMovement(productID: productID, delta: -8, ordinal: 1)
        let source = StockSyncLocalDataSource()
        try source.reconcile(
            StockRemoteChangeBatch(
                records: [stockSyncTestRecord(movement, sequence: 1)],
                nextCursor: StockSyncCursor(changeSequence: 1)
            ),
            in: ModelContext(container)
        )
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(throws: StockError.productNotFound) { try StockLocalDataSource().quantity(for: productID, in: context) }
    }

    @Test
    func `failed commit rolls back complete batch cursor and retry cleanup`() throws {
        let container = try stockSyncTestContainer()
        let context = ModelContext(container)
        let state = try SyncRetryState(
            scope: .pull,
            backoffStep: 2,
            notBefore: Date(timeIntervalSinceReferenceDate: 100),
            lastRecoverableCategory: .unavailable
        )
        try StockSyncLocalDataSource().persistRetry(state, in: context)
        context.autosaveEnabled = true
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: -1, ordinal: 1)
        let source = StockSyncLocalDataSource(save: { _ in throw StockSyncError.storageFailure })
        #expect(throws: StockSyncError.storageFailure) {
            try source.reconcile(
                StockRemoteChangeBatch(
                    records: [stockSyncTestRecord(movement, sequence: 1)],
                    nextCursor: StockSyncCursor(changeSequence: 1)
                ),
                in: context
            )
        }
        #expect(!context.hasChanges)
        #expect(context.autosaveEnabled)
        let check = ModelContext(container)
        #expect(try check.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try source.cursor(in: check) == nil)
        #expect(try source.retryState(for: .pull, in: check) == state)
    }

    @Test
    func `dirty caller retains unrelated edits on rejection`() throws {
        let container = try stockSyncTestContainer()
        let context = ModelContext(container)
        let product = try stockTestProduct()
        context.insert(ProductModel(product))
        #expect(throws: StockSyncError.storageFailure) {
            try StockSyncLocalDataSource().reconcile(
                StockRemoteChangeBatch(records: [], nextCursor: StockSyncCursor(changeSequence: 0)),
                in: context
            )
        }
        #expect(context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 1)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
    }

    @Test
    func `overflow rejects whole batch and never repairs invalid existing history`() throws {
        let container = try stockSyncTestContainer()
        let context = ModelContext(container)
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let maximum = try stockTestMovement(productID: product.id, delta: Int.max, ordinal: 1)
        context.insert(try StockMovementModel(maximum))
        try context.save()
        let source = StockSyncLocalDataSource()
        let overflow = try stockTestMovement(productID: product.id, delta: 1, ordinal: 2)
        #expect(throws: StockError.quantityOverflow) {
            try source.reconcile(
                StockRemoteChangeBatch(
                    records: [stockSyncTestRecord(overflow, sequence: 1)],
                    nextCursor: StockSyncCursor(changeSequence: 1)
                ),
                in: context
            )
        }
        #expect(try source.cursor(in: context) == nil)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        context.insert(try StockMovementModel(overflow))
        try context.save()
        let correction = try stockTestMovement(productID: product.id, delta: -1, ordinal: 3)
        #expect(throws: StockError.quantityOverflow) {
            try source.reconcile(
                StockRemoteChangeBatch(
                    records: [stockSyncTestRecord(correction, sequence: 2)],
                    nextCursor: StockSyncCursor(changeSequence: 2)
                ),
                in: context
            )
        }
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 2)
    }

    @Test
    func `acknowledgement checks full pending payload and metadata`() throws {
        let container = try stockSyncTestContainer()
        let context = ModelContext(container)
        let product = try stockTestProduct()
        let local = try stockTestMovement(productID: product.id, delta: -3, ordinal: 1)
        context.insert(try StockMovementModel(local))
        try context.save()
        let bad = try stockSyncTestRecord(stockTestMovement(productID: product.id, delta: -4, ordinal: 1), sequence: 1)
        #expect(throws: StockSyncError.identityConflict) {
            try StockSyncLocalDataSource().acknowledge(local, record: bad, in: context)
        }
        #expect(try #require(context.fetch(FetchDescriptor<StockMovementModel>()).first).isPendingSync)
        #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 0)
    }

    @Test(arguments: ["duplicateID", "duplicateSequence", "futureVersion", "wrongCursor", "invalidRevision"])
    func `invalid batch cannot partially consume a valid preceding record`(fault: String) throws {
        let container = try stockSyncTestContainer()
        let first = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        let second = try stockTestMovement(
            productID: first.productID,
            delta: 2,
            ordinal: fault == "duplicateID" ? 1 : 2
        )
        var dto = try StockMovementDTO(second)
        if fault == "futureVersion" {
            dto = StockMovementDTO(
                payloadVersion: 99,
                id: dto.id,
                productID: dto.productID,
                quantityDelta: dto.quantityDelta,
                reason: dto.reason,
                occurredAt: dto.occurredAt,
                origin: dto.origin
            )
        }
        let record = StockRemoteRecord(
            movement: dto,
            revision: fault == "invalidRevision" ? 2 : 1,
            operationID: second.id.rawValue,
            changeSequence: fault == "duplicateSequence" ? 1 : 2
        )
        let batch = StockRemoteChangeBatch(
            records: [try stockSyncTestRecord(first, sequence: 1), record],
            nextCursor: StockSyncCursor(changeSequence: fault == "wrongCursor" ? 3 : 2)
        )
        #expect(throws: (any Error).self) {
            try StockSyncLocalDataSource().reconcile(batch, in: ModelContext(container))
        }
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StockSyncCursorModel>()) == 0)
    }

}

func stockSyncTestContainer() throws -> ModelContainer {
    let schema = Schema(versionedSchema: StockSyncSchema.self)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, configurations: [configuration])
}

func stockSyncTestRecord(_ movement: StockMovement, sequence: Int64) throws -> StockRemoteRecord {
    StockRemoteRecord(
        movement: try StockMovementDTO(movement),
        revision: 1,
        operationID: movement.id.rawValue,
        changeSequence: sequence
    )
}
