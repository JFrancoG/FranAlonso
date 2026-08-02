import Testing
@testable import FranAlonso

@Suite("Clients synchronization error classification")
struct ClientSyncRetryPolicyTests {
    @Test(
        "Transient provider failures are recoverable",
        arguments: [
            (
                ClientRemoteDataSourceError.unavailable,
                SyncRetryCategory.unavailable
            ),
            (
                ClientRemoteDataSourceError.deadlineExceeded,
                SyncRetryCategory.deadlineExceeded
            ),
            (
                ClientRemoteDataSourceError.aborted,
                SyncRetryCategory.aborted
            )
        ]
    )
    func transientProviderFailuresAreRecoverable(error: ClientRemoteDataSourceError, category: SyncRetryCategory) {
        #expect(error.syncClassification == .recoverable(category))
    }

    @Test(
        "Provider failures requiring intervention are definitive",
        arguments: [
            ClientRemoteDataSourceError.permissionDenied,
            .resourceExhausted,
            .unexpected
        ]
    )
    func providerFailuresRequiringInterventionAreDefinitive(error: ClientRemoteDataSourceError) {
        #expect(error.syncClassification == .definitive)
    }
}
