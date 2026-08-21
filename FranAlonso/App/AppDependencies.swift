import SwiftData

struct AppDependencies {
    let observeClients: ObserveClientsUseCase
    let observeProducts: ObserveProductsUseCase
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
            persistenceActor: ClientPersistenceActor(
                modelContainer: modelContainer
            ),
            observationSignal: observationSignal,
            productPersistenceActor: ProductPersistenceActor(
                modelContainer: modelContainer
            ),
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: ServicePersistenceActor(
                modelContainer: modelContainer
            ),
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: SalePersistenceActor(
                modelContainer: modelContainer
            ),
            saleObservationSignal: saleObservationSignal
        )
    }

#if FRANALONSO_AUTH_FIXTURE
    /// Creates isolated local-first dependencies with explicitly supplied telemetry boundaries.
    static func local(
        modelContainer: ModelContainer,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) -> AppDependencies {
        let observationSignal = ClientObservationSignal()
        let productObservationSignal = ProductObservationSignal()
        let serviceObservationSignal = ServiceObservationSignal()
        let saleObservationSignal = SaleObservationSignal()
        return .composed(
            persistenceActor: ClientPersistenceActor(
                modelContainer: modelContainer
            ),
            observationSignal: observationSignal,
            productPersistenceActor: ProductPersistenceActor(
                modelContainer: modelContainer
            ),
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: ServicePersistenceActor(
                modelContainer: modelContainer
            ),
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: SalePersistenceActor(
                modelContainer: modelContainer
            ),
            saleObservationSignal: saleObservationSignal,
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource
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
        saleObservationSignal: SaleObservationSignal
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
            crashDataSource: FirebaseCrashDataSource()
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
        crashDataSource: any CrashDataSource
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
            productRepository: productRepository,
            serviceRepository: serviceRepository,
            saleRepository: saleRepository,
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource
        )
    }

    static func preview(
        clients: [Client] = [],
        products: [Product] = [],
        services: [Service] = [],
        sales: [Sale] = []
    ) -> AppDependencies {
        AppDependencies(
            clientRepository: InMemoryClientRepository(clients: clients),
            productRepository: InMemoryProductRepository(products: products),
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
        productRepository: any ProductRepository,
        serviceRepository: any ServiceRepository,
        saleRepository: any SaleRepository,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        self.init(
            observeClients: ObserveClientsUseCase(repository: clientRepository),
            observeProducts: ObserveProductsUseCase(repository: productRepository),
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
