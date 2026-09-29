import Foundation
import SwiftData

/// Persists UI-originated Services mutations in their caller-owned main context.
///
/// The context remains an ephemeral operation parameter. Persistence, pending-operation
/// creation and idempotency reuse the same Data primitive as `DefaultServiceRepository`.
@MainActor
struct ServiceContextualPersistenceAdapter {
    private let dataSource: ServiceLocalDataSource
    private let observationSignal: ServiceObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    /// Commits a service and one pending upsert before invalidating local observation.
    ///
    /// - Parameters:
    ///   - service: The validated Domain snapshot to persist.
    ///   - context: The main-actor context used for this operation only.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func save(_ service: Service, in context: ModelContext) async throws {
        try dataSource.persistPendingUpsert(service, operationID: makeOperationID(), in: context)
        await observationSignal.publishChange()
    }
}

extension ServiceContextualPersistenceAdapter {
    /// Creates the contextual route over the shared local-write and observation roles.
    ///
    /// - Parameters:
    ///   - dataSource: The context-confined Services persistence primitive.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        dataSource: ServiceLocalDataSource = ServiceLocalDataSource(),
        observationSignal: ServiceObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(dataSource: dataSource, observationSignal: observationSignal, makeOperationID: operationID)
    }
}

extension ServiceContextualPersistenceAdapter {
    /// Creates a locally accepted active profile and publishes only after its causal operation commits.
    /// The caller's context remains ephemeral; errors are neutral Domain failures or prior cancellation.
    func create(id: ServiceID, profile: ServiceProfile, in context: ModelContext) async throws -> Service {
        let service = try dataSource.createService(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return service
    }

    /// Edits the commercial profile through the shared acceptance primitive, preserving current availability.
    func update(id: ServiceID, profile: ServiceProfile, in context: ModelContext) async throws -> Service {
        let service = try dataSource.updateService(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return service
    }

    /// Retains the profile as inactive; repeating the command neither writes nor publishes a mutation.
    func deactivate(_ id: ServiceID, in context: ModelContext) async throws {
        let changed = try dataSource.deactivateService(id, operationID: makeOperationID(), in: context)
        guard changed else { return }
        await observationSignal.publishChange()
    }
}
