import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Stock screen composition")
@MainActor
struct StockScreenCompositionTests {
    @Test
    func `interactive preview persists a withdrawal and reopening reads the new balance`() async throws {
        let preview = try AppPreviewModifier.makeSharedContext()
        let context = preview.modelContainer.mainContext
        let product = ProductPreviewFixtures.standard.primaryProduct
        let form = preview.dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await form.load()
        #expect(form.quantity == 0)
        form.direction = .withdrawal
        form.unitsText = "3"
        form.reason = "Uso interno"
        await form.save(in: context)
        #expect(form.isAccepted)
        #expect(form.balanceState == .loaded(-3))
        let reopened = preview.dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await reopened.load()
        #expect(reopened.quantity == -3)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
    }

    @Test
    func `live composition shares contextual writes with its ledger reads`() async throws {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        try ProductPreviewFixtures.standard.seed(in: container.mainContext)
        let dependencies = AppDependencies.live(modelContainer: container)
        let product = ProductPreviewFixtures.standard.secondaryProduct
        let form = dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await form.load()
        #expect(form.loadedProduct?.status == .inactive)
        form.unitsText = "4"
        form.reason = "Inventario"
        await form.save(in: container.mainContext)
        #expect(form.isAccepted)
        let reopened = dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await reopened.load()
        #expect(reopened.quantity == 4)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
    }

    @Test
    func `finite snapshot rejects stock writes without changing persistent state`() async throws {
        let product = ProductPreviewFixtures.standard.primaryProduct
        let dependencies = AppDependencies.preview(products: [product])
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let form = dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await form.load()
        form.unitsText = "5"
        form.reason = "Inventario"
        await form.save(in: container.mainContext)
        #expect(form.state == .failed(.save, .storageFailure))
        #expect(!form.isAccepted)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(!container.mainContext.hasChanges)
    }

    #if FRANALONSO_AUTH_FIXTURE
    @Test
    func `demo seeds stock persists within a session and resets on a new launch`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        let context = demo.modelContainer.mainContext
        let products = try ProductLocalDataSource().fetchAll(in: context)
        let first = try #require(products.first)
        let second = try #require(products.last)
        let source = StockLocalDataSource()
        #expect(try source.quantity(for: first.id, in: context) == 8)
        #expect(try source.quantity(for: second.id, in: context) == 2)
        let form = demo.dependencies.makeStockAdjustment(.init(id: UUID(), productID: first.id))
        await form.load()
        form.direction = .withdrawal
        form.unitsText = "10"
        form.reason = "Recuento demo"
        await form.save(in: context)
        #expect(form.balanceState == .loaded(-2))
        let reopened = demo.dependencies.makeStockAdjustment(.init(id: UUID(), productID: first.id))
        await reopened.load()
        #expect(reopened.quantity == -2)
        let restarted = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        #expect(try source.quantity(for: first.id, in: restarted.modelContainer.mainContext) == 8)
        #expect(try source.quantity(for: second.id, in: restarted.modelContainer.mainContext) == 2)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(demo.runtime == nil)
    }
    #endif
}
