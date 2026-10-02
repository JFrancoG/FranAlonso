import Foundation

/// Reconciles the durable Stock ledger with the provider-neutral remote source.
actor StockSyncEngine {
    private let persistenceActor: StockPersistenceActor
    private let remoteDataSource: any StockRemoteDataSource
    private let observationSignal: any ProductChangeSignaling
    private let retryPolicy: SyncBackoffPolicy
    private let timing: SyncTiming
    private var isSynchronizing = false

    /// Creates the Stock engine from isolated local and replaceable remote roles.
    init(
        persistenceActor: StockPersistenceActor,
        remoteDataSource: any StockRemoteDataSource,
        observationSignal: any ProductChangeSignaling,
        retryPolicy: SyncBackoffPolicy = SyncBackoffPolicy(),
        timing: SyncTiming = .live
    ) {
        self.persistenceActor = persistenceActor
        self.remoteDataSource = remoteDataSource
        self.observationSignal = observationSignal
        self.retryPolicy = retryPolicy
        self.timing = timing
    }

    /// Performs one explicit, single-flight incremental pull and immutable push pass.
    ///
    /// The pulled batch and cursor commit atomically before any push begins. Its observation
    /// signal is therefore published even when a later remote push fails. Recoverable remote
    /// failures use durable per-scope backoff under the caller's task. The engine still has no
    /// automatic trigger in this Stock checkpoint.
    ///
    /// - Throws: `StockSyncError.alreadySynchronizing` for an overlapping pass,
    ///   `CancellationError` when the caller cancels, or a remote, policy or persistence error.
    func synchronize() async throws {
        guard !isSynchronizing else { throw StockSyncError.alreadySynchronizing }
        isSynchronizing = true
        defer { isSynchronizing = false }

        let currentCursor = try await persistenceActor.cursor()
        try Task.checkCancellation()
        let remoteDataSource = remoteDataSource
        let batch = try await performWithRetry(scope: .pull) {
            try await remoteDataSource.fetchChanges(after: currentCursor)
        }
        try Task.checkCancellation()
        try await persistenceActor.reconcileRemoteBatch(batch)
        await observationSignal.publishChange()

        let movements = try await persistenceActor.deliverablePendingMovements()
        for movement in movements {
            try Task.checkCancellation()
            let scope = SyncRetryScope.operation(movement.id.rawValue)
            let result = try await performWithRetry(scope: scope) {
                try await remoteDataSource.apply(movement)
            }
            try Task.checkCancellation()
            switch result {
            case .applied(let record), .alreadyApplied(let record):
                try await persistenceActor.acknowledge(movement, record: record)
            case .conflict(let record):
                try await persistenceActor.recordConflict(movement, remote: record)
            }
            await observationSignal.publishChange()
        }
    }

    private func performWithRetry<Success: Sendable>(
        scope: SyncRetryScope,
        operation: @Sendable () async throws -> Success
    ) async throws -> Success {
        var state = try await persistenceActor.retryState(for: scope)
        try Task.checkCancellation()
        if let state {
            try await wait(until: state.notBefore)
        }

        for attempt in 1...3 {
            try Task.checkCancellation()
            do {
                let value = try await operation()
                try Task.checkCancellation()
                return value
            } catch {
                try Task.checkCancellation()
                if error is CancellationError {
                    throw CancellationError()
                }

                let remoteError = error as? StockRemoteDataSourceError
                let classification = remoteError?.syncClassification ?? .definitive
                switch classification {
                case .definitive:
                    try await persistenceActor.clearRetryState(for: scope)
                    throw error
                case .recoverable(let category):
                    let failedAt = await timing.now()
                    let jitterFactor = await timing.jitterFactor()
                    let nextState = try retryPolicy.nextState(
                        for: scope,
                        after: state,
                        category: category,
                        failedAt: failedAt,
                        jitterFactor: jitterFactor
                    )
                    try Task.checkCancellation()
                    try await persistenceActor.saveRetryState(nextState)
                    state = nextState

                    guard attempt < 3 else { throw error }
                    try await wait(until: nextState.notBefore)
                }
            }
        }

        throw StockRemoteDataSourceError.unexpected
    }

    private func wait(until deadline: Date) async throws {
        let currentDate = await timing.now()
        let remaining = deadline.timeIntervalSince(currentDate)
        guard remaining.isFinite else { throw SyncRetryPolicyError.invalidDeadline }
        let boundedRemaining = min(max(remaining, 0), 60)
        guard boundedRemaining > 0 else { return }

        try Task.checkCancellation()
        try await timing.sleep(.seconds(boundedRemaining))
        try Task.checkCancellation()
    }
}
