import Foundation

/// Classifies remote failures and calculates bounded durable retry deadlines.
struct ClientSyncRetryPolicy {
    /// Returns whether one failure is safe to retry under the current idempotent contract.
    func classification(
        for error: any Error
    ) -> ClientSyncErrorClassification {
        guard let remoteError = error as? ClientRemoteDataSourceError else {
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
        for scope: ClientSyncRetryScope,
        after previous: ClientSyncRetryState?,
        category: ClientSyncRetryCategory,
        failedAt: Date,
        jitterFactor: Double
    ) throws -> ClientSyncRetryState {
        if let previous, previous.scope != scope {
            throw ClientSyncRetryPolicyError.scopeMismatch
        }
        guard jitterFactor.isFinite,
              (1...2).contains(jitterFactor) else {
            throw ClientSyncRetryPolicyError.invalidJitterFactor
        }
        guard failedAt.timeIntervalSinceReferenceDate.isFinite else {
            throw ClientSyncRetryPolicyError.invalidDeadline
        }

        let step = min((previous?.backoffStep ?? 0) + 1, 6)
        let exponentialSeconds = Double(1 << (step - 1))
        let baseSeconds = min(exponentialSeconds, 30)
        let delaySeconds = min(baseSeconds * jitterFactor, 60)

        return try ClientSyncRetryState(
            scope: scope,
            backoffStep: step,
            notBefore: failedAt.addingTimeInterval(delaySeconds),
            lastRecoverableCategory: category
        )
    }
}
