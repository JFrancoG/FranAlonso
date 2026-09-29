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
        let creating = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .create), .current)
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

        let editing = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit), .current)
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

        let deactivating = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit), .current)
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

        let inactiveEdit = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit), .current)
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
        let model = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit), .current)
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
        let model = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit), .current)
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
        let model = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: id, mode: .create), .current
        )
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
    func `selector creates and replaces product links through contextual acceptance without editing inventory`() async throws {
        let fixture = try ServiceFormCompositionFixture()
        let first = Product(id: ProductID(rawValue: UUID()), name: "First", status: .active)
        let second = Product(id: ProductID(rawValue: UUID()), name: "Second", status: .active)
        try await fixture.products.upsert(first)
        try await fixture.products.upsert(second)
        let id = ServiceID(rawValue: UUID())
        let creating = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .create), .current)
        creating.draft = ServiceFormDraft(name: "Chosen offering", priceText: "25", taxText: "4", discountText: "2")
        await creating.observeProducts()
        creating.changeType(.product)
        creating.selectLinkedProduct(first.id)
        await creating.save(in: fixture.container.mainContext)
        let original = try makeService(
            id: id.rawValue,
            name: "Chosen offering",
            type: .product,
            linkedProductID: first.id.rawValue,
            priceAmount: 25,
            taxPercentage: 4,
            discountPercentage: 2
        )
        try #require(creating.state == .saved(original))
        #expect(try await fixture.repository.service(id: id) == original)

        let editing = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .edit), .current)
        await editing.load()
        await editing.observeProducts()
        editing.selectLinkedProduct(second.id)
        await editing.save(in: fixture.container.mainContext)
        let replacement = try makeService(
            id: id.rawValue,
            name: "Chosen offering",
            type: .product,
            linkedProductID: second.id.rawValue,
            priceAmount: 25,
            taxPercentage: 4,
            discountPercentage: 2
        )
        #expect(editing.state == .saved(replacement))
        #expect(try await fixture.repository.service(id: id) == replacement)
        let operations = try await fixture.services.pendingUpserts()
        try #require(operations.count == 2)
        #expect(try operations.map { try $0.service.toDomain() } == [original, replacement])
        #expect(operations[1].predecessorOperationID == operations[0].operationID)
        #expect(try await fixture.products.pendingOperations().isEmpty)
        #expect(try await fixture.products.fetchAll().contains(first))
        #expect(try await fixture.products.fetchAll().contains(second))
    }

    @Test(arguments: [ServiceType.professional, .product])
    func `deactivation between choosing and saving has no effects and permits explicit recovery`(
        _ recoveryType: ServiceType
    ) async throws {
        let fixture = try ServiceFormCompositionFixture()
        let first = Product(id: ProductID(rawValue: UUID()), name: "Initially available", status: .active)
        let other = Product(id: ProductID(rawValue: UUID()), name: "Recovery choice", status: .active)
        try await fixture.products.upsert(first)
        try await fixture.products.upsert(other)
        let id = ServiceID(rawValue: UUID())
        let model = fixture.factory(ServiceFormDestination(id: UUID(), serviceID: id, mode: .create), .current)
        model.draft = ServiceFormDraft(name: "Recoverable offering", priceText: "40", taxText: "10")
        await model.observeProducts()
        model.changeType(.product)
        model.selectLinkedProduct(first.id)
        let chosenDraft = model.draft
        let unavailable = Product(id: first.id, name: first.name, status: .inactive)
        try await fixture.products.persistPendingUpsert(unavailable, operationID: UUID())
        let productQueue = try await fixture.products.pendingOperations()

        await model.save(in: fixture.container.mainContext)

        try #require(model.state == .failed(.save, .service(.linkedProductUnavailable)))
        #expect(model.draft == chosenDraft)
        #expect(try await fixture.repository.service(id: id) == nil)
        #expect(try await fixture.services.pendingOperations().isEmpty)
        #expect(try await fixture.products.pendingOperations() == productQueue)
        #expect(!fixture.container.mainContext.hasChanges)
        await model.observeProducts()
        #expect(model.linkableProductsState == .loaded([other]))
        #expect(model.draft == chosenDraft)
        #expect(model.state == .failed(.save, .service(.linkedProductUnavailable)))
        model.changeType(recoveryType)
        if recoveryType == .product {
            model.selectLinkedProduct(other.id)
        }
        await model.save(in: fixture.container.mainContext)
        let expected = try makeService(
            id: id.rawValue,
            name: "Recoverable offering",
            type: recoveryType,
            linkedProductID: recoveryType == .product ? other.id.rawValue : nil,
            priceAmount: 40,
            taxPercentage: 10,
            discountPercentage: nil
        )
        #expect(model.state == .saved(expected))
        #expect(try await fixture.repository.service(id: id) == expected)
        let accepted = try await fixture.services.pendingUpserts()
        try #require(accepted.count == 1)
        #expect(try accepted[0].service.toDomain() == expected)
        #expect(try await fixture.products.pendingOperations() == productQueue)
        #expect(try await fixture.products.fetchAll().contains(unavailable))
    }

    @Test
    func `snapshot application composition shares product choices with service forms`() async throws {
        let active = Product(id: ProductID(rawValue: UUID()), name: "Available", status: .active)
        let inactive = Product(id: ProductID(rawValue: UUID()), name: "Unavailable", status: .inactive)
        let dependencies = AppDependencies.preview(products: [inactive, active])
        let model = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: .create),
            .current
        )
        await model.observeProducts()
        #expect(model.linkableProductsState == .loaded([active]))
        model.changeType(.product)
        model.selectLinkedProduct(active.id)
        #expect(model.draft.linkedProductID == active.id)
        model.selectLinkedProduct(inactive.id)
        #expect(model.draft.linkedProductID == active.id)
    }

    @Test
    func `snapshot preview reads services and rejects all mutations without saving caller changes`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let callerContext = ModelContext(container)
        callerContext.insert(ProductModel(id: UUID(), name: "Unrelated unsaved product", statusRawValue: "active"))
        let original = try makeService(name: "Read only", priceAmount: 10, discountPercentage: nil)
        let dependencies = AppDependencies.preview(services: [original])
        let editing = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: original.id, mode: .edit),
            .current
        )
        await editing.load()
        try #require(editing.state == .editing)
        editing.draft.name = "Rejected edit"

        await editing.save(in: callerContext)
        #expect(editing.state == .failed(.save, .service(.persistenceUnavailable)))
        await editing.deactivate(in: callerContext)
        #expect(editing.state == .failed(.deactivate, .service(.persistenceUnavailable)))
        let creating = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: .create),
            .current
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
        let products = ProductPersistenceActor(modelContainer: container)
        self.init(
            container: container,
            services: services,
            products: products,
            repository: DefaultServiceRepository(persistenceActor: services, observationSignal: signal),
            factory: AppDependencies.serviceFormFactory(
                persistenceActor: services,
                observationSignal: signal,
                productRepository: ServiceFormFiniteProductRepository(
                    base: DefaultProductRepository(
                        persistenceActor: products,
                        observationSignal: ProductObservationSignal()
                    )
                )
            )
        )
    }
}

private struct ServiceFormFiniteProductRepository: ProductRepository {
    let base: DefaultProductRepository

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        var iterator = await base.observeProducts().makeAsyncIterator()
        do {
            let snapshot = try await iterator.next()
            return AsyncThrowingStream {
                if let snapshot {
                    $0.yield(snapshot)
                }
                $0.finish()
            }
        } catch {
            return AsyncThrowingStream {
                $0.finish(throwing: error)
            }
        }
    }

    func product(id: ProductID) async throws -> Product? {
        try await base.product(id: id)
    }
    func saveProduct(_ product: Product) async throws {
        try await base.saveProduct(product)
    }
    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        try await base.createProduct(id: id, profile: profile)
    }
    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        try await base.updateProduct(id: id, profile: profile)
    }
    func deactivateProduct(_ id: ProductID) async throws {
        try await base.deactivateProduct(id)
    }
}
