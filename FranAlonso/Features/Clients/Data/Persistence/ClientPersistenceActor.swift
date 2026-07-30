import Foundation
import SwiftData

/// Serializes Clients persistence on a SwiftData-owned model context.
///
/// Callers cross the actor boundary only with detached Domain snapshots or stable
/// Domain identifiers. Live persistent models and the actor's context remain isolated.
@ModelActor
actor ClientPersistenceActor {
    private let dataSource = ClientLocalDataSource()

    /// Fetches the current client snapshot ordered by display name.
    ///
    /// - Returns: Domain values detached from this actor's persistent context.
    /// - Throws: A SwiftData fetch error or a mapping error for invalid persisted data.
    func fetchAll() throws -> [Client] {
        try dataSource.fetchAll(in: modelContext)
    }

    /// Inserts or replaces a client by stable identity and saves the actor's context.
    ///
    /// - Parameter client: The detached Domain value to persist.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ client: Client) throws {
        try dataSource.upsert(client, in: modelContext)
    }

    /// Commits a client and one pending remote upsert on this actor's context.
    ///
    /// - Parameters:
    ///   - client: The detached Domain value to persist.
    ///   - operationID: The identifier assigned if the pending payload changes.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func persistPendingUpsert(
        _ client: Client,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingUpsert(
            client,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Removes the active client and commits one durable deletion operation.
    func persistPendingDelete(
        _ id: ClientID,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingDelete(
            id,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Returns the combined causal upsert and delete chain.
    func pendingOperations() throws -> [ClientPendingOperation] {
        try dataSource.pendingOperations(in: modelContext)
    }

    /// Returns immutable pending operations in deterministic causal order.
    func pendingUpserts() throws -> [ClientPendingUpsert] {
        try dataSource.pendingUpserts(in: modelContext)
    }

    /// Returns causal operations that are not held for explicit conflict resolution.
    func deliverablePendingUpserts() throws -> [ClientPendingUpsert] {
        try dataSource.deliverablePendingUpserts(in: modelContext)
    }

    /// Returns operations eligible for delivery under conflict and delete-wins policy.
    func deliverablePendingOperations() throws -> [ClientPendingOperation] {
        try dataSource.deliverablePendingOperations(in: modelContext)
    }

    /// Returns the durable incremental feed position, or nil before bootstrap.
    func cursor() throws -> ClientSyncCursor? {
        try dataSource.cursor(in: modelContext)
    }

    /// Returns the durable backoff schedule for one pull or pending operation.
    func retryState(
        for scope: SyncRetryScope
    ) throws -> SyncRetryState? {
        try dataSource.retryState(for: scope, in: modelContext)
    }

    /// Commits the next durable deadline after a recoverable remote failure.
    func saveRetryState(_ state: SyncRetryState) throws {
        try dataSource.saveRetryState(state, in: modelContext)
    }

    /// Clears obsolete transient backoff while retaining pending synchronization work.
    func clearRetryState(for scope: SyncRetryScope) throws {
        try dataSource.clearRetryState(for: scope, in: modelContext)
    }

    /// Applies a remote batch and advances its cursor in one isolated save boundary.
    func reconcileRemoteBatch(
        _ batch: ClientRemoteChangeBatch,
        policy: ClientSyncPolicy,
        clearingRetryFor retryScope: SyncRetryScope? = nil
    ) throws {
        try dataSource.reconcileRemoteBatch(
            batch,
            policy: policy,
            clearingRetryFor: retryScope,
            in: modelContext
        )
    }

    /// Persists one remote acknowledgement without overwriting newer local work.
    func acknowledge(
        operationID: UUID,
        record: ClientRemoteRecord,
        clearingRetryFor retryScope: SyncRetryScope? = nil
    ) throws {
        try dataSource.acknowledge(
            operationID: operationID,
            record: record,
            clearingRetryFor: retryScope,
            in: modelContext
        )
    }

    /// Records an authoritative remote observation while preserving pending work.
    func recordRemoteObservation(_ record: ClientRemoteRecord) throws {
        try dataSource.recordRemoteObservation(record, in: modelContext)
    }

    /// Persists both sides of a Clients conflict for later explicit resolution.
    func recordConflict(
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?,
        clearingRetryFor retryScope: SyncRetryScope? = nil
    ) throws {
        try dataSource.recordConflict(
            operation: operation,
            reason: reason,
            remoteRecord: remoteRecord,
            clearingRetryFor: retryScope,
            in: modelContext
        )
    }

    /// Deletes a client by stable identity and treats an absent client as success.
    ///
    /// - Parameter id: The Domain identifier to remove.
    /// - Throws: A SwiftData fetch or save error.
    func delete(_ id: ClientID) throws {
        try dataSource.delete(id, in: modelContext)
    }
}
