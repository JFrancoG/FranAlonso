import Foundation
import SwiftData

/// Persists UI-originated Sales mutations in their caller-owned main context.
///
/// The context remains an ephemeral operation parameter. Persistence, pending-operation
/// creation and idempotency reuse the same Data primitive as `DefaultSaleRepository`.
@MainActor
struct SaleContextualPersistenceAdapter {
    private let dataSource: SaleLocalDataSource
    private let observationSignal: SaleObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    /// Commits a sale and one pending upsert before invalidating local observation.
    ///
    /// - Parameters:
    ///   - sale: The validated Domain snapshot to persist.
    ///   - context: The main-actor context used for this operation only.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func save(_ sale: Sale, in context: ModelContext) async throws {
        try dataSource.persistPendingUpsert(
            sale,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
    }
}

extension SaleContextualPersistenceAdapter {
    /// Creates the contextual route over the shared local-write and observation roles.
    ///
    /// - Parameters:
    ///   - dataSource: The context-confined Sales persistence primitive.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        dataSource: SaleLocalDataSource = SaleLocalDataSource(),
        observationSignal: SaleObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            dataSource: dataSource,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
