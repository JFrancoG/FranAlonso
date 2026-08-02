import Testing
@testable import FranAlonso

@Suite("Telemetry privacy")
struct TelemetryPrivacyTests {
    @Test("Analytics uses a closed allowlist with technical values")
    func analyticsUsesClosedAllowlist() {
        #expect(AnalyticsEvent.appOpened.payload == AnalyticsPayload(
            name: "app_opened",
            parameters: [:]
        ))
        #expect(AnalyticsEvent.screenViewed(.bootstrap).payload == AnalyticsPayload(
            name: "screen_viewed",
            parameters: ["screen": "bootstrap"]
        ))
    }

    @Test("Telemetry is denied by default")
    func telemetryIsDeniedByDefault() async {
        let analytics = AnalyticsDataSourceSpy()
        let crash = CrashDataSourceSpy()
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await reporter.track(.appOpened)
        await reporter.record(.controlledValidation)

        #expect(await analytics.loggedEvents().isEmpty)
        #expect(await crash.recordedDiagnostics().isEmpty)
    }

    @Test("Consent enables allowlist-compatible data sources")
    func consentEnablesAllowlistCompatibleDataSources() async {
        let analytics = AnalyticsDataSourceSpy()
        let crash = CrashDataSourceSpy()
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await reporter.updateConsent(.granted)
        await reporter.track(.screenViewed(.bootstrap))
        await reporter.record(.controlledValidation)

        #expect(await analytics.collectionChanges() == [true])
        #expect(await analytics.loggedEvents() == [.screenViewed(.bootstrap)])
        #expect(await crash.collectionChanges() == [true])
        #expect(await crash.recordedDiagnostics() == [.controlledValidation])
    }

    @Test("An unavailable analytics sink does not block crash reporting")
    func unavailableAnalyticsDoesNotBlockCrashReporting() async {
        let analytics = AnalyticsDataSourceSpy(shouldFail: true)
        let crash = CrashDataSourceSpy()
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await reporter.updateConsent(.granted)
        await reporter.record(.controlledValidation)

        #expect(await analytics.collectionAttemptCount() == 1)
        #expect(await crash.collectionChanges() == [true])
        #expect(await crash.recordedDiagnostics() == [.controlledValidation])
    }

    @Test("Revoking consent disables collection and suppresses telemetry")
    func revokingConsentDisablesAndSuppressesTelemetry() async {
        let analytics = AnalyticsDataSourceSpy()
        let crash = CrashDataSourceSpy()
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await reporter.updateConsent(.granted)
        await reporter.updateConsent(.denied)
        await reporter.track(.appOpened)
        await reporter.record(.controlledValidation)

        #expect(await analytics.collectionChanges() == [true, false])
        #expect(await analytics.loggedEvents().isEmpty)
        #expect(await crash.collectionChanges() == [true, false])
        #expect(await crash.recordedDiagnostics().isEmpty)
    }

    @Test("Telemetry failures never escape into business flows")
    func telemetryFailuresNeverEscape() async {
        let analytics = AnalyticsDataSourceSpy(shouldFail: true)
        let crash = CrashDataSourceSpy(shouldFail: true)
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        await reporter.updateConsent(.granted)
        await reporter.track(.appOpened)
        await reporter.record(.controlledValidation)

        #expect(await analytics.collectionAttemptCount() == 1)
        #expect(await analytics.logAttemptCount() == 1)
        #expect(await crash.collectionAttemptCount() == 1)
        #expect(await crash.recordAttemptCount() == 1)
    }

    @Test("The latest consent wins when updates overlap")
    func latestConsentWinsWhenUpdatesOverlap() async {
        let analytics = AnalyticsDataSourceSpy()
        let crash = SuspendingCrashDataSource()
        let reporter = TelemetryReporter(
            analyticsDataSource: analytics,
            crashDataSource: crash
        )

        async let granting: Void = reporter.updateConsent(.granted)
        await crash.waitUntilEnableIsSuspended()
        async let revoking: Void = reporter.updateConsent(.denied)
        await crash.waitUntilDisableIsApplied()
        await crash.resumeSuspendedEnable()
        _ = await (granting, revoking)

        #expect(await crash.lastCollectionValue() == false)
    }
}

private enum TelemetryDataSourceFailure: Error {
    case controlled
}

private actor AnalyticsDataSourceSpy: AnalyticsDataSource {
    private let shouldFail: Bool
    private var collectionValues: [Bool] = []
    private var events: [AnalyticsEvent] = []
    private var collectionAttempts = 0
    private var logAttempts = 0

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func setCollectionEnabled(_ isEnabled: Bool) throws {
        collectionAttempts += 1
        if shouldFail {
            throw TelemetryDataSourceFailure.controlled
        }
        collectionValues.append(isEnabled)
    }

    func log(_ event: AnalyticsEvent) throws {
        logAttempts += 1
        if shouldFail {
            throw TelemetryDataSourceFailure.controlled
        }
        events.append(event)
    }

    func collectionChanges() -> [Bool] { collectionValues }

    func loggedEvents() -> [AnalyticsEvent] { events }

    func collectionAttemptCount() -> Int { collectionAttempts }

    func logAttemptCount() -> Int { logAttempts }
}

private actor CrashDataSourceSpy: CrashDataSource {
    private let shouldFail: Bool
    private var collectionValues: [Bool] = []
    private var diagnostics: [CrashDiagnostic] = []
    private var collectionAttempts = 0
    private var recordAttempts = 0

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func setCollectionEnabled(_ isEnabled: Bool) throws {
        collectionAttempts += 1
        if shouldFail {
            throw TelemetryDataSourceFailure.controlled
        }
        collectionValues.append(isEnabled)
    }

    func record(_ diagnostic: CrashDiagnostic) throws {
        recordAttempts += 1
        if shouldFail {
            throw TelemetryDataSourceFailure.controlled
        }
        diagnostics.append(diagnostic)
    }

    func collectionChanges() -> [Bool] { collectionValues }

    func recordedDiagnostics() -> [CrashDiagnostic] { diagnostics }

    func collectionAttemptCount() -> Int { collectionAttempts }

    func recordAttemptCount() -> Int { recordAttempts }
}

private actor SuspendingCrashDataSource: CrashDataSource {
    private var collectionValues: [Bool] = []
    private var shouldSuspendEnable = true
    private var enableContinuation: CheckedContinuation<Void, Never>?
    private var enableWaiters: [CheckedContinuation<Void, Never>] = []
    private var disableWaiters: [CheckedContinuation<Void, Never>] = []

    func setCollectionEnabled(_ isEnabled: Bool) async {
        if isEnabled, shouldSuspendEnable {
            shouldSuspendEnable = false
            await withCheckedContinuation { continuation in
                enableContinuation = continuation
                enableWaiters.forEach { $0.resume() }
                enableWaiters.removeAll()
            }
        }

        collectionValues.append(isEnabled)
        if !isEnabled {
            disableWaiters.forEach { $0.resume() }
            disableWaiters.removeAll()
        }
    }

    func record(_ diagnostic: CrashDiagnostic) {}

    func waitUntilEnableIsSuspended() async {
        guard enableContinuation == nil else { return }

        await withCheckedContinuation { continuation in
            enableWaiters.append(continuation)
        }
    }

    func waitUntilDisableIsApplied() async {
        guard !collectionValues.contains(false) else { return }

        await withCheckedContinuation { continuation in
            disableWaiters.append(continuation)
        }
    }

    func resumeSuspendedEnable() {
        let continuation = enableContinuation
        enableContinuation = nil
        continuation?.resume()
    }

    func lastCollectionValue() -> Bool? { collectionValues.last }
}
