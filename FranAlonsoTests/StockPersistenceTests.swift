import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Local append-only stock acceptance")
struct StockPersistenceTests {
    @Test
    @MainActor
    func `entries and withdrawals derive zero and negative balances without Product mutations`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let writer = StockPersistenceActor(modelContainer: container)
        let repository = DefaultStockRepository(persistenceActor: writer, observationSignal: ProductObservationSignal())
        #expect(try await repository.quantity(for: product.id) == 0)
        let input = try stockTestMovement(productID: product.id, delta: 5, ordinal: 1)
        let output = try stockTestMovement(productID: product.id, delta: -8, ordinal: 2)
        let correction = try stockTestMovement(productID: product.id, delta: 3, ordinal: 3)

        #expect(try await repository.append(input) == input)
        #expect(try await repository.quantity(for: product.id) == 5)
        #expect(try await repository.append(output) == output)
        #expect(try await repository.quantity(for: product.id) == -3)
        #expect(try await repository.append(correction) == correction)
        #expect(try await repository.quantity(for: product.id) == 0)
        #expect(try await repository.append(input) == input)

        let verification = ModelContext(container)
        let rows = try verification.fetch(FetchDescriptor<StockMovementModel>())
        #expect(rows.count == 3)
        #expect(rows.allSatisfy { $0.isPendingSync })
        #expect(try ProductLocalDataSource().product(id: product.id, in: verification) == product)
        #expect(try verification.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ProductPendingDeleteModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ProductRemoteStateModel>()) == 0)
    }

    @Test(arguments: StockCollisionField.allCases)
    @MainActor
    func `each changed payload field conflicts without replacing the accepted event`(
        field: StockCollisionField
    ) throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let source = StockLocalDataSource()
        let original = try stockTestMovement(productID: product.id, delta: 9, ordinal: 1)
        _ = try source.append(original, in: context)
        let before = try #require(context.fetch(FetchDescriptor<StockMovementModel>()).first).payloadData
        let collision = try stockCollision(original, field: field)

        #expect(throws: StockError.identityConflict) {
            try source.append(collision, in: context)
        }

        let verification = ModelContext(container)
        #expect(try source.movement(id: original.id, in: verification) == original)
        #expect(try source.quantity(for: product.id, in: verification) == 9)
        let rows = try verification.fetch(FetchDescriptor<StockMovementModel>())
        try #require(rows.count == 1)
        #expect(rows[0].payloadData == before)
        #expect(!context.hasChanges)
    }

    @Test(arguments: StockProductState.allCases)
    @MainActor
    func `new movements respect current Product eligibility`(state: StockProductState) throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        let context = ModelContext(container)
        context.autosaveEnabled = false
        try seedStockState(state, product: product, in: context)
        let source = StockLocalDataSource()
        let movement = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)

        if let expectedError = state.rejection {
            #expect(throws: expectedError) {
                try source.append(movement, in: context)
            }
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        } else {
            #expect(try source.append(movement, in: context) == movement)
            #expect(try source.quantity(for: product.id, in: ModelContext(container)) == 4)
            let stored = try ProductLocalDataSource().product(id: product.id, in: ModelContext(container))
            #expect(stored?.status == (state == .inactive ? .inactive : .active))
        }
    }

    @Test(arguments: [StockProductState.inactive, .pendingDeletion, .remoteTombstone, .conflict, .absent])
    @MainActor
    func `accepted identity remains successful after later Product changes`(state: StockProductState) throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let source = StockLocalDataSource()
        let original = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)
        let later = try stockTestMovement(productID: product.id, delta: -7, ordinal: 2)
        _ = try source.append(original, in: context)
        _ = try source.append(later, in: context)
        for row in try context.fetch(FetchDescriptor<ProductModel>()) {
            context.delete(row)
        }
        try context.save()
        try seedStockState(state, product: product, in: context)
        let unchangedPayloads = try stockPayloads(in: ModelContext(container))

        #expect(try source.append(original, in: context) == original)
        let unavailableCommit = StockLocalDataSource { _ in throw StockTestFailure.commit }
        #expect(try unavailableCommit.append(original, in: context) == original)
        #expect(try stockPayloads(in: ModelContext(container)) == unchangedPayloads)
        #expect(throws: StockError.identityConflict) {
            try source.append(stockCollision(original, field: .reason), in: context)
        }
        if state == .inactive || state == .conflict {
            #expect(try source.quantity(for: product.id, in: context) == -3)
        }
    }

    @Test
    @MainActor
    func `two concurrent requests sharing one writer accept exactly one row`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let writer = StockPersistenceActor(modelContainer: container)
        let signal = ProductObservationSignal()
        let firstCaller = DefaultStockRepository(persistenceActor: writer, observationSignal: signal)
        let secondCaller = DefaultStockRepository(persistenceActor: writer, observationSignal: signal)
        let movement = try stockTestMovement(productID: product.id, delta: 12, ordinal: 1)

        async let first = firstCaller.append(movement)
        async let second = secondCaller.append(movement)
        let results = try await [first, second]

        #expect(results == [movement, movement])
        #expect(try await firstCaller.quantity(for: product.id) == 12)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
    }

    @Test(arguments: [StockProductState.pendingDeletion, .remoteTombstone, .conflict, .absent])
    @MainActor
    func `warmed stock writer observes Product changes committed by another context`(
        state: StockProductState
    ) async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let repository = DefaultStockRepository(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            observationSignal: ProductObservationSignal()
        )
        let original = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)
        _ = try await repository.append(original)
        let products = ProductPersistenceActor(modelContainer: container)
        let operationID = try #require(UUID(uuidString: "95200000-0000-0000-0000-000000000002"))
        switch state {
        case .pendingDeletion:
            try await products.persistPendingDelete(product.id, operationID: operationID)
        case .remoteTombstone:
            try await products.recordRemoteObservation(ProductRemoteRecord(
                content: .tombstone(productID: product.id.rawValue),
                version: .versioned(revision: 1, lastOperationID: operationID),
                changeSequence: 1
            ))
        case .conflict:
            try await products.recordConflict(
                operation: ProductPendingUpsert(
                    productID: product.id.rawValue,
                    operationID: operationID,
                    predecessorOperationID: nil,
                    base: .absent,
                    product: ProductDTO(product)
                ),
                reason: .baseChanged,
                remoteRecord: nil
            )
        case .absent:
            try await products.delete(product.id)
        case .active, .inactive:
            Issue.record("The cross-context fixture requires a rejected Product state")
            return
        }
        let next = try stockTestMovement(productID: product.id, delta: 3, ordinal: 2)
        let rejection = try #require(state.rejection)

        #expect(try await repository.append(original) == original)
        await #expect(throws: rejection) {
            try await repository.append(next)
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
    }

    @Test
    @MainActor
    func `failed commit rolls back its event and permits recovery`() throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let movement = try stockTestMovement(productID: product.id, delta: 2, ordinal: 1)
        let failing = StockLocalDataSource { _ in throw StockTestFailure.commit }

        #expect(throws: StockError.storageFailure) {
            try failing.append(movement, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try StockLocalDataSource().append(movement, in: context) == movement)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: ModelContext(container)) == 2)
    }

    @Test
    @MainActor
    func `dirty context rejection preserves caller edits without saving or rolling them back`() throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let row = try #require(context.fetch(FetchDescriptor<ProductModel>()).first)
        row.name = "Unsaved caller edit"
        let movement = try stockTestMovement(productID: product.id, delta: 2, ordinal: 1)

        #expect(throws: StockError.storageFailure) {
            try StockLocalDataSource().append(movement, in: context)
        }

        #expect(context.hasChanges)
        #expect(row.name == "Unsaved caller edit")
        let verification = ModelContext(container)
        #expect(try ProductLocalDataSource().product(id: product.id, in: verification) == product)
        #expect(try verification.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    @MainActor
    func `cancellation before acceptance inserts no event`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let writer = StockPersistenceActor(modelContainer: container)
        let movement = try stockTestMovement(productID: product.id, delta: 2, ordinal: 1)
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            for await _ in gate.stream {
                break
            }
            return try await writer.append(movement)
        }
        task.cancel()
        gate.continuation.finish()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    @MainActor
    func `cancellation immediately after save does not hide accepted success`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: 2, ordinal: 1)
        let gate = AsyncStream<@Sendable () -> Void>.makeStream()
        let task = Task { @MainActor in
            var iterator = gate.stream.makeAsyncIterator()
            let cancel = try #require(await iterator.next())
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let source = StockLocalDataSource { savingContext in
                try savingContext.save()
                cancel()
            }
            return try source.append(movement, in: context)
        }
        gate.continuation.yield { task.cancel() }
        gate.continuation.finish()

        #expect(try await task.value == movement)
        #expect(task.isCancelled)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: ModelContext(container)) == 2)
    }

    @Test
    @MainActor
    func `overflow rejects the new event while preserving accepted quantity`() throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        let source = StockLocalDataSource()
        _ = try source.append(stockTestMovement(productID: product.id, delta: Int.max, ordinal: 1), in: context)
        let overflow = try stockTestMovement(productID: product.id, delta: 1, ordinal: 2)

        #expect(throws: StockError.quantityOverflow) {
            try source.append(overflow, in: context)
        }

        #expect(try source.quantity(for: product.id, in: ModelContext(container)) == Int.max)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(!context.hasChanges)
    }
}

