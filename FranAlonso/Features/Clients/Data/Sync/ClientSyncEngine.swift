/// Reconciles the durable Clients operation chain with the provider-neutral remote source.
actor ClientSyncEngine {
    private let persistenceActor: ClientPersistenceActor
    private let remoteDataSource: any ClientRemoteDataSource
    private let observationSignal: ClientObservationSignal
    private let policy: ClientSyncPolicy

    /// Creates the first Clients engine from isolated local and replaceable remote roles.
    init(
        persistenceActor: ClientPersistenceActor,
        remoteDataSource: any ClientRemoteDataSource,
        observationSignal: ClientObservationSignal,
        policy: ClientSyncPolicy = ClientSyncPolicy()
    ) {
        self.persistenceActor = persistenceActor
        self.remoteDataSource = remoteDataSource
        self.observationSignal = observationSignal
        self.policy = policy
    }

    /// Performs one explicit pull and causal push pass.
    ///
    /// The engine has no automatic trigger in phase 05.7. Repetition is safe: remote
    /// acknowledgements remove only their exact immutable operation and local observation is
    /// invalidated only after the complete pass succeeds.
    func synchronize() async throws {
        let remoteRecords = try await remoteDataSource.fetchAll()
        for record in remoteRecords.sorted(by: { $0.id < $1.id }) {
            try Task.checkCancellation()
            try await reconcilePulled(record)
        }

        let operations = try await persistenceActor.deliverablePendingUpserts()
        for operation in operations {
            try Task.checkCancellation()
            let result = try await remoteDataSource.upsert(operation)
            try await reconcilePushed(
                operation,
                result: result
            )
        }

        await observationSignal.publishChange()
    }

    private func reconcilePulled(_ record: ClientRemoteRecord) async throws {
        let clientID = try record.client.stableUUID()
        let pendingOperations = try await persistenceActor.pendingUpserts()
        let operation = pendingOperations.first {
            $0.clientID == clientID
        }
        guard let operation else {
            try await persistenceActor.recordRemoteObservation(record)
            return
        }

        switch policy.decision(for: operation, against: record) {
        case .apply:
            try await persistenceActor.recordRemoteObservation(record)
        case .alreadyApplied(let acknowledgedRecord):
            try await persistenceActor.acknowledge(
                operationID: operation.operationID,
                record: acknowledgedRecord
            )
        case .conflict(let reason, let remoteRecord):
            try await persistenceActor.recordConflict(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord
            )
        case .invalid(let error):
            throw error
        }
    }

    private func reconcilePushed(
        _ operation: ClientPendingUpsert,
        result: ClientRemoteUpsertResult
    ) async throws {
        switch result {
        case .applied(let record), .alreadyApplied(let record):
            try await persistenceActor.acknowledge(
                operationID: operation.operationID,
                record: record
            )
        case .conflict(let reason, let remoteRecord):
            try await persistenceActor.recordConflict(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord
            )
        }
    }
}
