import Foundation

/// One independently scheduled unit of Clients synchronization work.
enum ClientSyncRetryScope: Codable, Hashable {
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
enum ClientSyncRetryCategory: String, Codable, Equatable {
    case unavailable
    case deadlineExceeded
    case aborted
}

/// Whether a synchronization failure may consume the retry budget of its scope.
enum ClientSyncErrorClassification: Equatable {
    case recoverable(ClientSyncRetryCategory)
    case definitive
}

/// The durable schedule retained after a recoverable Clients synchronization failure.
struct ClientSyncRetryState: Equatable {
    private let storedScope: ClientSyncRetryScope
    private let storedBackoffStep: Int
    private let storedNotBefore: Date
    private let storedLastRecoverableCategory: ClientSyncRetryCategory

    var scope: ClientSyncRetryScope { storedScope }
    var backoffStep: Int { storedBackoffStep }
    var notBefore: Date { storedNotBefore }
    var lastRecoverableCategory: ClientSyncRetryCategory {
        storedLastRecoverableCategory
    }
}

extension ClientSyncRetryState {
    /// Creates a trusted retry schedule from durable or newly calculated state.
    ///
    /// - Throws: `ClientSyncRetryPolicyError` when the step or deadline is invalid.
    init(
        scope: ClientSyncRetryScope,
        backoffStep: Int,
        notBefore: Date,
        lastRecoverableCategory: ClientSyncRetryCategory
    ) throws {
        guard (1...6).contains(backoffStep) else {
            throw ClientSyncRetryPolicyError.invalidBackoffStep(
                backoffStep
            )
        }
        guard notBefore.timeIntervalSinceReferenceDate.isFinite else {
            throw ClientSyncRetryPolicyError.invalidDeadline
        }

        storedScope = scope
        storedBackoffStep = backoffStep
        storedNotBefore = notBefore
        storedLastRecoverableCategory = lastRecoverableCategory
    }
}

/// Injectable wall time, cancellable waiting and jitter for Clients retry scheduling.
struct ClientSyncTiming {
    let now: @Sendable () async -> Date
    let sleep: @Sendable (Duration) async throws -> Void
    let jitterFactor: @Sendable () async -> Double
}

extension ClientSyncTiming {
    /// Uses durable wall time and Swift's nonblocking continuous-clock sleep in production.
    static var live: ClientSyncTiming {
        ClientSyncTiming(
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
enum ClientSyncRetryPolicyError: Error, Equatable {
    case invalidBackoffStep(Int)
    case invalidDeadline
    case invalidJitterFactor
    case invalidStoredCategory(String)
    case scopeMismatch
}
