/// A provider-neutral analytics capability owned by the telemetry domain boundary.
protocol AnalyticsDataSource: Sendable {
    /// Applies the requested collection setting at the adapter boundary.
    ///
    /// - Parameter isEnabled: Whether the adapter should collect analytics data.
    /// - Throws: An adapter error when the requested setting cannot be honored.
    func setCollectionEnabled(_ isEnabled: Bool) async throws

    /// Emits one allowlisted technical analytics event.
    ///
    /// - Parameter event: The event accepted by the application's closed allowlist.
    /// - Throws: An adapter error when the event cannot be recorded.
    func log(_ event: AnalyticsEvent) async throws
}

/// A provider-neutral crash-reporting capability owned by the telemetry domain boundary.
protocol CrashDataSource: Sendable {
    /// Applies the requested crash-report collection setting at the adapter boundary.
    ///
    /// - Parameter isEnabled: Whether the adapter should collect crash reports.
    /// - Throws: An adapter error when the requested setting cannot be honored.
    func setCollectionEnabled(_ isEnabled: Bool) async throws

    /// Records one allowlisted non-PII diagnostic.
    ///
    /// - Parameter diagnostic: The stable technical diagnostic to record.
    /// - Throws: An adapter error when the diagnostic cannot be recorded.
    func record(_ diagnostic: CrashDiagnostic) async throws
}
