import Foundation
import Testing
@testable import FranAlonso

@Suite("Shared synchronization backoff policy")
struct SyncBackoffPolicyTests {
    private let policy = SyncBackoffPolicy()

    @Test("Retry scopes preserve their published storage identity")
    func retryScopesPreservePublishedStorageIdentity() {
        let operationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000151"
        )!

        #expect(SyncRetryScope.pull.storageID == "pull")
        #expect(
            SyncRetryScope.operation(operationID).storageID
                == "operation/00000000-0000-0000-0000-000000000151"
        )
    }

    @Test(
        "Retry categories preserve their published raw values",
        arguments: [
            (SyncRetryCategory.unavailable, "unavailable"),
            (.deadlineExceeded, "deadlineExceeded"),
            (.aborted, "aborted")
        ]
    )
    func retryCategoriesPreservePublishedRawValues(category: SyncRetryCategory, rawValue: String) {
        #expect(category.rawValue == rawValue)
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
        let previous = try SyncRetryState(
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
        #expect(throws: SyncRetryPolicyError.invalidBackoffStep(0)) {
            _ = try SyncRetryState(
                scope: .pull,
                backoffStep: 0,
                notBefore: .now,
                lastRecoverableCategory: .unavailable
            )
        }
    }

    @Test("A retry state rejects a non-finite deadline")
    func retryStateRejectsNonFiniteDeadline() {
        #expect(throws: SyncRetryPolicyError.invalidDeadline) {
            _ = try SyncRetryState(
                scope: .pull,
                backoffStep: 1,
                notBefore: Date(timeIntervalSinceReferenceDate: .infinity),
                lastRecoverableCategory: .unavailable
            )
        }
    }

    @Test("A previous state from another scope fails closed")
    func previousStateFromAnotherScopeFailsClosed() throws {
        let operationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000152"
        )!
        let previous = try SyncRetryState(
            scope: .operation(operationID),
            backoffStep: 1,
            notBefore: .now,
            lastRecoverableCategory: .unavailable
        )

        #expect(throws: SyncRetryPolicyError.scopeMismatch) {
            _ = try policy.nextState(
                for: .pull,
                after: previous,
                category: .aborted,
                failedAt: .now,
                jitterFactor: 1
            )
        }
    }

    @Test(
        "Jitter outside the closed one-to-two range fails closed",
        arguments: [0.99, 2.01, .infinity, .nan]
    )
    func invalidJitterFailsClosed(_ jitterFactor: Double) {
        #expect(throws: SyncRetryPolicyError.invalidJitterFactor) {
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
