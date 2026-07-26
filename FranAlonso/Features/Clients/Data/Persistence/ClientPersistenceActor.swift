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

    /// Returns immutable pending operations in deterministic causal order.
    func pendingUpserts() throws -> [ClientPendingUpsert] {
        try dataSource.pendingUpserts(in: modelContext)
    }

    /// Returns causal operations that are not held for explicit conflict resolution.
    func deliverablePendingUpserts() throws -> [ClientPendingUpsert] {
        try dataSource.deliverablePendingUpserts(in: modelContext)
    }

    /// Persists one remote acknowledgement without overwriting newer local work.
    func acknowledge(
        operationID: UUID,
        record: ClientRemoteRecord
    ) throws {
        try dataSource.acknowledge(
            operationID: operationID,
            record: record,
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
        remoteRecord: ClientRemoteRecord?
    ) throws {
        try dataSource.recordConflict(
            operation: operation,
            reason: reason,
            remoteRecord: remoteRecord,
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
