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
        try dataSource.persistPendingUpsert(
            service,
            operationID: makeOperationID(),
            in: context
        )
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
        self.init(
            dataSource: dataSource,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
