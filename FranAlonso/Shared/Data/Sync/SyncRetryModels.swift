import Foundation

/// One independently scheduled unit of synchronization work within a feature-owned retry table.
enum SyncRetryScope: Codable, Hashable {
    /// The incremental remote read and its local batch reconciliation.
    case pull

    /// One immutable pending mutation identified across every retry.
    case operation(UUID)

    var storageID: String {
        switch self {
        case .pull:
            "pull"
        case .operation(let operationID):
            "operation/\(operationID.uuidString)"
        }
    }
}

/// A transient remote condition for which a later idempotent attempt is permitted.
enum SyncRetryCategory: String, Codable, Equatable {
    case unavailable
    case deadlineExceeded
    case aborted
}

/// Whether a synchronization failure may consume the retry budget of its scope.
enum SyncErrorClassification: Equatable {
    case recoverable(SyncRetryCategory)
    case definitive
}

/// The durable schedule retained after a recoverable synchronization failure.
struct SyncRetryState: Equatable {
    private let storedScope: SyncRetryScope
    private let storedBackoffStep: Int
    private let storedNotBefore: Date
    private let storedLastRecoverableCategory: SyncRetryCategory

    var scope: SyncRetryScope { storedScope }
    var backoffStep: Int { storedBackoffStep }
    var notBefore: Date { storedNotBefore }
    var lastRecoverableCategory: SyncRetryCategory {
        storedLastRecoverableCategory
    }
}

extension SyncRetryState {
    /// Creates a trusted retry schedule from durable or newly calculated state.
    ///
    /// - Throws: `SyncRetryPolicyError` when the step or deadline is invalid.
    init(
        scope: SyncRetryScope,
        backoffStep: Int,
        notBefore: Date,
        lastRecoverableCategory: SyncRetryCategory
    ) throws {
        guard (1...6).contains(backoffStep) else {
            throw SyncRetryPolicyError.invalidBackoffStep(backoffStep)
        }
        guard notBefore.timeIntervalSinceReferenceDate.isFinite else { throw SyncRetryPolicyError.invalidDeadline }

        storedScope = scope
        storedBackoffStep = backoffStep
        storedNotBefore = notBefore
        storedLastRecoverableCategory = lastRecoverableCategory
    }
}

/// Injectable wall time, cancellable waiting and jitter for synchronization retry scheduling.
struct SyncTiming {
    let now: @Sendable () async -> Date
    let sleep: @Sendable (Duration) async throws -> Void
    let jitterFactor: @Sendable () async -> Double
}

extension SyncTiming {
    /// Uses durable wall time and Swift's nonblocking continuous-clock sleep in production.
    static var live: SyncTiming {
        SyncTiming(
            now: { Date.now },
            sleep: { duration in
                try await Task.sleep(
                    for: duration,
                    clock: .continuous
                )
            },
            jitterFactor: { Double.random(in: 1...2) }
        )
    }
}

/// Invalid scheduling state that must not produce another remote attempt.
enum SyncRetryPolicyError: Error, Equatable {
    case invalidBackoffStep(Int)
    case invalidDeadline
    case invalidJitterFactor
    case invalidStoredCategory(String)
    case scopeMismatch
}
