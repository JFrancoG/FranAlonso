import Foundation
import SwiftUI
import Testing
@testable import FranAlonso

@Suite("Application dependency composition")
struct AppDependenciesTests {
    @Test("Injected telemetry data sources compose the shared reporter")
    func injectedTelemetryDataSourcesComposeTheSharedReporter() async {
        let analytics = CompositionAnalyticsDataSourceSpy()
        let crash = CompositionCrashDataSourceSpy()
        let dependencies = AppDependencies(
            clientRepository: CompositionClientRepositoryFake(clients: []),
            productRepository: CompositionProductRepositoryFake(products: []),
            serviceRepository: CompositionServiceRepositoryFake(services: []),
            saleRepository: InMemorySaleRepository(),
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await dependencies.telemetryReporter.updateConsent(.denied)
        await dependencies.telemetryReporter.updateConsent(.granted)
        await dependencies.telemetryReporter.track(.appOpened)
        await dependencies.telemetryReporter.record(.controlledValidation)

        #expect(await analytics.collectionChanges() == [false, true])
        #expect(await analytics.loggedEvents() == [.appOpened])
        #expect(await crash.collectionChanges() == [false, true])
        #expect(await crash.recordedDiagnostics() == [.controlledValidation])
    }

    @Test("SwiftUI environment stores the injected dependency container")
    func swiftUIEnvironmentStoresTheInjectedDependencyContainer() {
        let dependencies = AppDependencies(
            clientRepository: CompositionClientRepositoryFake(clients: []),
            productRepository: CompositionProductRepositoryFake(products: []),
            serviceRepository: CompositionServiceRepositoryFake(services: []),
            saleRepository: InMemorySaleRepository(),
            analyticsDataSource: CompositionAnalyticsDataSourceSpy(),
            crashDataSource: CompositionCrashDataSourceSpy()
        )
        var environment = EnvironmentValues()

        environment.appDependencies = dependencies

        #expect(
            environment.appDependencies.telemetryReporter
                === dependencies.telemetryReporter
        )
    }

    @Test("SwiftUI environment uses one stable preview default")
    func swiftUIEnvironmentUsesOneStablePreviewDefault() {
        let firstEnvironment = EnvironmentValues()
        let secondEnvironment = EnvironmentValues()

        #expect(
            firstEnvironment.appDependencies.telemetryReporter
                === secondEnvironment.appDependencies.telemetryReporter
        )
    }

    @Test("SwiftUI environment resolves clients through the injected repository")
    func swiftUIEnvironmentResolvesClientsThroughTheInjectedRepository() async throws {
        let expectedClients = [
            Client.draft(
                id: ClientID(
                    rawValue: UUID(
                        uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                    )!
                ),
                displayName: "Ana Alonso"
            )
        ]
        let repository = CompositionClientRepositoryFake(clients: expectedClients)
        let dependencies = AppDependencies(
            clientRepository: repository,
            productRepository: CompositionProductRepositoryFake(products: []),
            serviceRepository: CompositionServiceRepositoryFake(services: []),
            saleRepository: InMemorySaleRepository(),
            analyticsDataSource: CompositionAnalyticsDataSourceSpy(),
            crashDataSource: CompositionCrashDataSourceSpy()
        )
        var environment = EnvironmentValues()

        environment.appDependencies = dependencies
        let stream = await environment.appDependencies.observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedClients)
        #expect(await repository.observationCallCount() == 1)
    }

    @Test("Preview dependencies expose their seeded clients")
    func previewDependenciesExposeTheirSeededClients() async throws {
        let expectedClients = [
            Client.draft(
                id: ClientID(
                    rawValue: UUID(
                        uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                    )!
                ),
                displayName: "Ana Alonso"
            )
        ]
        let dependencies = AppDependencies.preview(clients: expectedClients)

        let stream = await dependencies.observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedClients)
        #expect(try await iterator.next() == nil)
    }

    @Test("Application dependencies resolve Products through the injected repository")
    func dependenciesResolveProductsThroughTheInjectedRepository() async throws {
        let expectedProducts = [compositionProduct()]
        let repository = CompositionProductRepositoryFake(
            products: expectedProducts
        )
        let dependencies = AppDependencies(
            clientRepository: CompositionClientRepositoryFake(clients: []),
            productRepository: repository,
            serviceRepository: CompositionServiceRepositoryFake(services: []),
            saleRepository: InMemorySaleRepository(),
            analyticsDataSource: CompositionAnalyticsDataSourceSpy(),
            crashDataSource: CompositionCrashDataSourceSpy()
        )

        let stream = await dependencies.observeProducts()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedProducts)
        #expect(await repository.observationCallCount() == 1)
    }

    @Test("Preview dependencies expose their seeded Products")
    func previewDependenciesExposeTheirSeededProducts() async throws {
        let expectedProducts = [compositionProduct()]
        let dependencies = AppDependencies.preview(products: expectedProducts)

        let stream = await dependencies.observeProducts()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedProducts)
        #expect(try await iterator.next() == nil)
    }

    @Test("Application dependencies resolve Services through the injected repository")
    func dependenciesResolveServicesThroughTheInjectedRepository() async throws {
        let expectedServices = [try compositionService()]
        let repository = CompositionServiceRepositoryFake(
            services: expectedServices
        )
        let dependencies = AppDependencies(
            clientRepository: CompositionClientRepositoryFake(clients: []),
            productRepository: CompositionProductRepositoryFake(products: []),
            serviceRepository: repository,
            saleRepository: InMemorySaleRepository(),
            analyticsDataSource: CompositionAnalyticsDataSourceSpy(),
            crashDataSource: CompositionCrashDataSourceSpy()
        )

        let stream = await dependencies.observeServices()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedServices)
        #expect(await repository.observationCallCount() == 1)
    }

    @Test("Preview dependencies expose their seeded Services")
    func previewDependenciesExposeTheirSeededServices() async throws {
        let expectedServices = [try compositionService()]
        let dependencies = AppDependencies.preview(services: expectedServices)

        let stream = await dependencies.observeServices()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedServices)
        #expect(try await iterator.next() == nil)
    }

    @Test("Application and preview dependencies expose their seeded Sales")
    func dependenciesExposeSeededSales() async throws {
        let expectedSales = [try compositionSale()]
        let repository = CompositionSaleRepositoryFake(sales: expectedSales)
        let dependencies = AppDependencies(
            clientRepository: CompositionClientRepositoryFake(clients: []),
            productRepository: CompositionProductRepositoryFake(products: []),
            serviceRepository: CompositionServiceRepositoryFake(services: []),
            saleRepository: repository,
            analyticsDataSource: CompositionAnalyticsDataSourceSpy(),
            crashDataSource: CompositionCrashDataSourceSpy()
        )

        let stream = await dependencies.observeSales()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == expectedSales)
        try await dependencies.saveSale(expectedSales[0])
        #expect(await repository.saveCallCount() == 1)

        let preview = AppDependencies.preview(sales: expectedSales)
        let previewStream = await preview.observeSales()
        var previewIterator = previewStream.makeAsyncIterator()
        #expect(try await previewIterator.next() == expectedSales)
    }
}

