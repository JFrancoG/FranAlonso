import Foundation
import SwiftData

/// Serializes Products persistence on a SwiftData-owned model context.
///
/// Callers cross the actor boundary only with detached Domain snapshots or stable
/// Domain identifiers. Live persistent models and the actor's context remain isolated.
@ModelActor
actor ProductPersistenceActor {
    private let dataSource = ProductLocalDataSource()

    /// Fetches the current product snapshot ordered by name.
    ///
    /// - Returns: Domain values detached from this actor's persistent context.
    /// - Throws: A SwiftData fetch error or a mapping error for invalid persisted data.
    func fetchAll() throws -> [Product] {
        try dataSource.fetchAll(in: modelContext)
    }

    /// Inserts or replaces a product by stable identity and saves the actor's context.
    ///
    /// - Parameter product: The detached Domain value to persist.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ product: Product) throws {
        try dataSource.upsert(product, in: modelContext)
    }

    /// Commits a product and one pending remote upsert on this actor's context.
    ///
    /// - Parameters:
    ///   - product: The detached Domain value to persist.
    ///   - operationID: The identifier assigned if the pending payload changes.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func persistPendingUpsert(
        _ product: Product,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingUpsert(
            product,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Removes the active product and commits one durable deletion operation.
    func persistPendingDelete(
        _ id: ProductID,
        operationID: UUID
    ) throws {
        try dataSource.persistPendingDelete(
            id,
            operationID: operationID,
            in: modelContext
        )
    }

    /// Returns the combined causal upsert and delete chain.
    func pendingOperations() throws -> [ProductPendingOperation] {
        try dataSource.pendingOperations(in: modelContext)
    }

    /// Returns immutable pending operations in deterministic causal order.
    func pendingUpserts() throws -> [ProductPendingUpsert] {
        try dataSource.pendingUpserts(in: modelContext)
    }

    /// Returns causal operations that are not held for explicit conflict resolution.
    func deliverablePendingUpserts() throws -> [ProductPendingUpsert] {
        try dataSource.deliverablePendingUpserts(in: modelContext)
    }

    /// Returns operations eligible for delivery under conflict and delete-wins policy.
    func deliverablePendingOperations() throws -> [ProductPendingOperation] {
        try dataSource.deliverablePendingOperations(in: modelContext)
    }

    /// Returns the durable incremental feed position, or nil before bootstrap.
    func cursor() throws -> ProductSyncCursor? {
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
        _ batch: ProductRemoteChangeBatch,
        policy: ProductSyncPolicy,
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
        record: ProductRemoteRecord,
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
    func recordRemoteObservation(_ record: ProductRemoteRecord) throws {
        try dataSource.recordRemoteObservation(record, in: modelContext)
    }

    /// Persists both sides of a Products conflict for later explicit resolution.
    func recordConflict(
        operation: ProductPendingUpsert,
        reason: ProductSyncConflictReason,
        remoteRecord: ProductRemoteRecord?,
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

    /// Deletes a product by stable identity and treats an absent product as success.
    ///
    /// - Parameter id: The Domain identifier to remove.
    /// - Throws: A SwiftData fetch or save error.
    func delete(_ id: ProductID) throws {
        try dataSource.delete(id, in: modelContext)
    }
}
