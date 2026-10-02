import SwiftData

/// Serializes stock operations through one context with explicit saves and no automatic acceptance.
/// Composition shares one writer; independent writers or processes are outside this atomicity contract.
@ModelActor
actor StockPersistenceActor {
    private let dataSource = StockLocalDataSource()
    private let syncDataSource = StockSyncLocalDataSource()

    /// Commits or deduplicates an event without a suspension inside its acceptance boundary.
    func append(_ movement: StockMovement) throws -> StockMovement {
        modelContext.autosaveEnabled = false
        return try dataSource.append(movement, in: modelContext)
    }

    /// Returns detached accepted history by stable identity.
    func movement(id: StockMovementID) throws -> StockMovement? {
        modelContext.autosaveEnabled = false
        return try dataSource.movement(id: id, in: modelContext)
    }

    /// Returns a checked sum of accepted deltas for a present Product.
    func quantity(for productID: ProductID) throws -> Int {
        modelContext.autosaveEnabled = false
        return try dataSource.quantity(for: productID, in: modelContext)
    }
}

extension StockPersistenceActor {
    /// Commits feed acceptance and its cursor without suspension inside the writer.
    func reconcileRemoteBatch(_ batch: StockRemoteChangeBatch) throws {
        modelContext.autosaveEnabled = false
        try syncDataSource.reconcile(batch, in: modelContext)
    }

    /// Returns detached events excluding durable acknowledgements and divergent identities.
    func deliverablePendingMovements() throws -> [StockMovement] {
        try syncDataSource.pending(in: modelContext)
    }

    /// Accepts full transport equivalence and clears operation retry in the same save.
    func acknowledge(_ movement: StockMovement, record: StockRemoteRecord) throws {
        modelContext.autosaveEnabled = false
        try syncDataSource.acknowledge(movement, record: record, in: modelContext)
    }

    /// Retains both original snapshots and blocks only this identity from future pushes.
    func recordConflict(_ movement: StockMovement, remote: StockRemoteRecord) throws {
        modelContext.autosaveEnabled = false
        try syncDataSource.recordConflict(movement, remote: remote, in: modelContext)
    }

    func cursor() throws -> StockSyncCursor? {
        try syncDataSource.cursor(in: modelContext)
    }

    func syncConflicts() throws -> [StockSyncConflict] {
        try syncDataSource.conflicts(in: modelContext)
    }

    func retryState(for scope: SyncRetryScope) throws -> SyncRetryState? {
        try syncDataSource.retryState(for: scope, in: modelContext)
    }

    /// Persists a feature-owned retry deadline under this writer without automatic scheduling.
    func saveRetryState(_ state: SyncRetryState) throws {
        modelContext.autosaveEnabled = false
        try syncDataSource.persistRetry(state, in: modelContext)
    }

    /// Removes definitive-failure scheduling; pending business events remain unchanged.
    func clearRetryState(for scope: SyncRetryScope) throws {
        modelContext.autosaveEnabled = false
        try syncDataSource.clearRetry(scope, in: modelContext)
    }
}
