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
    private let productObservationSignal: any ProductChangeSignaling
    private let makeOperationID: @Sendable () -> UUID

    /// Accepts closure in the ephemeral main context, then invalidates the same locally observed Sales source.
    /// The capability-owning caller checks its shell authorization before and after this contextual operation.
    func closeSale(_ request: SaleClosureRequest, principalID: String, in context: ModelContext) async throws -> Sale {
        let accepted = try dataSource.closeSale(
            request,
            principalID: principalID,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        return accepted
    }

    /// Accepts void and stock in the ephemeral caller context, then invalidates both observed sources.
    /// Cancellation after commit does not undo acceptance; the context is never stored or sent across actors.
    func voidSale(
        _ expected: Sale,
        reversalID: SaleReversalID,
        voidedAt: Date,
        in context: ModelContext
    ) async throws -> Sale {
        let accepted = try dataSource.voidSale(
            expected,
            reversalID: reversalID,
            voidedAt: voidedAt,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        await productObservationSignal.publishChange()
        return accepted
    }

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

    /// Accepts a stable payment in the ephemeral caller context before publishing.
    /// Exact replay retains later lifecycle metadata; cancellation after commit does not undo acceptance.
    /// - Throws: `SalePaymentError`, `SaleError`, or cancellation before acceptance.
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date,
        in context: ModelContext
    ) async throws -> Sale {
        let accepted = try dataSource.registerPayment(
            expected,
            id: paymentID,
            method: method,
            paidAt: paidAt,
            operationID: makeOperationID(),
            in: context
        )
        await observationSignal.publishChange()
        await productObservationSignal.publishChange()
        return accepted
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
    ///   - productObservationSignal: Invalidates stock readers after atomic payment acceptance.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        dataSource: SaleLocalDataSource = SaleLocalDataSource(),
        observationSignal: SaleObservationSignal,
        productObservationSignal: any ProductChangeSignaling = ProductObservationSignal(),
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            dataSource: dataSource,
            observationSignal: observationSignal,
            productObservationSignal: productObservationSignal,
            makeOperationID: operationID
        )
    }
}
