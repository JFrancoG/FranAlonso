import FirebaseAnalytics

/// Failures produced when Firebase Analytics cannot satisfy the application's privacy contract.
enum FirebaseAnalyticsDataSourceError: Error {
    /// SDK-managed automatic collection would emit events outside the closed allowlist.
    case automaticCollectionOutsideAllowlist
}

/// A fail-closed adapter that keeps Firebase Analytics disabled.
///
/// The Firebase SDK cannot enforce the application's closed event allowlist, so this adapter
/// refuses both collection enablement and individual event logging.
struct FirebaseAnalyticsDataSource: AnalyticsDataSource {
    /// Keeps collection disabled and rejects an enable request.
    ///
    /// - Parameter isEnabled: The requested collection state.
    /// - Throws: `FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist`
    ///   when enablement is requested.
    func setCollectionEnabled(_ isEnabled: Bool) async throws {
        Analytics.setAnalyticsCollectionEnabled(false)

        if isEnabled {
            throw FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist
        }
    }

    /// Rejects event logging because this Firebase capability is intentionally unavailable.
    ///
    /// - Parameter event: The allowlisted event rejected by this adapter.
    /// - Throws: `FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist`.
    func log(_ event: AnalyticsEvent) async throws {
        throw FirebaseAnalyticsDataSourceError.automaticCollectionOutsideAllowlist
    }
}
