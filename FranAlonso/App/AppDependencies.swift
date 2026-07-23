struct AppDependencies {
    let observeClients: ObserveClientsUseCase
    let telemetryReporter: TelemetryReporter

    static func live() -> AppDependencies {
        AppDependencies(
            clientRepository: InMemoryClientRepository(),
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
