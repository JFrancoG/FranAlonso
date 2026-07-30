import Foundation
import SwiftData

/// Serializes Services persistence on a SwiftData-owned model context.
///
/// Callers cross the actor boundary only with detached Domain snapshots or stable
/// Domain identifiers. Live persistent models and the actor's context remain isolated.
@ModelActor
actor ServicePersistenceActor {
    private let dataSource = ServiceLocalDataSource()

    /// Fetches the current service snapshot ordered by name.
    ///
    /// - Returns: Domain values detached from this actor's persistent context.
    /// - Throws: A SwiftData fetch error or a mapping error for invalid persisted data.
    func fetchAll() throws -> [Service] {
        try dataSource.fetchAll(in: modelContext)
    }

    /// Inserts or replaces a service by stable identity and saves the actor's context.
    ///
    /// - Parameter service: The detached Domain value to persist.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ service: Service) throws {
        try dataSource.upsert(service, in: modelContext)
    }

    /// Commits a service and one pending remote upsert on this actor's context.
    ///
    /// - Parameters:
    ///   - service: The detached Domain value to persist.
    ///   - operationID: The identifier assigned if the pending payload changes.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func persistPendingUpsert(
        _ service: Service,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingUpsert(
            service,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Removes the active service and commits one durable deletion operation.
    func persistPendingDelete(
        _ id: ServiceID,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingDelete(
            id,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Returns the combined causal upsert and delete chain.
    func pendingOperations() throws -> [ServicePendingOperation] {
        try dataSource.pendingOperations(in: modelContext)
    }

    /// Returns immutable pending operations in deterministic causal order.
    func pendingUpserts() throws -> [ServicePendingUpsert] {
        try dataSource.pendingUpserts(in: modelContext)
    }

    /// Returns causal operations that are not held for explicit conflict resolution.
    func deliverablePendingUpserts() throws -> [ServicePendingUpsert] {
        try dataSource.deliverablePendingUpserts(in: modelContext)
    }

    /// Returns operations eligible for delivery under conflict and delete-wins policy.
    func deliverablePendingOperations() throws -> [ServicePendingOperation] {
        try dataSource.deliverablePendingOperations(in: modelContext)
    }

    /// Returns the durable incremental feed position, or nil before bootstrap.
    func cursor() throws -> ServiceSyncCursor? {
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
        _ batch: ServiceRemoteChangeBatch,
        policy: ServiceSyncPolicy,
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
        record: ServiceRemoteRecord,
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
    func recordRemoteObservation(_ record: ServiceRemoteRecord) throws {
        try dataSource.recordRemoteObservation(record, in: modelContext)
    }

    /// Persists both sides of a Services conflict for later explicit resolution.
    func recordConflict(
        operation: ServicePendingUpsert,
        reason: ServiceSyncConflictReason,
        remoteRecord: ServiceRemoteRecord?,
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

    /// Deletes a service by stable identity and treats an absent service as success.
    ///
    /// - Parameter id: The Domain identifier to remove.
    /// - Throws: A SwiftData fetch or save error.
    func delete(_ id: ServiceID) throws {
        try dataSource.delete(id, in: modelContext)
    }
}
