/// Atomically advances a future billing-sequence head and records immutable administrative acceptance.
///
/// Administrative authority is an injected capability. The request does not grant a role or
/// identify its actor. Existing documents, number bindings and historical business data remain intact.
/// An identical command and authorized principal replay its original receipt without further writes.
/// Reusing its identity with different content or a different principal conflicts.
///
/// Failure or cancellation may follow remote acceptance. The caller retains the complete request
/// and retries explicitly with current administrative authority; neither outcome proves rollback.
protocol BillingSeriesAdjustmentRepository: Sendable {
    func adjust(_ request: BillingSeriesAdjustmentRequest) async throws -> BillingSeriesAdjustmentReceipt
}
