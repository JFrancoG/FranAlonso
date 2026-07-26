import Foundation

/// Reconciles the durable Clients operation chain with the provider-neutral remote source.
actor ClientSyncEngine {
    private let persistenceActor: ClientPersistenceActor
    private let remoteDataSource: any ClientRemoteDataSource
    private let observationSignal: any ClientChangeSignaling
    private let policy: ClientSyncPolicy

    /// Creates the Clients engine from isolated local and replaceable remote roles.
    init(
        persistenceActor: ClientPersistenceActor,
        remoteDataSource: any ClientRemoteDataSource,
        observationSignal: any ClientChangeSignaling,
        policy: ClientSyncPolicy = ClientSyncPolicy()
    ) {
        self.persistenceActor = persistenceActor
        self.remoteDataSource = remoteDataSource
        self.observationSignal = observationSignal
        self.policy = policy
    }

    /// Performs one explicit incremental pull and causal push pass.
    ///
    /// The pulled batch and cursor commit atomically before any push begins. Its observation
    /// signal is therefore published even when a later remote push fails. The engine still
    /// has no automatic trigger in phase 05.8.
    func synchronize() async throws {
        let currentCursor = try await persistenceActor.cursor()
        let batch = try await remoteDataSource.fetchChanges(
            after: currentCursor
        )
        try await persistenceActor.reconcileRemoteBatch(
            batch,
            policy: policy
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
            let result = try await remoteDataSource.apply(operation)
            try await reconcilePushed(operation, result: result)
            if case .conflict = result {
                conflictedClientIDs.insert(operation.clientID)
            }
            await observationSignal.publishChange()
        }
    }

    private func reconcilePushed(
        _ operation: ClientPendingOperation,
        result: ClientRemoteMutationResult
    ) async throws {
        switch result {
        case .applied(let record), .alreadyApplied(let record):
            try await persistenceActor.acknowledge(
                operationID: operation.operationID,
                record: record
            )
        case .conflict(let reason, let remoteRecord):
            guard case .upsert(let upsert) = operation else {
                throw ClientSyncPersistenceError.entityIdentityMismatch
            }
            try await persistenceActor.recordConflict(
                operation: upsert,
                reason: reason,
                remoteRecord: remoteRecord
            )
        }
    }
}
