/// Coordinates independent telemetry adapters behind the latest owner consent.
///
/// Telemetry begins denied. Emission is suppressed without consent, overlapping consent
/// updates converge on the latest value, and adapter failures never escape into business flows.
actor TelemetryReporter {
    private let analyticsDataSource: any AnalyticsDataSource
    private let crashDataSource: any CrashDataSource
    private var consent: TelemetryConsent = .denied
    private var consentRevision = 0

    init(
        analyticsDataSource: any AnalyticsDataSource,
        crashDataSource: any CrashDataSource
    ) {
        self.analyticsDataSource = analyticsDataSource
        self.crashDataSource = crashDataSource
    }

    /// Updates the in-process emission gate and requests the same state from both adapters.
    ///
    /// Overlapping calls converge on the latest consent revision. Adapter failures remain
    /// isolated and do not prevent the other telemetry capability from receiving the update.
    ///
    /// - Parameter consent: The latest owner-controlled telemetry consent.
    func updateConsent(_ consent: TelemetryConsent) async {
        self.consent = consent
        consentRevision &+= 1

        await applyLatestConsent()
    }

    private func applyLatestConsent() async {
        while true {
            let revision = consentRevision
            let isEnabled = consent.isGranted

            try? await analyticsDataSource.setCollectionEnabled(isEnabled)
            guard revision == consentRevision else {
                continue
            }

            try? await crashDataSource.setCollectionEnabled(isEnabled)
            guard revision == consentRevision else {
                continue
            }

            return
        }
    }

    /// Attempts to emit an allowlisted event only while in-process consent is granted.
    ///
    /// Adapter failures are deliberately discarded so analytics cannot block business flows.
    ///
    /// - Parameter event: The technical analytics event to emit.
    func track(_ event: AnalyticsEvent) async {
        guard consent.isGranted else {
            return
        }

        try? await analyticsDataSource.log(event)
    }

    /// Attempts to record a diagnostic only while in-process consent is granted.
    ///
    /// Adapter failures are deliberately discarded so crash reporting cannot block business flows.
    ///
    /// - Parameter diagnostic: The allowlisted technical diagnostic to record.
    func record(_ diagnostic: CrashDiagnostic) async {
        guard consent.isGranted else {
            return
        }

        try? await crashDataSource.record(diagnostic)
    }
}
