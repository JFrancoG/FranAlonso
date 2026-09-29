import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Stock contextual acceptance")
@MainActor
struct StockContextualPersistenceTests {
    @Test
    func `acceptance uses the supplied store and retry does not create a second row`() async throws {
        let container = try stockTestContainer()
        let unrelated = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: -3, ordinal: 1)
        let context = ModelContext(container)
        let adapter = StockContextualPersistenceAdapter()

        #expect(try await adapter.append(movement, in: context) == movement)
        #expect(try await adapter.append(movement, in: context) == movement)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: ModelContext(container)) == -3)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(try ModelContext(unrelated).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    func `dirty caller changes survive a rejected adjustment`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let unsaved = Product(id: ProductID(rawValue: UUID()), name: "Unsaved", status: .active)
        context.insert(ProductModel(unsaved))
        let movement = try stockTestMovement(productID: product.id, delta: 1, ordinal: 1)
        await #expect(throws: StockError.storageFailure) {
            try await StockContextualPersistenceAdapter().append(movement, in: context)
        }
        #expect(context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 2)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 1)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    func `concurrent UI requests sharing a context accept each identity once`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = container.mainContext
        let movement = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)
        let withdrawal = try stockTestMovement(productID: product.id, delta: -7, ordinal: 2)
        let adapter = StockContextualPersistenceAdapter()
        let first = Task { @MainActor in
            try await adapter.append(movement, in: context)
        }
        let duplicate = Task { @MainActor in
            try await adapter.append(movement, in: context)
        }
        let second = Task { @MainActor in
            try await adapter.append(withdrawal, in: context)
        }
        let accepted = try await [first.value, duplicate.value, second.value]
        #expect(accepted == [movement, movement, withdrawal])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 2)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: ModelContext(container)) == -3)
    }

    @Test
    func `identity collision and commit failure preserve accepted history`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = ModelContext(container)
        let movement = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)
        let adapter = StockContextualPersistenceAdapter()
        _ = try await adapter.append(movement, in: context)
        let collision = try stockTestMovement(productID: product.id, delta: 5, ordinal: 1)
        await #expect(throws: StockError.identityConflict) {
            try await adapter.append(collision, in: context)
        }
        let failing = StockContextualPersistenceAdapter(dataSource: StockLocalDataSource { _ in
            throw StockContextualFailure.commit
        })
        let another = try stockTestMovement(productID: product.id, delta: -2, ordinal: 2)
        await #expect(throws: StockError.storageFailure) {
            try await failing.append(another, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(try StockLocalDataSource().quantity(for: product.id, in: ModelContext(container)) == 4)
    }

    @Test
    func `prior cancellation writes no movement through the contextual adapter`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let context = container.mainContext
        let movement = try stockTestMovement(productID: product.id, delta: 4, ordinal: 1)
        let writing = Task {
            try await StockContextualPersistenceAdapter().append(movement, in: context)
        }
        writing.cancel()
        await #expect(throws: CancellationError.self) {
            try await writing.value
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

}


private enum StockContextualFailure: Error {
    case commit
}
