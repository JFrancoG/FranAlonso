import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service screen composition", .timeLimit(.minutes(1)))
@MainActor
struct ServiceScreenCompositionTests {
    @Test
    func `preview seeds coherent services once and preserves edits in the observed container`() async throws {
        let preview = try AppPreviewModifier.makeSharedContext()
        let context = ModelContext(preview.modelContainer)
        let source = ServiceLocalDataSource()
        let initial = try source.fetchAll(in: context)
        try #require(initial.count == 3)
        #expect(Set(initial.map(\.name)) == [
            "Corte y peinado con tratamiento de hidratación", "Champú profesional hidratante", "Coloración de temporada"
        ])
        let linked = try #require(initial.first { $0.type == .product })
        let productID = try #require(linked.linkedProductID)
        #expect(try ProductLocalDataSource().product(id: productID, in: context)?.status == .active)
        let model = preview.dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: linked.id, mode: .edit),
            Locale(identifier: "es_ES")
        )
        await model.load()
        model.draft.priceText = "22,50"
        await model.save(in: context)
        guard case .saved(let accepted) = model.state else {
            Issue.record("The preview service must save through the contextual factory")
            return
        }
        #expect(accepted.price.amount == Decimal(string: "22.50"))
        #expect(accepted.linkedProductID == productID)
        try ServicePreviewFixtures.standard.seed(in: context)
        try ServicePreviewFixtures.standard.seed(in: context)
        let persisted = try source.fetchAll(in: ModelContext(preview.modelContainer))
        #expect(persisted.count == 3)
        #expect(persisted.contains(accepted))
        var observation = await preview.dependencies.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == persisted)
    }

    @Test(arguments: [("es_ES", "12,50", "12.50"), ("en_US", "12.50", "12,50")])
    func `form factory uses the screen locale for exact input and subsequent load`(
        localeID: String,
        validPrice: String,
        invalidPrice: String
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        let id = ServiceID(rawValue: UUID())
        let locale = Locale(identifier: localeID)
        let creating = dependencies.makeServiceForm(.init(id: UUID(), serviceID: id, mode: .create), locale)
        creating.draft = ServiceFormDraft(name: "Localized offering", priceText: invalidPrice, taxText: "21")
        await creating.save(in: container.mainContext)
        #expect(creating.state == .failed(.save, .invalidPriceInput))
        #expect(try container.mainContext.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        creating.draft.priceText = validPrice
        await creating.save(in: container.mainContext)
        guard case .saved(let service) = creating.state else {
            Issue.record("Valid localized input must save")
            return
        }
        #expect(service.price.amount == Decimal(string: "12.50"))
        let editing = dependencies.makeServiceForm(.init(id: UUID(), serviceID: id, mode: .edit), locale)
        await editing.load()
        #expect(editing.draft.priceText == (localeID == "es_ES" ? "12,5" : "12.5"))
        #expect(!editing.hasUnsavedChanges)
    }

    #if FRANALONSO_AUTH_FIXTURE
    @Test
    func `demo services retain their product link through edits and reset after a fresh launch`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        let context = ModelContext(demo.modelContainer)
        let source = ServiceLocalDataSource()
        let initial = try source.fetchAll(in: context)
        try #require(initial.count == 2)
        #expect(Set(initial.map(\.name)) == ["Corte y peinado DEMO", "Champú DEMO venta"])
        let linked = try #require(initial.first { $0.type == .product })
        let linkedID = try #require(linked.linkedProductID)
        #expect(try ProductLocalDataSource().product(id: linkedID, in: context)?.name == "Champú DEMO hidratante")
        let editing = demo.dependencies.makeServiceForm(
            .init(id: UUID(), serviceID: linked.id, mode: .edit), Locale(identifier: "es_ES")
        )
        await editing.load()
        editing.draft.name = "Champú DEMO revisado"
        editing.draft.priceText = "25,75"
        await editing.save(in: context)
        try #require(editing.loadedService?.name == "Champú DEMO revisado")
        #expect(editing.loadedService?.linkedProductID == linkedID)
        let deactivating = demo.dependencies.makeServiceForm(
            .init(id: UUID(), serviceID: linked.id, mode: .edit), Locale(identifier: "es_ES")
        )
        await deactivating.load()
        deactivating.draft.priceText = "invalid"
        await deactivating.deactivate(in: context)
        #expect(deactivating.state == .deactivated)
        let persisted = try #require(try source.service(id: linked.id, in: ModelContext(demo.modelContainer)))
        #expect(persisted.status == .inactive)
        #expect(persisted.price.amount == Decimal(string: "25.75"))
        #expect(persisted.linkedProductID == linkedID)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(demo.runtime == nil)
        let restarted = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        #expect(try source.fetchAll(in: ModelContext(restarted.modelContainer)) == initial)
    }
    #endif
}
