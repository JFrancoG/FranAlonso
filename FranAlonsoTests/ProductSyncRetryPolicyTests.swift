import Foundation
import Testing
@testable import FranAlonso

@Suite("Products synchronization retry policy")
struct ProductSyncRetryPolicyTests {
    private let policy = ProductSyncRetryPolicy()

    @Test(
        "Transient provider failures are recoverable",
        arguments: [
            (
                ProductRemoteDataSourceError.unavailable,
                ProductSyncRetryCategory.unavailable
            ),
            (
                ProductRemoteDataSourceError.deadlineExceeded,
                ProductSyncRetryCategory.deadlineExceeded
            ),
            (
                ProductRemoteDataSourceError.aborted,
                ProductSyncRetryCategory.aborted
            )
        ]
    )
    func transientProviderFailuresAreRecoverable(
        error: ProductRemoteDataSourceError,
        category: ProductSyncRetryCategory
    ) {
        #expect(
            policy.classification(for: error)
                == .recoverable(category)
        )
    }

    @Test(
        "Provider failures requiring intervention are definitive",
        arguments: [
            ProductRemoteDataSourceError.permissionDenied,
            .resourceExhausted,
            .unexpected
        ]
    )
    func providerFailuresRequiringInterventionAreDefinitive(
        error: ProductRemoteDataSourceError
    ) {
        #expect(policy.classification(for: error) == .definitive)
    }

    @Test("Non-transport failures are definitive")
    func nonTransportFailuresAreDefinitive() {
        #expect(
            policy.classification(
                for: ProductSyncPolicyError.invalidRemoteRevision
            ) == .definitive
        )
    }

    @Test("Backoff begins at one second and advances exponentially")
    func backoffBeginsAtOneSecondAndAdvancesExponentially() throws {
        let failedAt = Date(timeIntervalSinceReferenceDate: 1_000)
        let first = try policy.nextState(
            for: .pull,
            after: nil,
            category: .unavailable,
            failedAt: failedAt,
            jitterFactor: 1
        )
        let second = try policy.nextState(
            for: .pull,
            after: first,
            category: .deadlineExceeded,
            failedAt: first.notBefore,
            jitterFactor: 2
        )

        #expect(first.backoffStep == 1)
        #expect(first.notBefore == failedAt.addingTimeInterval(1))
        #expect(first.lastRecoverableCategory == .unavailable)
        #expect(second.backoffStep == 2)
        #expect(
            second.notBefore
                == first.notBefore.addingTimeInterval(4)
        )
        #expect(second.lastRecoverableCategory == .deadlineExceeded)
    }

    @Test("Backoff saturates at step six and sixty seconds")
    func backoffSaturatesAtStepSixAndSixtySeconds() throws {
        let failedAt = Date(timeIntervalSinceReferenceDate: 2_000)
        let previous = try ProductSyncRetryState(
            scope: .pull,
            backoffStep: 6,
            notBefore: failedAt,
            lastRecoverableCategory: .aborted
        )

        let next = try policy.nextState(
            for: .pull,
            after: previous,
            category: .unavailable,
            failedAt: failedAt,
            jitterFactor: 2
        )

        #expect(next.backoffStep == 6)
        #expect(next.notBefore == failedAt.addingTimeInterval(60))
    }

    @Test("A retry state rejects an invalid persisted step")
    func retryStateRejectsInvalidPersistedStep() {
        #expect(
            throws: ProductSyncRetryPolicyError.invalidBackoffStep(0)
        ) {
            _ = try ProductSyncRetryState(
                scope: .pull,
                backoffStep: 0,
                notBefore: .now,
                lastRecoverableCategory: .unavailable
            )
        }
    }

    @Test(
        "Jitter outside the closed one-to-two range fails closed",
        arguments: [0.99, 2.01, .infinity, .nan]
    )
    func invalidJitterFailsClosed(_ jitterFactor: Double) {
        #expect(
            throws: ProductSyncRetryPolicyError.invalidJitterFactor
        ) {
            _ = try policy.nextState(
                for: .pull,
                after: nil,
                category: .unavailable,
                failedAt: .now,
                jitterFactor: jitterFactor
            )
        }
    }
}
