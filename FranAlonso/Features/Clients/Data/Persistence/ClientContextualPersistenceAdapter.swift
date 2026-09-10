import Foundation
import SwiftData

/// Persists UI-originated Clients mutations in their caller-owned main context.
///
/// The context remains an ephemeral operation parameter. Persistence, pending-operation
/// creation and idempotency reuse the same Data primitive as `DefaultClientRepository`.
@MainActor
struct ClientContextualPersistenceAdapter {
    private let dataSource: ClientLocalDataSource
    private let observationSignal: ClientObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    /// Commits a client and one pending upsert before invalidating local observation.
    ///
    /// - Parameters:
    ///   - client: The validated Domain snapshot to persist.
    ///   - context: The main-actor context used for this operation only.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func save(_ client: Client, in context: ModelContext) async throws {
        try dataSource.persistPendingUpsert(client, operationID: makeOperationID(), in: context)
        await observationSignal.publishChange()
    }

    /// Creates a draft using the caller's ephemeral context and publishes only after durable acceptance.
    func create(id: ClientID, profile: ClientProfile, in context: ModelContext) async throws -> Client {
        let client = try dataSource.createClient(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return client
    }

    /// Updates editable fields while preserving the profile's current consent and activation state.
    func update(id: ClientID, profile: ClientProfile, in context: ModelContext) async throws -> Client {
        let client = try dataSource.updateClient(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return client
    }

    /// Hides a known profile through the same tombstone primitive used by the repository.
    func deactivate(_ id: ClientID, in context: ModelContext) async throws {
        try dataSource.deactivateClient(id, operationID: makeOperationID(), in: context)
        await observationSignal.publishChange()
    }
}

extension ClientContextualPersistenceAdapter {
    /// Creates the contextual route over the shared local-write and observation roles.
    ///
    /// - Parameters:
    ///   - dataSource: The context-confined Clients persistence primitive.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        dataSource: ClientLocalDataSource = ClientLocalDataSource(),
        observationSignal: ClientObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(dataSource: dataSource, observationSignal: observationSignal, makeOperationID: operationID)
    }
}
