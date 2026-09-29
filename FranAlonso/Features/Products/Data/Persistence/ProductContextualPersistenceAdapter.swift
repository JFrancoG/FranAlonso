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
        try dataSource.persistPendingUpsert(product, operationID: makeOperationID(), in: context)
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
        self.init(dataSource: dataSource, observationSignal: observationSignal, makeOperationID: operationID)
    }
}

extension ProductContextualPersistenceAdapter {
    /// Creates a locally accepted active profile and publishes only after its causal operation commits.
    /// The caller's context remains ephemeral; errors are neutral Domain failures or prior cancellation.
    func create(id: ProductID, profile: ProductProfile, in context: ModelContext) async throws -> Product {
        let product = try dataSource.createProduct(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return product
    }

    /// Edits metadata through the shared acceptance primitive, preserving current availability.
    func update(id: ProductID, profile: ProductProfile, in context: ModelContext) async throws -> Product {
        let product = try dataSource.updateProduct(
            id: id,
            profile: profile,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return product
    }

    /// Retains the profile as inactive; repeating the command neither writes nor publishes a mutation.
    func deactivate(_ id: ProductID, in context: ModelContext) async throws {
        let changed = try dataSource.deactivateProduct(id, operationID: makeOperationID(), in: context)
        guard changed else { return }
        await observationSignal.publishChange()
    }
}
