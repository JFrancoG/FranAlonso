import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Stock observation composition", .timeLimit(.minutes(1)))
@MainActor
struct StockObservationCompositionTests {
    @Test
    func `runtime shares stock observation with contextual form acceptance`() async throws {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let runtime = AppRuntime(modelContainer: container, environment: .develop)
        let stream = await runtime.stockRepository.observeQuantity(for: product.id)
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == 0)
        let form = runtime.dependencies.makeStockAdjustment(.init(id: UUID(), productID: product.id))
        await form.load()
        form.unitsText = "5"
        form.reason = "Recuento"
        await form.save(in: container.mainContext)
        #expect(form.isAccepted)
        #expect(try await observation.next() == 5)
        let consuming = Task {
            for try await _ in stream {}
        }
        consuming.cancel()
        _ = await consuming.result
    }

    @Test(arguments: [false, true])
    func `live and preview stock commits invalidate catalogue while preserving the parent draft`(
        preview: Bool
    ) async throws {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let dependencies = preview ? AppDependencies.preview(modelContainer: container)
            : AppDependencies.live(modelContainer: container)
        try await verifyCatalogueInvalidation(dependencies, container: container, product: product)
    }

    #if FRANALONSO_AUTH_FIXTURE
    @Test
    func `demo stock commits invalidate the same catalogue composition`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        let product = try #require(ProductLocalDataSource().fetchAll(in: demo.modelContainer.mainContext).first)
        try await verifyCatalogueInvalidation(demo.dependencies, container: demo.modelContainer, product: product)
    }
    #endif
}

@MainActor
private func verifyCatalogueInvalidation(
    _ dependencies: AppDependencies,
    container: ModelContainer,
    product: Product
) async throws {
    let parent = dependencies.makeProductForm(.init(id: UUID(), productID: product.id, mode: .edit))
    await parent.load()
    parent.name = "Unsaved parent draft"
    parent.openStockAdjustment()
    let destination = try #require(parent.stockAdjustmentDestination)
    let catalogue = await dependencies.observeProducts()
    var products = catalogue.makeAsyncIterator()
    let initial = try #require(try await products.next())
    let form = dependencies.makeStockAdjustment(destination)
    await form.load()
    form.unitsText = "3"
    form.reason = "Recuento"
    await form.save(in: container.mainContext)
    #expect(form.isAccepted)
    #expect(try await products.next() == initial)
    parent.dismissStockAdjustment(id: destination.id)
    #expect(parent.name == "Unsaved parent draft")
    #expect(parent.loadedProduct == product)
    #expect(parent.stockAdjustmentDestination == nil)
    let consuming = Task {
        for try await _ in catalogue {}
    }
    consuming.cancel()
    _ = await consuming.result
}
