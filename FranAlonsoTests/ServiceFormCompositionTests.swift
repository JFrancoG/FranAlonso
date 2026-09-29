import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service form contextual composition", .timeLimit(.minutes(1)))
@MainActor
struct ServiceFormCompositionTests {
    @Test
    func `forms share complete commercial profiles observation and the causal chain`() async throws {
        let fixture = try ServiceFormCompositionFixture()
        var observation = await fixture.repository.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let id = ServiceID(rawValue: UUID())
        let creating = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .create))
        creating.draft = ServiceFormDraft(name: "  Original  ", priceText: "10", taxText: "21")

        await creating.save(in: fixture.container.mainContext)

        let original = try makeService(
            id: id.rawValue,
            name: "Original",
            priceAmount: 10,
            discountPercentage: nil
        )
        try #require(creating.state == .saved(original))
        #expect(try await observation.next() == [original])

        let editing = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit))
        await editing.load()
        try #require(editing.state == .editing)
        editing.draft = ServiceFormDraft(
            name: "Renamed",
            priceText: "20",
            currency: .usd,
            taxText: "7",
            discountText: "0"
        )
        await editing.save(in: fixture.container.mainContext)
        let renamed = try makeService(
            id: id.rawValue,
            name: "Renamed",
            priceAmount: 20,
            currency: .usd,
            taxPercentage: 7,
            discountPercentage: 0
        )
        try #require(editing.state == .saved(renamed))
        #expect(try await observation.next() == [renamed])

        let deactivating = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit))
        await deactivating.load()
        await deactivating.deactivate(in: fixture.container.mainContext)
        try #require(deactivating.state == .deactivated)
        let inactive = try makeService(
            id: id.rawValue,
            name: "Renamed",
            priceAmount: 20,
            currency: .usd,
            taxPercentage: 7,
            discountPercentage: 0,
            status: .inactive
        )
        #expect(try await observation.next() == [inactive])

        let inactiveEdit = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit))
        await inactiveEdit.load()
        try #require(inactiveEdit.state == .editing)
        #expect(!inactiveEdit.canDeactivate)
        inactiveEdit.draft.discountText = "5"
        await inactiveEdit.save(in: fixture.container.mainContext)
        let updated = try makeService(
            id: id.rawValue,
            name: "Renamed",
            priceAmount: 20,
            currency: .usd,
            taxPercentage: 7,
            discountPercentage: 5,
            status: .inactive
        )
        try #require(inactiveEdit.state == .saved(updated))
        #expect(try await observation.next() == [updated])
        let operations = try await fixture.services.pendingUpserts()
        try #require(operations.count == 4)
        #expect(try operations.map { try $0.service.toDomain() } == [original, renamed, inactive, updated])
        #expect(operations.map(\.predecessorOperationID) == [
            nil, operations[0].operationID, operations[1].operationID, operations[2].operationID
        ])
        #expect(try await fixture.repository.service(id: id) == updated)
    }

    @Test
    func `factory rejects a product removed after loading and preserves draft and accepted queue`() async throws {
        let fixture = try ServiceFormCompositionFixture()
        let productID = ProductID(rawValue: UUID())
        try await fixture.products.upsert(Product(id: productID, name: "Available", status: .active))
        let original = try makeService(
            name: "Linked offering",
            type: .product,
            linkedProductID: productID.rawValue,
            priceAmount: 15
        )
        try await fixture.services.persistPendingUpsert(original, operationID: UUID())
        let acceptedQueue = try await fixture.services.pendingOperations()
        let model = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit))
        await model.load()
        try #require(model.state == .editing)
        model.draft.priceText = "19"
        let editedDraft = model.draft
        try await fixture.products.persistPendingDelete(productID, operationID: UUID())
        let productQueue = try await fixture.products.pendingOperations()

        await model.save(in: fixture.container.mainContext)

        #expect(model.state == .failed(.save, .service(.linkedProductUnavailable)))
        #expect(model.draft == editedDraft)
        #expect(model.hasUnsavedChanges)
        #expect(try await fixture.repository.service(id: original.id) == original)
        #expect(try await fixture.services.pendingOperations() == acceptedQueue)
        #expect(try await fixture.products.pendingOperations() == productQueue)
        #expect(!fixture.container.mainContext.hasChanges)
    }

    @Test
    func `historical missing product permits deactivation without accepting an invalid draft`() async throws {
        let fixture = try ServiceFormCompositionFixture()
        let productID = ProductID(rawValue: UUID())
        let original = try makeService(
            name: "Historical offering",
            type: .product,
            linkedProductID: productID.rawValue,
            priceAmount: 15,
            taxPercentage: 4,
            discountPercentage: 3
        )
        try await fixture.services.upsert(original)
        let model = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit))
        await model.load()
        try #require(model.state == .editing)
        #expect(model.canDeactivate)
        model.draft.name = ""
        model.draft.priceText = "invalid"
        model.draft.type = .professional

        await model.deactivate(in: fixture.container.mainContext)

        try #require(model.state == .deactivated)
        let expected = try makeService(
            name: "Historical offering",
            type: .product,
            linkedProductID: productID.rawValue,
            priceAmount: 15,
            taxPercentage: 4,
            discountPercentage: 3,
            status: .inactive
        )
        #expect(try await fixture.repository.service(id: original.id) == expected)
        let pending = try await fixture.services.pendingUpserts()
        try #require(pending.count == 1)
        #expect(try pending[0].service.toDomain() == expected)
        #expect(pending[0].predecessorOperationID == nil)
        #expect(try await fixture.products.fetchAll().isEmpty)
        #expect(try await fixture.products.pendingOperations().isEmpty)
    }

    @Test
    func `interactive preview writes the service into its observed container`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        var observation = await dependencies.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let id = ServiceID(rawValue: UUID())
        let model = dependencies.makeServiceForm(ServiceFormDestination(id: UUID(), serviceID: id, mode: .create))
        model.draft = ServiceFormDraft(name: "Interactive service", priceText: "35", taxText: "10")

        await model.save(in: container.mainContext)

        let expected = try makeService(
            id: id.rawValue,
            name: "Interactive service",
            priceAmount: 35,
            taxPercentage: 10,
            discountPercentage: nil
        )
        try #require(model.state == .saved(expected))
        #expect(try await observation.next() == [expected])
        let stored = try ModelContext(container).fetch(FetchDescriptor<ServiceModel>())
        #expect(try stored.map { try $0.toDomain() } == [expected])
        #expect(try await ServicePersistenceActor(modelContainer: container).pendingOperations().count == 1)
    }

    @Test
    func `snapshot preview reads services and rejects all mutations without saving caller changes`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let callerContext = ModelContext(container)
        callerContext.insert(ProductModel(id: UUID(), name: "Unrelated unsaved product", statusRawValue: "active"))
        let original = try makeService(name: "Read only", priceAmount: 10, discountPercentage: nil)
        let dependencies = AppDependencies.preview(services: [original])
        let editing = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit)
        )
        await editing.load()
        try #require(editing.state == .editing)
        editing.draft.name = "Rejected edit"

        await editing.save(in: callerContext)
        #expect(editing.state == .failed(.save, .service(.persistenceUnavailable)))
        await editing.deactivate(in: callerContext)
        #expect(editing.state == .failed(.deactivate, .service(.persistenceUnavailable)))
        let creating = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: .create)
        )
        creating.draft = ServiceFormDraft(name: "Rejected creation", priceText: "20", taxText: "21")
        await creating.save(in: callerContext)
        #expect(creating.state == .failed(.save, .service(.persistenceUnavailable)))

        #expect(callerContext.hasChanges)
        let persisted = ModelContext(container)
        #expect(try persisted.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        #expect(try persisted.fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try await ServicePersistenceActor(modelContainer: container).pendingOperations().isEmpty)
        var observation = await dependencies.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [original])
    }
}

@MainActor
private struct ServiceFormCompositionFixture {
    let container: ModelContainer
    let services: ServicePersistenceActor
    let products: ProductPersistenceActor
    let repository: DefaultServiceRepository
    let factory: AppDependencies.ServiceFormFactory
}

private extension ServiceFormCompositionFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let services = ServicePersistenceActor(modelContainer: container)
        let signal = ServiceObservationSignal()
        self.init(
            container: container,
            services: services,
            products: ProductPersistenceActor(modelContainer: container),
            repository: DefaultServiceRepository(persistenceActor: services, observationSignal: signal),
            factory: AppDependencies.serviceFormFactory(persistenceActor: services, observationSignal: signal)
        )
    }
}
