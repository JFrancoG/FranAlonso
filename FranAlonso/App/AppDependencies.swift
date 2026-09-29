import SwiftData

struct AppDependencies {
    typealias ClientFormFactory = @MainActor @Sendable (ClientFormDestination) -> ClientFormViewModel
    typealias ProductFormFactory = @MainActor @Sendable (ProductFormDestination) -> ProductFormViewModel
    typealias ClientConsentServicesFactory = @MainActor @Sendable () throws -> ClientConsentServices

    let observeClients: ObserveClientsUseCase
    let makeClientForm: ClientFormFactory
    let observeProducts: ObserveProductsUseCase
    let makeProductForm: ProductFormFactory
    let observeServices: ObserveServicesUseCase
    let observeSales: ObserveSalesUseCase
    let saveSale: SaveSaleUseCase
    let telemetryReporter: TelemetryReporter

    /// Creates production dependencies over the supplied local source of truth.
    ///
    /// The Clients, Products, Services and Sales repositories remain local-first and share their
    /// persistence and observation roles with the application runtime.
    ///
    /// - Parameter modelContainer: The application container shared with SwiftUI.
    /// - Returns: Dependencies backed by durable local persistence and live telemetry.
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let observationSignal = ClientObservationSignal()
        let productObservationSignal = ProductObservationSignal()
        let serviceObservationSignal = ServiceObservationSignal()
        let saleObservationSignal = SaleObservationSignal()
        return .live(
            persistenceActor: ClientPersistenceActor(modelContainer: modelContainer),
            observationSignal: observationSignal,
            productPersistenceActor: ProductPersistenceActor(modelContainer: modelContainer),
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: ServicePersistenceActor(modelContainer: modelContainer),
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: SalePersistenceActor(modelContainer: modelContainer),
            saleObservationSignal: saleObservationSignal
        )
    }

#if FRANALONSO_AUTH_FIXTURE
    /// Creates isolated local-first dependencies with explicitly supplied telemetry boundaries.
    @MainActor
    static func local(
        modelContainer: ModelContainer,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource,
        clientRepository: (any ClientRepository)? = nil,
        authenticationRoot: AuthenticationRootViewModel? = nil,
        clientDocumentStorage: (any ClientDocumentStorage)? = nil
    ) -> AppDependencies {
        let observationSignal = ClientObservationSignal()
        let productObservationSignal = ProductObservationSignal()
        let serviceObservationSignal = ServiceObservationSignal()
        let saleObservationSignal = SaleObservationSignal()
        let makeClientConsentServices: ClientConsentServicesFactory?
        if let authenticationRoot {
            let composition = ClientDocumentComposition(
                modelContainer: modelContainer,
                observationSignal: observationSignal,
                storage: clientDocumentStorage
            )
            composition.authenticationRoot = authenticationRoot
            makeClientConsentServices = { try composition.makeServices() }
        } else {
            makeClientConsentServices = nil
        }
        return .fixtureComposed(
            persistenceActor: ClientPersistenceActor(modelContainer: modelContainer),
            observationSignal: observationSignal,
            productPersistenceActor: ProductPersistenceActor(modelContainer: modelContainer),
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: ServicePersistenceActor(modelContainer: modelContainer),
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: SalePersistenceActor(modelContainer: modelContainer),
            saleObservationSignal: saleObservationSignal,
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource,
            clientRepository: clientRepository,
            makeClientConsentServices: makeClientConsentServices
        )
    }
#endif

    /// Creates production dependencies over runtime-owned local-first roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The single actor that owns durable Clients state.
    ///   - observationSignal: The invalidation shared by local writes and sync reconciliation.
    ///   - productPersistenceActor: The single actor that owns durable Products state.
    ///   - productObservationSignal: The Products invalidation shared by local writes and sync.
    ///   - servicePersistenceActor: The single actor that owns durable Services state.
    ///   - serviceObservationSignal: The Services invalidation shared by local writes and sync.
    ///   - salePersistenceActor: The single actor that owns durable Sales state.
    ///   - saleObservationSignal: The Sales invalidation shared by local writes and sync.
    static func live(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal,
        productPersistenceActor: ProductPersistenceActor,
        productObservationSignal: ProductObservationSignal,
        servicePersistenceActor: ServicePersistenceActor,
        serviceObservationSignal: ServiceObservationSignal,
        salePersistenceActor: SalePersistenceActor,
        saleObservationSignal: SaleObservationSignal,
        makeClientConsentServices: ClientConsentServicesFactory? = nil
    ) -> AppDependencies {
        .composed(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            productPersistenceActor: productPersistenceActor,
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: servicePersistenceActor,
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: salePersistenceActor,
            saleObservationSignal: saleObservationSignal,
            analyticsDataSource: FirebaseAnalyticsDataSource(),
            crashDataSource: FirebaseCrashDataSource(),
            makeClientConsentServices: makeClientConsentServices
        )
    }

    private static func composed(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal,
        productPersistenceActor: ProductPersistenceActor,
        productObservationSignal: ProductObservationSignal,
        servicePersistenceActor: ServicePersistenceActor,
        serviceObservationSignal: ServiceObservationSignal,
        salePersistenceActor: SalePersistenceActor,
        saleObservationSignal: SaleObservationSignal,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource,
        makeClientConsentServices: ClientConsentServicesFactory? = nil
    ) -> AppDependencies {
        let clientRepository = DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let productRepository = DefaultProductRepository(
            persistenceActor: productPersistenceActor,
            observationSignal: productObservationSignal
        )
        let serviceRepository = DefaultServiceRepository(
            persistenceActor: servicePersistenceActor,
            observationSignal: serviceObservationSignal
        )
        let saleRepository = DefaultSaleRepository(
            persistenceActor: salePersistenceActor,
            observationSignal: saleObservationSignal
        )

        return AppDependencies(
            clientRepository: clientRepository,
            makeClientForm: clientFormFactory(
                persistenceActor: persistenceActor,
                observationSignal: observationSignal,
                makeClientConsentServices: makeClientConsentServices
            ),
            productRepository: productRepository,
            makeProductForm: productFormFactory(
                persistenceActor: productPersistenceActor,
                observationSignal: productObservationSignal
            ),
            serviceRepository: serviceRepository,
            saleRepository: saleRepository,
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource
        )
    }

