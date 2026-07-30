import Foundation

/// Calculates bounded durable retry deadlines independently of a feature's transport errors.
struct SyncBackoffPolicy {
    /// Calculates and validates the next exponential backoff deadline for one scope.
    ///
    /// The step saturates at six. The sampled factor must be within `1...2`; the resulting
    /// delay is capped at sixty seconds.
    func nextState(
        for scope: SyncRetryScope,
        after previous: SyncRetryState?,
        category: SyncRetryCategory,
        failedAt: Date,
        jitterFactor: Double
    ) throws -> SyncRetryState {
        if let previous, previous.scope != scope {
            throw SyncRetryPolicyError.scopeMismatch
        }
        guard jitterFactor.isFinite,
              (1...2).contains(jitterFactor) else {
            throw SyncRetryPolicyError.invalidJitterFactor
        }
        guard failedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw SyncRetryPolicyError.invalidDeadline
        }

        let step = min((previous?.backoffStep ?? 0) + 1, 6)
        let exponentialSeconds = Double(1 << (step - 1))
        let baseSeconds = min(exponentialSeconds, 30)
        let delaySeconds = min(baseSeconds * jitterFactor, 60)

        return try SyncRetryState(
            scope: scope,
            backoffStep: step,
            notBefore: failedAt.addingTimeInterval(delaySeconds),
            lastRecoverableCategory: category
        )
    }
}
