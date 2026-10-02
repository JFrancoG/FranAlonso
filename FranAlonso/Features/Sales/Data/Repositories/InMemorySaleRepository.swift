import Foundation
/// An actor-isolated Sales repository for previews and deterministic tests.
actor InMemorySaleRepository: SaleRepository {
    func advanceSale(_ expected: Sale, action: SaleProgressAction) throws -> Sale {
        try Task.checkCancellation()
        guard let index = sales.firstIndex(where: { $0.id == expected.id }) else {
            throw knownIDs.contains(expected.id) ? SaleProgressError.deleted : .notFound
        }
        let accepted = try SaleProgressAcceptancePolicy()(expected: expected, current: sales[index], action: action)
        sales[index] = accepted
        return accepted
    }
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        try Task.checkCancellation()
        guard let index = sales.firstIndex(where: { $0.id == expected.id }) else {
            throw knownIDs.contains(expected.id) ? SalePaymentError.deleted : .notFound
        }
        let accepted = try SalePaymentAcceptancePolicy()(
            expected: expected,
            current: sales[index],
            id: paymentID,
            method: method,
            paidAt: paidAt
        )
        sales[index] = accepted
        return accepted
    }

    private var sales: [Sale]
    private var knownIDs: Set<SaleID>

    init(sales: [Sale] = []) {
        self.sales = sales
        knownIDs = Set(sales.map(\.id))
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(sales)
            continuation.finish()
        }
    }

    /// Inserts a sale or replaces the snapshot with the same stable identity.
    func saveSale(_ sale: Sale) async throws {
        knownIDs.insert(sale.id)
        if let index = sales.firstIndex(where: { $0.id == sale.id }) {
            sales[index] = sale
        } else {
            sales.append(sale)
        }
    }

    func sale(id: SaleID) async throws -> Sale? {
        try Task.checkCancellation()
        return sales.first { $0.id == id }
    }

    func createDraft(_ draft: Sale) async throws {
        try Task.checkCancellation()
        guard draft.status == .draft else { throw SaleDraftError.requiresDraft }
        guard !knownIDs.contains(draft.id) else { throw SaleDraftError.alreadyExists }
        knownIDs.insert(draft.id)
        sales.append(draft)
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        try Task.checkCancellation()
        guard let index = sales.firstIndex(where: { $0.id == expected.id }) else {
            throw knownIDs.contains(expected.id) ? SaleDraftError.deleted : .notFound
        }
        let existing = sales[index]
        guard existing.status == .draft else { throw SaleDraftError.requiresDraft }
        guard existing == expected else { throw SaleDraftError.staleDraft }
        let draft = try existing.replacingDraft(clientID: clientID, lines: lines, globalDiscount: globalDiscount)
        sales[index] = draft
        return draft
    }

    func discardDraft(_ id: SaleID) async throws {
        try Task.checkCancellation()
        guard let index = sales.firstIndex(where: { $0.id == id }) else { return }
        guard sales[index].status == .draft else { throw SaleDraftError.requiresDraft }
        sales.remove(at: index)
    }
}
