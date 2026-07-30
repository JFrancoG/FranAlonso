import Foundation

/// Reconciles the durable Clients operation chain with the provider-neutral remote source.
actor ClientSyncEngine {
    private let persistenceActor: ClientPersistenceActor
    private let remoteDataSource: any ClientRemoteDataSource
    private let observationSignal: any ClientChangeSignaling
    private let syncPolicy: ClientSyncPolicy
    private let retryPolicy: SyncBackoffPolicy
    private let timing: SyncTiming
    private var isSynchronizing = false

    /// Creates the Clients engine from isolated local and replaceable remote roles.
    init(
        persistenceActor: ClientPersistenceActor,
        remoteDataSource: any ClientRemoteDataSource,
        observationSignal: any ClientChangeSignaling,
        policy: ClientSyncPolicy = ClientSyncPolicy(),
        retryPolicy: SyncBackoffPolicy = SyncBackoffPolicy(),
        timing: SyncTiming = .live
    ) {
        self.persistenceActor = persistenceActor
        self.remoteDataSource = remoteDataSource
        self.observationSignal = observationSignal
        syncPolicy = policy
        self.retryPolicy = retryPolicy
        self.timing = timing
    }

    /// Performs one explicit, single-flight incremental pull and causal push pass.
    ///
    /// The pulled batch and cursor commit atomically before any push begins. Its observation
    /// signal is therefore published even when a later remote push fails. Recoverable remote
    /// failures use durable per-scope backoff under the caller's task. The engine still has no
    /// automatic trigger in phase 05.9.
    ///
    /// - Throws: `ClientSyncEngineError.alreadySynchronizing` for an overlapping pass,
    ///   `CancellationError` when the caller cancels, or a remote, policy or persistence error.
    func synchronize() async throws {
        guard !isSynchronizing else {
            throw ClientSyncEngineError.alreadySynchronizing
        }
        isSynchronizing = true
        defer { isSynchronizing = false }

        let currentCursor = try await persistenceActor.cursor()
        try Task.checkCancellation()
        let remoteDataSource = remoteDataSource
        let batch = try await performWithRetry(scope: .pull) {
            try await remoteDataSource.fetchChanges(after: currentCursor)
        }
        try Task.checkCancellation()
        try await persistenceActor.reconcileRemoteBatch(
            batch,
            policy: syncPolicy,
            clearingRetryFor: .pull
        )
        await observationSignal.publishChange()

        let operations = try await persistenceActor
            .deliverablePendingOperations()
        var conflictedClientIDs: Set<UUID> = []
        for operation in operations {
            if conflictedClientIDs.contains(operation.clientID),
               case .upsert = operation {
                continue
            }
            try Task.checkCancellation()
            let retryScope = SyncRetryScope.operation(
                operation.operationID
            )
            let result = try await performWithRetry(scope: retryScope) {
                try await remoteDataSource.apply(operation)
            }
            try Task.checkCancellation()
            try await reconcilePushed(
                operation,
                result: result,
                clearingRetryFor: retryScope
            )
            if case .conflict = result {
                conflictedClientIDs.insert(operation.clientID)
            }
            await observationSignal.publishChange()
        }
    }

    private func reconcilePushed(
        _ operation: ClientPendingOperation,
        result: ClientRemoteMutationResult,
        clearingRetryFor retryScope: SyncRetryScope
    ) async throws {
        switch result {
        case .applied(let record), .alreadyApplied(let record):
            try await persistenceActor.acknowledge(
                operationID: operation.operationID,
                record: record,
                clearingRetryFor: retryScope
            )
        case .conflict(let reason, let remoteRecord):
            guard case .upsert(let upsert) = operation else {
                throw ClientSyncPersistenceError.entityIdentityMismatch
            }
            try await persistenceActor.recordConflict(
                operation: upsert,
                reason: reason,
                remoteRecord: remoteRecord,
                clearingRetryFor: retryScope
            )
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

                let remoteError = error as? ClientRemoteDataSourceError
                let classification = remoteError?.syncClassification
                    ?? .definitive
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

                    guard attempt < 3 else {
                        throw error
                    }
                    try await wait(until: nextState.notBefore)
                }
            }
        }

        throw ClientRemoteDataSourceError.unexpected
    }

    private func wait(until deadline: Date) async throws {
        let currentDate = await timing.now()
        let remaining = deadline.timeIntervalSince(currentDate)
        guard remaining.isFinite else {
            throw SyncRetryPolicyError.invalidDeadline
        }
        let boundedRemaining = min(max(remaining, 0), 60)
        guard boundedRemaining > 0 else { return }

        try Task.checkCancellation()
        try await timing.sleep(.seconds(boundedRemaining))
        try Task.checkCancellation()
    }
}

/// Failures owned by the Clients synchronization pass rather than its dependencies.
enum ClientSyncEngineError: Error, Equatable {
    case alreadySynchronizing
}
