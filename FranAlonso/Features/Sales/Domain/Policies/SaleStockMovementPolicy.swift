import Foundation

/// Prepares immutable original consumption from captured sale terms without consulting inventory or the catalogue.
struct SaleStockMovementPolicy {
    /// Requires the recorded payment identity and retains its original date after document/void transitions.
    /// Professional services are omitted; each product-linked line keeps a separate negative unit delta.
    /// - Throws: Sale lifecycle/payment rejection or invalid movement construction; performs no persistence.
    func callAsFunction(sale: Sale, paymentID: PaymentID) throws -> [StockMovement] {
        let recordedID: PaymentID
        let paidAt: Date
        switch sale.status {
        case let .awaitingDocument(id, _, date), let .closed(id, _, date, _, _),
             let .voided(id, _, date, _, _, _, _):
            recordedID = id
            paidAt = date
        case .draft, .inProgress, .awaitingPayment:
            throw SaleError.invalidSaleTransition
        }
        guard recordedID == paymentID else { throw SaleError.conflictingPayment }
        return try sale.lines.compactMap { line in
            guard let productID = line.linkedProductID else { return nil }
            return try StockMovement(
                id: .saleConsumption(saleID: sale.id, lineID: line.id),
                productID: productID,
                quantityDelta: -line.quantity,
                reason: "sale-payment",
                occurredAt: paidAt,
                origin: .sale(saleID: sale.id, lineID: line.id, paymentID: paymentID)
            )
        }
    }
}
