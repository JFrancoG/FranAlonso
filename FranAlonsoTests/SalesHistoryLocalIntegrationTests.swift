import Foundation
import Observation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Materialized sales history", .timeLimit(.minutes(1)))
@MainActor
struct SalesHistoryLocalIntegrationTests {
    @Test
    func `shared SwiftData composition moves materialized closure to history and observes compensation in open detail`(
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        var sale = try viewModelSale(stage: .awaitingDocument)
        try SaleLocalDataSource().upsert(sale, in: ModelContext(container))
        let history = dependencies.makeSalesHistory()
        let workday = dependencies.makeWorkday()
        let detail = dependencies.makeSaleDetail(SaleDetailDestination(id: viewModelUUID(500), saleID: sale.id))
        let historyTask = Task {
            await history.load()
        }
        let workdayTask = Task {
            await workday.load()
        }
        let detailTask = Task {
            await detail.load()
        }
        defer {
            history.close()
            workday.close()
            detail.close()
            historyTask.cancel()
            workdayTask.cancel()
            detailTask.cancel()
        }
        await waitForHistoryChange { history.state == .content([]) && workday.state != .loading &&
            workday.state != .idle && detail.state == .unavailable }
        #expect(history.visibleSales.isEmpty)
        guard case let .content(board) = workday.state else {
            Issue.record("Paid sale without document must remain operational")
            return
        }
        #expect(board.awaitingClosure == [sale])

        // Simulate already-materialized lifecycle state, not CloseSaleUseCase or a compensation writer.
        try sale.close(
            documentID: BillingDocumentID(rawValue: viewModelUUID(900)),
            closedAt: Date(timeIntervalSince1970: 300)
        )
        try await dependencies.saveSale(sale)
        let closed = sale
        await waitForHistoryChange {
            history.visibleSales.first == closed && detail.sale == closed && workday.state == .empty
        }
        history.openSale(sale.id)
        let session = try #require(history.destination)
        #expect(detail.sale?.lines == sale.lines)

        try sale.void(
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: 400)
        )
        try await dependencies.saveSale(sale)
        let voided = sale
        await waitForHistoryChange { history.visibleSales.first == voided && detail.sale == voided }
        #expect(history.destination == session)
        #expect(workday.state == .empty)
        guard case let .content(_, calculation) = detail.state else {
            Issue.record("Compensated operation must retain original amounts")
            return
        }
        #expect(calculation.total.amount == Decimal(string: "12.10"))
        #expect(calculation.taxAmount.amount == Decimal(string: "2.10"))
    }

    @Test
    func `a mixed currency historical snapshot surfaces calculation failure without a invented total`() async throws {
        let eur = try viewModelLine()
        let usd = try SaleLine.upcoming(
            id: SaleLineID(rawValue: viewModelUUID(101)),
            serviceID: ServiceID(rawValue: viewModelUUID(201)),
            serviceName: "USD captured service",
            quantity: 1,
            unitPrice: Money(amount: 20, currency: .usd),
            taxRate: TaxRate(percentage: 0),
            discount: nil,
            linkedProductID: nil
        )
        var sale = try Sale.draft(
            id: SaleID(rawValue: viewModelUUID(1)),
            clientID: nil,
            createdAt: Date(timeIntervalSince1970: 100),
            lines: [eur, usd]
        )
        try sale.start()
        for line in sale.lines {
            try sale.startLine(id: line.id)
            try sale.completeLine(id: line.id)
        }
        try sale.registerPayment(
            id: PaymentID(rawValue: viewModelUUID(800)),
            method: .cash,
            paidAt: Date(timeIntervalSince1970: 200)
        )
        try sale.close(
            documentID: BillingDocumentID(rawValue: viewModelUUID(900)),
            closedAt: Date(timeIntervalSince1970: 300)
        )
        let model = historyDetail(repository: InMemorySaleRepository(sales: [sale]))
        await model.load()
        #expect(model.state == .failed)
        #expect(model.lastError as? SaleCalculatorError == .incompatibleCurrency(expected: .eur, actual: .usd))
        #expect(model.sale == nil)
    }
}

@MainActor
private func waitForHistoryChange(_ predicate: @escaping @MainActor () -> Bool) async {
    while !predicate() {
        await withCheckedContinuation { changed in
            withObservationTracking {
                _ = predicate()
            } onChange: {
                changed.resume()
            }
        }
    }
}
