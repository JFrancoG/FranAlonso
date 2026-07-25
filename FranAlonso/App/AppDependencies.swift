import SwiftData

struct AppDependencies {
    let observeClients: ObserveClientsUseCase
    let telemetryReporter: TelemetryReporter

    /// Creates production dependencies over the supplied local source of truth.
    ///
    /// The Clients Repository remains local-only; Firestore composition begins with the
    /// first SyncEngine in subphase 05.7.
    ///
    /// - Parameter modelContainer: The application container shared with SwiftUI.
    /// - Returns: Dependencies backed by durable Clients persistence and live telemetry.
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let observationSignal = ClientObservationSignal()
        let clientRepository = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(
                modelContainer: modelContainer
            ),
            observationSignal: observationSignal
        )

        return AppDependencies(
            clientRepository: clientRepository,
            analyticsDataSource: FirebaseAnalyticsDataSource(),
            crashDataSource: FirebaseCrashDataSource()
        )
    }

    static func preview(clients: [Client] = []) -> AppDependencies {
        AppDependencies(
            clientRepository: InMemoryClientRepository(clients: clients),
            analyticsDataSource: PreviewAnalyticsDataSource(),
            crashDataSource: PreviewCrashDataSource()
        )
    }
}

extension AppDependencies {
    init(
        clientRepository: any ClientRepository,
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        self.init(
            observeClients: ObserveClientsUseCase(repository: clientRepository),
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
