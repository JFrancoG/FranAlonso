import Foundation

/// Accepts a captured paid sale only against its correlated confirmed document and retained final PDF.
struct SaleClosureAcceptancePolicy {
    /// Initial acceptance requires exact current terms and payment; replay preserves later closure and void metadata.
    /// Upload receipt and manual mail are independent of operational closure.
    /// - Throws: A neutral closure rejection without exposing document or principal payloads.
    func callAsFunction(
        _ request: SaleClosureRequest,
        current: Sale,
        delivery: BillingDocumentDelivery,
        principalID: String
    ) throws -> Sale {
        guard !principalID.isEmpty, delivery.principalID == principalID else { throw SaleClosureError.unauthorized }
        guard delivery.id == request.requestID, delivery.request.saleID == request.expected.id else {
            throw SaleClosureError.conflictingDocument
        }
        guard let document = delivery.document, delivery.pdf != nil else { throw SaleClosureError.documentPending }
        guard document.request == delivery.request else { throw SaleClosureError.conflictingDocument }
        let expected = request.expected
        guard sameCommercialSnapshot(expected, current), sameCommercialSnapshot(expected, delivery.request.sale),
              let expectedPayment = payment(of: expected), expectedPayment == payment(of: current),
              expectedPayment == payment(of: delivery.request.sale) else {
            throw SaleClosureError.staleSale
        }
        switch expected.status {
        case let .closed(_, _, _, expectedDocumentID, expectedClosedAt),
             let .voided(_, _, _, expectedDocumentID, expectedClosedAt, _, _):
            guard expectedDocumentID == document.id else { throw SaleClosureError.conflictingDocument }
            guard SalesHistoryPolicy().closureDate(of: current) == expectedClosedAt else {
                throw SaleClosureError.staleSale
            }
        case .awaitingDocument:
            break
        case .draft, .inProgress, .awaitingPayment:
            throw SaleClosureError.requiresPayment
        }
        switch current.status {
        case .awaitingDocument:
            guard current == expected else { throw SaleClosureError.staleSale }
            var accepted = current
            try accepted.close(documentID: document.id, closedAt: request.closedAt)
            return accepted
        case let .closed(_, _, _, documentID, _), let .voided(_, _, _, documentID, _, _, _):
            guard documentID == document.id else { throw SaleClosureError.conflictingDocument }
            return current
        case .draft, .inProgress, .awaitingPayment:
            throw SaleClosureError.staleSale
        }
    }
}

private extension SaleClosureAcceptancePolicy {
    func sameCommercialSnapshot(_ first: Sale, _ second: Sale) -> Bool {
        first.id == second.id && first.clientID == second.clientID && first.createdAt == second.createdAt
            && first.lines == second.lines && first.globalDiscount == second.globalDiscount
    }

    func payment(of sale: Sale) -> SaleClosurePayment? {
        switch sale.status {
        case let .awaitingDocument(id, method, paidAt), let .closed(id, method, paidAt, _, _),
             let .voided(id, method, paidAt, _, _, _, _):
            SaleClosurePayment(id: id, method: method, paidAt: paidAt)
        case .draft, .inProgress, .awaitingPayment:
            nil
        }
    }
}

private struct SaleClosurePayment: Equatable {
    let id: PaymentID
    let method: PaymentMethod
    let paidAt: Date
}
