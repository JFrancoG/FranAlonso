/// Analyzes physical inventory consumption from immutable sale-line and stock snapshots.
///
/// This synchronous operation performs no I/O and never reserves or changes inventory.
/// Stock warnings are advisory; callers must refresh their input snapshots before confirmation.
struct AnalyzeSaleStockImpactUseCase {
    /// Returns one impact per product-linked line in input order, accumulating repeated product consumption.
    ///
    /// Lines without a product link are omitted regardless of their execution state.
    /// Exact depletion is sufficient; negative projections carry a nonblocking warning.
    ///
    /// - Parameters:
    ///   - lines: Sale-owned service snapshots in display order, with unique line identities.
    ///   - availableQuantities: Current stock for every linked product; missing values are not treated as zero.
    /// - Throws: `StockWarningPolicyError` for duplicate line identities, missing stock or integer overflow.
    func callAsFunction(lines: [SaleLine], availableQuantities: [ProductID: Int]) throws -> [StockImpact] {
        try StockWarningPolicy().analyze(lines: lines, availableQuantities: availableQuantities)
    }
}