#if FRANALONSO_AUTH_FIXTURE
    private static func fixtureComposed(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal,
        productPersistenceActor: ProductPersistenceActor,
        productObservationSignal: ProductObservationSignal,
        servicePersistenceActor: ServicePersistenceActor,
        serviceObservationSignal: ServiceObservationSignal,
        salePersistenceActor: SalePersistenceActor,
        saleObservationSignal: SaleObservationSignal,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource,
        clientRepository injectedClientRepository: (any ClientRepository)?,
        makeClientConsentServices: ClientConsentServicesFactory?
    ) -> AppDependencies {
        let clientRepository = injectedClientRepository ?? DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let productRepository = DefaultProductRepository(
            persistenceActor: productPersistenceActor,
            observationSignal: productObservationSignal
        )
        let serviceRepository = DefaultServiceRepository(
            persistenceActor: servicePersistenceActor,
            observationSignal: serviceObservationSignal
        )
        let saleRepository = DefaultSaleRepository(
            persistenceActor: salePersistenceActor,
            observationSignal: saleObservationSignal
        )

        return AppDependencies(
            clientRepository: clientRepository,
            makeClientForm: injectedClientRepository.map { readOnlyClientFormFactory(repository: $0) }
                ?? clientFormFactory(
                    persistenceActor: persistenceActor,
                    observationSignal: observationSignal,
                    makeClientConsentServices: makeClientConsentServices
                ),
            productRepository: productRepository,
            makeProductForm: productFormFactory(
                persistenceActor: productPersistenceActor,
                observationSignal: productObservationSignal
            ),
            serviceRepository: serviceRepository,
            saleRepository: saleRepository,
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource
        )
    }
#endif

    /// Creates an interactive preview over the same in-memory container supplied to SwiftUI.
    /// Clients and Products reads, observation and contextual mutations share their existing actor and signal.
    /// Telemetry is inert; no remote data source or synchronization engine is composed.
    static func preview(modelContainer: ModelContainer) -> AppDependencies {
        .composed(
            persistenceActor: ClientPersistenceActor(modelContainer: modelContainer),
            observationSignal: ClientObservationSignal(),
            productPersistenceActor: ProductPersistenceActor(modelContainer: modelContainer),
            productObservationSignal: ProductObservationSignal(),
            servicePersistenceActor: ServicePersistenceActor(modelContainer: modelContainer),
            serviceObservationSignal: ServiceObservationSignal(),
            salePersistenceActor: SalePersistenceActor(modelContainer: modelContainer),
            saleObservationSignal: SaleObservationSignal(),
            analyticsDataSource: PreviewAnalyticsDataSource(),
            crashDataSource: PreviewCrashDataSource()
        )
    }

    /// Creates finite snapshot dependencies; Clients and Products form mutations are explicitly unavailable.
    /// Use `preview(modelContainer:)` when a preview needs interactive local persistence.
    static func preview(
        clients: [Client] = [],
        products: [Product] = [],
        services: [Service] = [],
        sales: [Sale] = []
    ) -> AppDependencies {
        let clientRepository = InMemoryClientRepository(clients: clients)
        let productRepository = InMemoryProductRepository(products: products)
        return AppDependencies(
            clientRepository: clientRepository,
            makeClientForm: readOnlyClientFormFactory(repository: clientRepository),
            productRepository: productRepository,
            makeProductForm: readOnlyProductFormFactory(repository: productRepository),
            serviceRepository: InMemoryServiceRepository(services: services),
            saleRepository: InMemorySaleRepository(sales: sales),
            analyticsDataSource: PreviewAnalyticsDataSource(),
            crashDataSource: PreviewCrashDataSource()
        )
    }
}

extension AppDependencies {
    init(
        clientRepository: any ClientRepository,
        makeClientForm: @escaping ClientFormFactory,
        productRepository: any ProductRepository,
        makeProductForm: @escaping ProductFormFactory,
        serviceRepository: any ServiceRepository,
        saleRepository: any SaleRepository,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        self.init(
            observeClients: ObserveClientsUseCase(repository: clientRepository),
            makeClientForm: makeClientForm,
            observeProducts: ObserveProductsUseCase(repository: productRepository),
            makeProductForm: makeProductForm,
            observeServices: ObserveServicesUseCase(repository: serviceRepository),
            observeSales: ObserveSalesUseCase(repository: saleRepository),
            saveSale: SaveSaleUseCase(repository: saleRepository),
            telemetryReporter: TelemetryReporter(
                analyticsDataSource: analyticsDataSource,
                crashDataSource: crashDataSource
            )
        )
    }
}

private struct PreviewAnalyticsDataSource: AnalyticsDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func log(_ event: AnalyticsEvent) {}
}

private struct PreviewCrashDataSource: CrashDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func record(_ diagnostic: CrashDiagnostic) {}
}
