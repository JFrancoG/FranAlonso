import Foundation
import SwiftData

/// Persists UI-originated Products mutations in their caller-owned main context.
///
/// The context remains an ephemeral operation parameter. Persistence, pending-operation
/// creation and idempotency reuse the same Data primitive as `DefaultProductRepository`.
@MainActor
struct ProductContextualPersistenceAdapter {
    private let dataSource: ProductLocalDataSource
    private let observationSignal: ProductObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    /// Commits a product and one pending upsert before invalidating local observation.
    ///
    /// - Parameters:
    ///   - product: The validated Domain snapshot to persist.
    ///   - context: The main-actor context used for this operation only.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func save(_ product: Product, in context: ModelContext) async throws {
        try dataSource.persistPendingUpsert(
            product,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
    }
}

extension ProductContextualPersistenceAdapter {
    /// Creates the contextual route over the shared local-write and observation roles.
    ///
    /// - Parameters:
    ///   - dataSource: The context-confined Products persistence primitive.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        dataSource: ProductLocalDataSource = ProductLocalDataSource(),
        observationSignal: ProductObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            dataSource: dataSource,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
