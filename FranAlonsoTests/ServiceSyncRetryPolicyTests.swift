import Testing
@testable import FranAlonso

@Suite("Services synchronization error classification")
struct ServiceSyncRetryPolicyTests {
    @Test(
        "Transient provider failures are recoverable",
        arguments: [
            (
                ServiceRemoteDataSourceError.unavailable,
                SyncRetryCategory.unavailable
            ),
            (
                ServiceRemoteDataSourceError.deadlineExceeded,
                SyncRetryCategory.deadlineExceeded
            ),
            (
                ServiceRemoteDataSourceError.aborted,
                SyncRetryCategory.aborted
            )
        ]
    )
    func transientProviderFailuresAreRecoverable(
        error: ServiceRemoteDataSourceError,
        category: SyncRetryCategory
    ) {
        #expect(error.syncClassification == .recoverable(category))
    }

    @Test(
        "Provider failures requiring intervention are definitive",
        arguments: [
            ServiceRemoteDataSourceError.permissionDenied,
            .resourceExhausted,
            .unexpected
        ]
    )
    func providerFailuresRequiringInterventionAreDefinitive(
        error: ServiceRemoteDataSourceError
    ) {
        #expect(error.syncClassification == .definitive)
    }
}
