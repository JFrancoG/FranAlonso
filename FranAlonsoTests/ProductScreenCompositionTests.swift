import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product screen composition")
@MainActor
struct ProductScreenCompositionTests {
    @Test
    func `interactive preview seeds products once and edits the observed container`() async throws {
        let preview = try AppPreviewModifier.makeSharedContext()
        let context = ModelContext(preview.modelContainer)
        let source = ProductLocalDataSource()
        let initial = try source.fetchAll(in: context)
        #expect(initial.map(\.name) == [
            "Champú profesional de hidratación y cuidado del cabello teñido", "Mascarilla nutritiva"
        ])
        let first = try #require(initial.first)
        let form = preview.dependencies.makeProductForm(.init(id: UUID(), productID: first.id, mode: .edit))
        await form.load()
        form.name = "Champú revisado"
        await form.save(in: context)
        let saved = try #require(form.loadedProduct)
        #expect(saved.name == "Champú revisado")
        try ProductPreviewFixtures.standard.seed(in: context)
        try ProductPreviewFixtures.standard.seed(in: context)
        let persisted = try source.fetchAll(in: ModelContext(preview.modelContainer))
        #expect(persisted.count == 2)
        #expect(persisted.contains(saved))
        let stream = await preview.dependencies.observeProducts()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == persisted)
    }

    #if FRANALONSO_AUTH_FIXTURE
    @Test
    func `demo catalogue edits deactivates and creates locally then resets on a new launch`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        let context = ModelContext(demo.modelContainer)
        let source = ProductLocalDataSource()
        let initial = try source.fetchAll(in: context)
        #expect(initial.map(\.name) == ["Champú DEMO hidratante", "Mascarilla DEMO nutritiva"])
        #expect(initial.allSatisfy { $0.status == .active })
        let product = try #require(initial.first)
        let edit = demo.dependencies.makeProductForm(.init(id: UUID(), productID: product.id, mode: .edit))
        await edit.load()
        edit.name = "Champú DEMO revisado"
        await edit.save(in: context)
        #expect(edit.loadedProduct?.name == "Champú DEMO revisado")
        let reopen = demo.dependencies.makeProductForm(.init(id: UUID(), productID: product.id, mode: .edit))
        await reopen.load()
        await reopen.deactivate(in: context)
        #expect(reopen.state == .deactivated)
        let newDestination = ProductFormDestination(id: UUID(), productID: ProductID(rawValue: UUID()), mode: .create)
        let create = demo.dependencies.makeProductForm(newDestination)
        create.name = "Producto DEMO creado"
        await create.save(in: context)
        #expect(create.loadedProduct?.name == "Producto DEMO creado")
        let products = try source.fetchAll(in: ModelContext(demo.modelContainer))
        #expect(products.count == 3)
        #expect(products.first { $0.id == product.id }?.status == .inactive)
        let stream = await demo.dependencies.observeProducts()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == products)
        let restarted = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        #expect(try source.fetchAll(in: ModelContext(restarted.modelContainer)) == initial)
        #expect(try context.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(demo.runtime == nil)
    }
    #endif
}
