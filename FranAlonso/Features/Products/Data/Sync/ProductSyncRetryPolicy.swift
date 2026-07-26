import Foundation

/// Classifies remote failures and calculates bounded durable retry deadlines.
struct ProductSyncRetryPolicy {
    /// Returns whether one failure is safe to retry under the current idempotent contract.
    func classification(
        for error: any Error
    ) -> ProductSyncErrorClassification {
        guard let remoteError = error as? ProductRemoteDataSourceError else {
            return .definitive
        }

        return switch remoteError {
        case .unavailable:
            .recoverable(.unavailable)
        case .deadlineExceeded:
            .recoverable(.deadlineExceeded)
        case .aborted:
            .recoverable(.aborted)
        case .permissionDenied, .resourceExhausted, .unexpected:
            .definitive
        }
    }

    /// Calculates and validates the next exponential backoff deadline for one scope.
    ///
    /// The step saturates at six. The sampled factor must be within `1...2`; the resulting
    /// delay is capped at sixty seconds.
    func nextState(
        for scope: ProductSyncRetryScope,
        after previous: ProductSyncRetryState?,
        category: ProductSyncRetryCategory,
        failedAt: Date,
        jitterFactor: Double
    ) throws -> ProductSyncRetryState {
        if let previous, previous.scope != scope {
            throw ProductSyncRetryPolicyError.scopeMismatch
        }
        guard jitterFactor.isFinite,
              (1...2).contains(jitterFactor) else {
            throw ProductSyncRetryPolicyError.invalidJitterFactor
        }
        guard failedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw ProductSyncRetryPolicyError.invalidDeadline
        }

        let step = min((previous?.backoffStep ?? 0) + 1, 6)
        let exponentialSeconds = Double(1 << (step - 1))
        let baseSeconds = min(exponentialSeconds, 30)
        let delaySeconds = min(baseSeconds * jitterFactor, 60)

        return try ProductSyncRetryState(
            scope: scope,
            backoffStep: step,
            notBefore: failedAt.addingTimeInterval(delaySeconds),
            lastRecoverableCategory: category
        )
    }
}
