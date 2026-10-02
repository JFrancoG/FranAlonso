import Foundation

/// Derives one immutable inverse per captured product line, never from current catalogue or prices.
struct SaleStockReversalPolicy {
    /// Reversal identity is conflict-relevant payload; event identity is unique to the original sale-line consumption.
    /// Professional services produce no movement. The effective void date is retained exactly.
    /// - Throws: Invalid lifecycle or conflicting reversal metadata; performs no I/O.
    func callAsFunction(sale: Sale, reversalID: SaleReversalID) throws -> [StockMovement] {
        guard case let .voided(paymentID, _, _, _, _, recordedID, date) = sale.status else {
            throw SaleError.invalidSaleTransition
        }
        guard recordedID == reversalID else { throw SaleError.conflictingReversal }
        return try sale.lines.compactMap { line in
            guard let productID = line.linkedProductID else { return nil }
            return try StockMovement(
                id: .saleReversal(saleID: sale.id, lineID: line.id),
                productID: productID,
                quantityDelta: line.quantity,
                reason: "sale-reversal",
                occurredAt: date,
                origin: .saleReversal(
                    saleID: sale.id,
                    lineID: line.id,
                    paymentID: paymentID,
                    reversalID: reversalID,
                    originalMovementID: .saleConsumption(saleID: sale.id, lineID: line.id)
                )
            )
        }
    }
}
