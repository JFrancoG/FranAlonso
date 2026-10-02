import Foundation

/// Access to sale snapshots materialized by the local source of truth.
protocol SaleRepository: Sendable {
    /// Accepts a closed sale and its inverse stock events atomically; exact replay never rewrites original history.
    /// Caller retains reversal ID/date. Validation and commit do not suspend; no independent-context CAS.
    /// - Throws: Reversal/lifecycle rejection or cancellation before local acceptance.
    func voidSale(_ expected: Sale, reversalID: SaleReversalID, voidedAt: Date) async throws -> Sale
    /// Accepts one work transition against the expected snapshot, with write-free exact replay.
    /// Validation/commit share one context without suspension; no independent-context CAS is promised.
    func advanceSale(_ expected: Sale, action: SaleProgressAction) async throws -> Sale
    /// Requests an observation stream backed by locally materialized sale snapshots.
    ///
    /// - Returns: A stream backed by locally materialized sale values.
    func observeSales() async -> AsyncThrowingStream<[Sale], any Error>

    /// Persists a sale through the local-first repository boundary.
    ///
    /// Successful completion means the local source accepted the snapshot;
    /// remote convergence may continue independently.
    ///
    /// - Parameter sale: The validated sale snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func saveSale(_ sale: Sale) async throws

    /// Reads the local snapshot without exposing discarded identities; absence returns nil.
    /// - Throws: `SaleDraftError.persistenceUnavailable` or cancellation before reading.
    func sale(id: SaleID) async throws -> Sale?

    /// Creates a draft without reusing any materialized, pending, remote, or discarded identity.
    /// Successful completion means local acceptance, without waiting for remote synchronization.
    /// - Throws: `SaleDraftError` for rejection, or cancellation before acceptance.
    func createDraft(_ draft: Sale) async throws

    /// Replaces a matching local draft, preserving identity, creation and retained service terms.
    ///
    /// Checks and persistence share one context without suspension. Snapshot equality detects
    /// obsolete copies visible in that context; this is not CAS across independent contexts.
    /// - Throws: `SaleDraftError`, `SaleError` for invalid lines, or cancellation before acceptance.
    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale

    /// Accepts payment and captured stock consumptions atomically in the local source.
    /// Never overwrites an obsolete commercial snapshot.
    /// Exact replay preserves later metadata and repairs missing consumptions without another sale operation.
    /// Checks and persistence do not suspend in the owning context; not cross-context CAS.
    /// - Throws: `SalePaymentError`, `SaleError`, or cancellation before acceptance.
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale

    /// Discards only a draft through the existing durable tombstone path.
    /// Absence and repetition are no-ops; conflicts and progressed sales are retained.
    /// - Throws: `SaleDraftError` for rejection, or cancellation before acceptance.
    func discardDraft(_ id: SaleID) async throws
}

extension SaleRepository {
    /// Repositories without compensating acceptance fail closed instead of saving an unrestricted voided snapshot.
    func voidSale(_ expected: Sale, reversalID: SaleReversalID, voidedAt: Date) async throws -> Sale {
        throw SaleReversalError.persistenceUnavailable
    }
    /// Repositories without a work-acceptance capability fail closed rather than save unrestricted snapshots.
    func advanceSale(_ expected: Sale, action: SaleProgressAction) async throws -> Sale {
        throw SaleProgressError.persistenceUnavailable
    }
    /// Replaces client and lines while preserving the expected sale's global term.
    func updateDraft(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        try await updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: expected.globalDiscount
        )
    }
}
