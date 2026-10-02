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

    /// Accepts a new draft in the ephemeral caller context before invalidating observation.
    /// Uses the same draft checks and causal write primitive as the context-free repository.
    /// - Throws: `SaleDraftError` or cancellation before acceptance; does not retain the context.
    func createDraft(_ draft: Sale, in context: ModelContext) async throws {
        try dataSource.createDraft(draft, operationID: makeOperationID(), in: context)
        await observationSignal.publishChange()
    }

    /// Replaces a matching draft in the caller context and returns the accepted snapshot.
    /// Preserves identity, creation and retained terms, without cross-context CAS guarantees.
    /// - Throws: `SaleDraftError`, `SaleError`, or cancellation before acceptance.
    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        in context: ModelContext
    ) async throws -> Sale {
        try await updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: expected.globalDiscount,
            in: context
        )
    }

    /// Accepts a complete commercial draft candidate, including explicit global removal.
    /// - Throws: `SaleDraftError`, `SaleError`, or cancellation before acceptance.
    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?,
        in context: ModelContext
    ) async throws -> Sale {
        let draft = try dataSource.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return draft
    }

    /// Discards an unconflicted draft and publishes only after local acceptance.
    /// Progressed sales remain intact; repetition and absence keep the existing pending identity.
    /// - Throws: `SaleDraftError` or cancellation before acceptance.
    func discardDraft(_ id: SaleID, in context: ModelContext) async throws {
        try dataSource.discardDraft(id, operationID: makeOperationID(), in: context)
        await observationSignal.publishChange()
    }

    /// Commits a sale and one pending upsert before invalidating local observation.
    ///
    /// - Parameters:
    ///   - sale: The validated Domain snapshot to persist.
    ///   - context: The main-actor context used for this operation only.
    /// - Throws: A mapping, encoding, SwiftData fetch or SwiftData save error.
    func save(_ sale: Sale, in context: ModelContext) async throws {
        try dataSource.persistPendingUpsert(sale, operationID: makeOperationID(), in: context)
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
        self.init(dataSource: dataSource, observationSignal: observationSignal, makeOperationID: operationID)
    }
}
