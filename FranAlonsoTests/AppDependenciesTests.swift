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
