import SwiftData

struct AppDependencies {
    let observeClients: ObserveClientsUseCase
    let observeProducts: ObserveProductsUseCase
    let telemetryReporter: TelemetryReporter

    /// Creates production dependencies over the supplied local source of truth.
    ///
    /// The Clients and Products repositories remain local-first and share their persistence
    /// and observation roles with the application runtime.
    ///
    /// - Parameter modelContainer: The application container shared with SwiftUI.
    /// - Returns: Dependencies backed by durable local persistence and live telemetry.
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let observationSignal = ClientObservationSignal()
        let productObservationSignal = ProductObservationSignal()
        return .live(
            persistenceActor: ClientPersistenceActor(
                modelContainer: modelContainer
            ),
            observationSignal: observationSignal,
            productPersistenceActor: ProductPersistenceActor(
                modelContainer: modelContainer
            ),
            productObservationSignal: productObservationSignal
        )
    }

    /// Creates production dependencies over runtime-owned local-first roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The single actor that owns durable Clients state.
    ///   - observationSignal: The invalidation shared by local writes and sync reconciliation.
    ///   - productPersistenceActor: The single actor that owns durable Products state.
    ///   - productObservationSignal: The Products invalidation shared by local writes and sync.
    static func live(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal,
        productPersistenceActor: ProductPersistenceActor,
        productObservationSignal: ProductObservationSignal
    ) -> AppDependencies {
        let clientRepository = DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let productRepository = DefaultProductRepository(
            persistenceActor: productPersistenceActor,
            observationSignal: productObservationSignal
        )

        return AppDependencies(
            clientRepository: clientRepository,
            productRepository: productRepository,
            analyticsDataSource: FirebaseAnalyticsDataSource(),
            crashDataSource: FirebaseCrashDataSource()
        )
    }

    static func preview(
        clients: [Client] = [],
        products: [Product] = []
    ) -> AppDependencies {
        AppDependencies(
            clientRepository: InMemoryClientRepository(clients: clients),
            productRepository: InMemoryProductRepository(products: products),
            analyticsDataSource: PreviewAnalyticsDataSource(),
            crashDataSource: PreviewCrashDataSource()
        )
    }
}

extension AppDependencies {
    init(
        clientRepository: any ClientRepository,
        productRepository: any ProductRepository,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        self.init(
            observeClients: ObserveClientsUseCase(repository: clientRepository),
            observeProducts: ObserveProductsUseCase(repository: productRepository),
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
