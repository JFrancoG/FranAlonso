protocol AnalyticsDataSource: Sendable {
    func setCollectionEnabled(_ isEnabled: Bool) async throws
    func log(_ event: AnalyticsEvent) async throws
}

protocol CrashDataSource: Sendable {
    func setCollectionEnabled(_ isEnabled: Bool) async throws
    func record(_ diagnostic: CrashDiagnostic) async throws
}
