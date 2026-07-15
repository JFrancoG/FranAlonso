import FirebaseAnalytics

enum FirebaseAnalyticsDataSourceError: Error {
    case automaticCollectionOutsideAllowlist
}

struct FirebaseAnalyticsDataSource: AnalyticsDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) async throws {
        Analytics.setAnalyticsCollectionEnabled(false)

        if isEnabled {
            throw FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist
        }
    }

    func log(_ event: AnalyticsEvent) async throws {
        throw FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist
    }
}
