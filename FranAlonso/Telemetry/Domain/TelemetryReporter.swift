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

    func track(_ event: AnalyticsEvent) async {
        guard consent.isGranted else {
            return
        }

        try? await analyticsDataSource.log(event)
    }

    func record(_ diagnostic: CrashDiagnostic) async {
        guard consent.isGranted else {
            return
        }

        try? await crashDataSource.record(diagnostic)
    }
}
