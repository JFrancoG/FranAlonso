import Foundation

/// One independently scheduled unit of Products synchronization work.
enum ProductSyncRetryScope: Codable, Hashable {
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
enum ProductSyncRetryCategory: String, Codable, Equatable {
    case unavailable
    case deadlineExceeded
    case aborted
}

/// Whether a synchronization failure may consume the retry budget of its scope.
enum ProductSyncErrorClassification: Equatable {
    case recoverable(ProductSyncRetryCategory)
    case definitive
}

/// The durable schedule retained after a recoverable Products synchronization failure.
struct ProductSyncRetryState: Equatable {
    private let storedScope: ProductSyncRetryScope
    private let storedBackoffStep: Int
    private let storedNotBefore: Date
    private let storedLastRecoverableCategory: ProductSyncRetryCategory

    var scope: ProductSyncRetryScope { storedScope }
    var backoffStep: Int { storedBackoffStep }
    var notBefore: Date { storedNotBefore }
    var lastRecoverableCategory: ProductSyncRetryCategory {
        storedLastRecoverableCategory
    }
}

extension ProductSyncRetryState {
    /// Creates a trusted retry schedule from durable or newly calculated state.
    ///
    /// - Throws: `ProductSyncRetryPolicyError` when the step or deadline is invalid.
    init(
        scope: ProductSyncRetryScope,
        backoffStep: Int,
        notBefore: Date,
        lastRecoverableCategory: ProductSyncRetryCategory
    ) throws {
        guard (1...6).contains(backoffStep) else {
            throw ProductSyncRetryPolicyError.invalidBackoffStep(
                backoffStep
            )
        }
        guard notBefore.timeIntervalSinceReferenceDate.isFinite else {
            throw ProductSyncRetryPolicyError.invalidDeadline
        }

        storedScope = scope
        storedBackoffStep = backoffStep
        storedNotBefore = notBefore
        storedLastRecoverableCategory = lastRecoverableCategory
    }
}

/// Injectable wall time, cancellable waiting and jitter for Products retry scheduling.
struct ProductSyncTiming {
    let now: @Sendable () async -> Date
    let sleep: @Sendable (Duration) async throws -> Void
    let jitterFactor: @Sendable () async -> Double
}

extension ProductSyncTiming {
    /// Uses durable wall time and Swift's nonblocking continuous-clock sleep in production.
    static var live: ProductSyncTiming {
        ProductSyncTiming(
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
enum ProductSyncRetryPolicyError: Error, Equatable {
    case invalidBackoffStep(Int)
    case invalidDeadline
    case invalidJitterFactor
    case invalidStoredCategory(String)
    case scopeMismatch
}
