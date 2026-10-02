import Foundation
import Testing
@testable import FranAlonso

@MainActor
struct SaleDetailViewModelTests {
    @Test(arguments: [ViewModelSaleStage.closed, .voided])
    func `terminal inspection preserves original commercial and payment document reversal trace`(
        stage: ViewModelSaleStage
    ) async throws {
        let sale = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [sale])
        let model = historyDetail(repository: repository, saleID: sale.id)
        await model.load()
        guard case let .content(actual, calculation) = model.state else {
            Issue.record("Terminal history must provide its immutable sale and original monetary breakdown")
            return
        }
        #expect(actual == sale)
        #expect(calculation.total.amount == Decimal(string: "12.10"))
        #expect(calculation.taxAmount.amount == Decimal(string: "2.10"))
        #expect(model.sale == sale)
        #expect(await repository.writeCount == 0)
    }

    @Test(arguments: [ViewModelSaleStage.draft, .inProgress, .awaitingPayment, .awaitingDocument])
    func `operational sales cannot be inspected as historical operations`(stage: ViewModelSaleStage) async throws {
        let sale = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [sale])
        let model = historyDetail(repository: repository, saleID: sale.id)
        await model.load()
        #expect(model.state == .unavailable)
        #expect(model.sale == nil)
    }

    @Test
    func `missing operation differs from local failure and retry recovers`() async throws {
        let repository = ViewModelSaleRepository()
        let model = historyDetail(repository: repository)
        await model.load()
        #expect(model.state == .unavailable)
        await repository.failNextObservation()
        await model.load()
        #expect(model.state == .failed)
        #expect(model.lastError as? ViewModelRepositoryError == .unavailable)
        await repository.saveSale(try viewModelSale(stage: .closed))
        await model.load()
        #expect(model.sale?.id == SaleID(rawValue: viewModelUUID(1)))
        #expect(model.lastError == nil)
    }

    @Test
    func `voided materialization and replay update detail without editing the original snapshot`() async throws {
        var sale = try viewModelSale(stage: .closed)
        let repository = ViewModelSaleRepository(sales: [sale])
        let model = historyDetail(repository: repository)
        await model.load()
        let originalLines = try #require(model.sale).lines
        try sale.void(
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: 400)
        )
        await repository.saveSale(sale)
        await model.load()
        #expect(model.sale?.lines == originalLines)
        #expect(model.sale?.status == .voided(
            paymentID: PaymentID(rawValue: viewModelUUID(800)),
            method: .cash,
            paidAt: Date(timeIntervalSince1970: 200),
            documentID: BillingDocumentID(rawValue: viewModelUUID(900)),
            closedAt: Date(timeIntervalSince1970: 300),
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: 400)
        ))
        try sale.void(
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: 400)
        )
        await repository.saveSale(sale)
        await model.load()
        #expect(model.sale == sale)
    }

    @Test
    func `close removes content and prevents reentry`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale(stage: .closed)])
        let model = historyDetail(repository: repository)
        await model.load()
        model.close()
        await model.load()
        #expect(model.state == .closed)
        #expect(model.sale == nil)
    }
}

@MainActor
func historyDetail(
    repository: any SaleRepository,
    saleID: SaleID = SaleID(rawValue: viewModelUUID(1))
) -> SaleDetailViewModel {
    SaleDetailViewModel(
        destination: SaleDetailDestination(id: viewModelUUID(500), saleID: saleID),
        observe: ObserveSalesUseCase(repository: repository)
    )
}
