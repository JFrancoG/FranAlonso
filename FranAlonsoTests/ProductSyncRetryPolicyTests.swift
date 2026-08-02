import Testing
@testable import FranAlonso

@Suite("Products synchronization error classification")
struct ProductSyncRetryPolicyTests {
    @Test(
        "Transient provider failures are recoverable",
        arguments: [
            (
                ProductRemoteDataSourceError.unavailable,
                SyncRetryCategory.unavailable
            ),
            (
                ProductRemoteDataSourceError.deadlineExceeded,
                SyncRetryCategory.deadlineExceeded
            ),
            (
                ProductRemoteDataSourceError.aborted,
                SyncRetryCategory.aborted
            )
        ]
    )
    func transientProviderFailuresAreRecoverable(error: ProductRemoteDataSourceError, category: SyncRetryCategory) {
        #expect(error.syncClassification == .recoverable(category))
    }

    @Test(
        "Provider failures requiring intervention are definitive",
        arguments: [
            ProductRemoteDataSourceError.permissionDenied,
            .resourceExhausted,
            .unexpected
        ]
    )
    func providerFailuresRequiringInterventionAreDefinitive(error: ProductRemoteDataSourceError) {
        #expect(error.syncClassification == .definitive)
    }
}