enum StockCollisionField: CaseIterable {
    case product, delta, reason, date, origin
}

enum StockProductState: CaseIterable {
    case active, inactive, absent, pendingDeletion, remoteTombstone, conflict

    var rejection: StockError? {
        switch self {
        case .active, .inactive: nil
        case .absent, .pendingDeletion, .remoteTombstone: .productNotFound
        case .conflict: .productConflict
        }
    }
}

private enum StockTestFailure: Error {
    case commit
}

func stockTestContainer() throws -> ModelContainer {
    let schema = Schema(ClientDocumentsSchema.models + [StockMovementModel.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try ModelContainer(for: schema, configurations: [configuration])
}

func stockTestProduct() throws -> Product {
    Product(
        id: ProductID(rawValue: try #require(UUID(uuidString: "95000000-0000-0000-0000-000000000001"))),
        name: "Stock fixture",
        status: .active
    )
}

func stockTestMovement(productID: ProductID, delta: Int, ordinal: Int) throws -> StockMovement {
    let suffix = String(format: "%012d", ordinal)
    let id = StockMovementID(rawValue: try #require(UUID(uuidString: "95100000-0000-0000-0000-\(suffix)")))
    return try StockMovement(
        id: id,
        productID: productID,
        quantityDelta: delta,
        reason: "Physical count",
        occurredAt: Date(timeIntervalSinceReferenceDate: 12_000),
        origin: .manual(reference: id)
    )
}

func seedStockTestProduct(_ product: Product, in container: ModelContainer) throws {
    let context = ModelContext(container)
    context.insert(ProductModel(product))
    try context.save()
}

func stockPayloads(in context: ModelContext) throws -> [UUID: Data] {
    Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<StockMovementModel>()).map {
        ($0.id, $0.payloadData)
    })
}

private func stockCollision(_ original: StockMovement, field: StockCollisionField) throws -> StockMovement {
    let otherID = try #require(UUID(uuidString: "95000000-0000-0000-0000-000000000002"))
    return try StockMovement(
        id: original.id,
        productID: field == .product ? ProductID(rawValue: otherID) : original.productID,
        quantityDelta: field == .delta ? original.quantityDelta + 1 : original.quantityDelta,
        reason: field == .reason ? "Another count" : original.reason,
        occurredAt: field == .date ? original.occurredAt.addingTimeInterval(1) : original.occurredAt,
        origin: field == .origin ? .manual(reference: StockMovementID(rawValue: otherID)) : original.origin
    )
}

private func seedStockState(_ state: StockProductState, product: Product, in context: ModelContext) throws {
    if state != .absent {
        context.insert(ProductModel(Product(
            id: product.id,
            name: product.name,
            status: state == .inactive ? .inactive : .active
        )))
    }
    let operationID = try #require(UUID(uuidString: "95200000-0000-0000-0000-000000000001"))
    switch state {
    case .active, .inactive, .absent:
        break
    case .pendingDeletion:
        context.insert(try ProductPendingDeleteModel(
            productID: product.id.rawValue,
            operationID: operationID,
            predecessorOperationID: nil,
            base: .absent
        ))
    case .remoteTombstone:
        let record = ProductRemoteRecord(
            content: .tombstone(productID: product.id.rawValue),
            version: .versioned(revision: 1, lastOperationID: operationID),
            changeSequence: 1
        )
        context.insert(try ProductRemoteStateModel(record: record))
    case .conflict:
        context.insert(try ProductSyncConflictModel(
            operation: ProductPendingUpsert(
                productID: product.id.rawValue,
                operationID: operationID,
                predecessorOperationID: nil,
                base: .absent,
                product: ProductDTO(product)
            ),
            reason: .baseChanged,
            remoteRecord: nil
        ))
    }
    try context.save()
}
