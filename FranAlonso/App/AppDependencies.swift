struct AppDependencies: Sendable {
    let telemetryReporter: TelemetryReporter

    init(
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        telemetryReporter = TelemetryReporter(
            analyticsDataSource: analyticsDataSource,
            crashDataSource: crashDataSource
        )
    }

    static func live() -> AppDependencies {
        AppDependencies(
            analyticsDataSource: FirebaseAnalyticsDataSource(),
            crashDataSource: FirebaseCrashDataSource()
        )
    }

    static func preview() -> AppDependencies {
        AppDependencies(
            analyticsDataSource: PreviewAnalyticsDataSource(),
            crashDataSource: PreviewCrashDataSource()
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
