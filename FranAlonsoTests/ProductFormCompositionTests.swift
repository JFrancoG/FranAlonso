import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product form contextual composition")
@MainActor
struct ProductFormCompositionTests {
    @Test
    func `forms share observation and the causal chain through create edit and deactivate`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ProductPersistenceActor(modelContainer: container)
        let signal = ProductObservationSignal()
        let repository = DefaultProductRepository(persistenceActor: actor, observationSignal: signal)
        var observation = await repository.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let factory = AppDependencies.productFormFactory(persistenceActor: actor, observationSignal: signal)
        let id = ProductID(rawValue: UUID())
        let creating = factory(ProductFormDestination(id: UUID(), productID: id, mode: .create))
        creating.name = "  Original  "
        await creating.save(in: container.mainContext)
        let original = Product(id: id, name: "Original", status: .active)
        try #require(creating.state == .saved(original))
        #expect(try await observation.next() == [original])

        let editing = factory(ProductFormDestination(id: UUID(), productID: id, mode: .edit))
        await editing.load()
        #expect(editing.name == "Original")
        editing.name = "Renamed"
        await editing.save(in: container.mainContext)
        let renamed = Product(id: id, name: "Renamed", status: .active)
        try #require(editing.state == .saved(renamed))
        #expect(try await observation.next() == [renamed])

        let deactivating = factory(ProductFormDestination(id: UUID(), productID: id, mode: .edit))
        await deactivating.load()
        await deactivating.deactivate(in: container.mainContext)
        try #require(deactivating.state == .deactivated)
        let inactive = Product(id: id, name: "Renamed", status: .inactive)
        #expect(try await observation.next() == [inactive])
        let operations = try await actor.pendingUpserts()
        try #require(operations.count == 3)
        #expect(operations.map(\.product.status) == [.active, .active, .inactive])
        #expect(operations.map(\.predecessorOperationID) == [nil, operations[0].operationID, operations[1].operationID])
        #expect(try await repository.product(id: id) == inactive)

        let inactiveEdit = factory(ProductFormDestination(id: UUID(), productID: id, mode: .edit))
        await inactiveEdit.load()
        #expect(!inactiveEdit.canDeactivate)
        inactiveEdit.name = "Inactive renamed"
        await inactiveEdit.save(in: container.mainContext)
        let updated = Product(id: id, name: "Inactive renamed", status: .inactive)
        try #require(inactiveEdit.state == .saved(updated))
        #expect(try await observation.next() == [updated])
        #expect(try await actor.pendingOperations().count == 4)
    }

    @Test
    func `interactive preview writes into the same container it observes`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        var observation = await dependencies.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let id = ProductID(rawValue: UUID())
        let model = dependencies.makeProductForm(ProductFormDestination(id: UUID(), productID: id, mode: .create))
        model.name = "Interactive fixture"
        await model.save(in: container.mainContext)
        let expected = Product(id: id, name: "Interactive fixture", status: .active)
        try #require(model.state == .saved(expected))
        #expect(try await observation.next() == [expected])
        let stored = try ModelContext(container).fetch(FetchDescriptor<ProductModel>())
        #expect(try stored.map { try $0.toDomain() } == [expected])
    }

    @Test
    func `snapshot preview permits reads and rejects every contextual mutation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let product = Product(id: ProductID(rawValue: UUID()), name: "Read only", status: .active)
        let dependencies = AppDependencies.preview(products: [product])
        let editing = dependencies.makeProductForm(
            ProductFormDestination(id: UUID(), productID: product.id, mode: .edit)
        )
        await editing.load()
        #expect(editing.name == "Read only")
        editing.name = "Rejected edit"
        await editing.save(in: container.mainContext)
        #expect(editing.state == .failed(.save, .persistenceUnavailable))
        await editing.deactivate(in: container.mainContext)
        #expect(editing.state == .failed(.deactivate, .persistenceUnavailable))
        let creating = dependencies.makeProductForm(
            ProductFormDestination(id: UUID(), productID: ProductID(rawValue: UUID()), mode: .create)
        )
        creating.name = "Rejected creation"
        await creating.save(in: container.mainContext)
        #expect(creating.state == .failed(.save, .persistenceUnavailable))
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
        var observation = await dependencies.observeProducts().makeAsyncIterator()
        #expect(try await observation.next() == [product])
    }
}
