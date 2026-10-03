import Foundation
import Testing
@testable import FranAlonso

@Suite("Paid sale billing navigation")
@MainActor
struct SaleBillingNavigationTests {
    @Test
    func `paid document selection preserves the parent and ignores obsolete close callbacks without writing`() async throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let repository = ViewModelSaleRepository(sales: [sale])
        let draft = makeBillingNavigationDraft(repository: repository, saleID: sale.id)
        _ = try await draft.load()
        #expect(draft.canSelectBilling)
        draft.presentBilling()
        let first = try #require(draft.billingDestination)
        #expect(first.saleID == sale.id)
        draft.presentBilling()
        #expect(draft.billingDestination == first)
        draft.finishBilling(first.id)
        #expect(draft.billingDestination == nil)
        #expect(!draft.isClosed)
        draft.presentBilling()
        let second = try #require(draft.billingDestination)
        #expect(second.id != first.id)
        draft.finishBilling(first.id)
        #expect(draft.billingDestination == second)
        #expect(draft.sale == sale)
        #expect(await repository.writeCount == 0)
        #expect(try await repository.sale(id: sale.id) == sale)
        #expect(WorkdaySalesPolicy()([sale]).awaitingClosure.map(\.id) == [sale.id])
        draft.close()
        #expect(draft.billingDestination == nil)
        #expect(!draft.canSelectBilling)
        draft.presentBilling()
        #expect(draft.billingDestination == nil)
    }

    @Test(arguments: [ViewModelSaleStage.draft, .inProgress, .awaitingPayment, .closed, .voided])
    func `unpaid and terminal sales cannot open document selection`(_ stage: ViewModelSaleStage) async throws {
        let sale = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [sale])
        let draft = makeBillingNavigationDraft(repository: repository, saleID: sale.id)
        _ = try await draft.load()
        draft.presentBilling()
        #expect(!draft.canSelectBilling)
        #expect(draft.billingDestination == nil)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `inspection and unloaded sessions cannot create a document form even for a paid sale`() async throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let repository = ViewModelSaleRepository(sales: [sale])
        let draft = makeBillingNavigationDraft(repository: repository, saleID: sale.id)
        draft.presentBilling()
        #expect(draft.billingDestination == nil)
        let inspection = makeBillingNavigationDraft(repository: repository, saleID: sale.id, mode: .inspect)
        _ = try await inspection.load()
        inspection.presentBilling()
        #expect(!inspection.canSelectBilling)
        #expect(inspection.billingDestination == nil)
        #expect(await repository.writeCount == 0)
    }
}