private actor CompositionClientRepositoryFake: ClientRepository {
    private var clients: [Client]
    private var callCount = 0

    init(clients: [Client]) {
        self.clients = clients
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        callCount += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(clients)
            continuation.finish()
        }
    }

    func saveClient(_ client: Client) async throws {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
    }

    func observationCallCount() -> Int {
        callCount
    }
}

private actor CompositionProductRepositoryFake: ProductRepository {
    private var products: [Product]
    private var callCount = 0

    init(products: [Product]) {
        self.products = products
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        callCount += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(products)
            continuation.finish()
        }
    }

    func saveProduct(_ product: Product) async throws {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        } else {
            products.append(product)
        }
    }

    func observationCallCount() -> Int {
        callCount
    }
}

private actor CompositionServiceRepositoryFake: ServiceRepository {
    private var services: [Service]
    private var callCount = 0

    init(services: [Service]) {
        self.services = services
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        callCount += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(services)
            continuation.finish()
        }
    }

    func saveService(_ service: Service) async throws {
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
    }

    func observationCallCount() -> Int {
        callCount
    }
}

private actor CompositionSaleRepositoryFake: SaleRepository {
    private var sales: [Sale]
    private var saves = 0

    init(sales: [Sale]) {
        self.sales = sales
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(sales)
            continuation.finish()
        }
    }

    func saveSale(_ sale: Sale) async throws {
        saves += 1
        if let index = sales.firstIndex(where: { $0.id == sale.id }) {
            sales[index] = sale
        } else {
            sales.append(sale)
        }
    }

    func saveCallCount() -> Int { saves }
}

private func compositionProduct() -> Product {
    Product.testSnapshot(
        id: ProductID(
            rawValue: UUID(
                uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF"
            )!
        ),
        name: "Champú"
    )
}

private func compositionService() throws -> Service {
    try makeService(
        id: UUID(
            uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-AAAAAAAAAAAA"
        )!,
        name: "Corte y peinado",
        discountPercentage: nil
    )
}

private func compositionSale() throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(
            rawValue: UUID(uuidString: "DDDDDDDD-EEEE-FFFF-AAAA-BBBBBBBBBBBB")!
        ),
        serviceID: ServiceID(
            rawValue: UUID(uuidString: "EEEEEEEE-FFFF-AAAA-BBBB-CCCCCCCCCCCC")!
        ),
        serviceName: "Snapshot",
        quantity: 1,
        unitPrice: Money(amount: 10, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
    return try Sale.draft(
        id: SaleID(
            rawValue: UUID(uuidString: "FFFFFFFF-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!
        ),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 1),
        lines: [line]
    )
}

private actor CompositionAnalyticsDataSourceSpy: AnalyticsDataSource {
    private var collectionValues: [Bool] = []
    private var events: [AnalyticsEvent] = []

    func setCollectionEnabled(_ isEnabled: Bool) {
        collectionValues.append(isEnabled)
    }

    func log(_ event: AnalyticsEvent) {
        events.append(event)
    }

    func collectionChanges() -> [Bool] {
        collectionValues
    }

    func loggedEvents() -> [AnalyticsEvent] {
        events
    }
}

private actor CompositionCrashDataSourceSpy: CrashDataSource {
    private var collectionValues: [Bool] = []
    private var diagnostics: [CrashDiagnostic] = []

    func setCollectionEnabled(_ isEnabled: Bool) {
        collectionValues.append(isEnabled)
    }

    func record(_ diagnostic: CrashDiagnostic) {
        diagnostics.append(diagnostic)
    }

    func collectionChanges() -> [Bool] {
        collectionValues
    }

    func recordedDiagnostics() -> [CrashDiagnostic] {
        diagnostics
    }
}
