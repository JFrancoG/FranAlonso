import Foundation
import Testing
@testable import FranAlonso

@Suite("Global and line discount navigation")
@MainActor
struct SaleGlobalDiscountNavigationTests {
    @Test
    func `one global session excludes line editing and service selection until its matching finish`() async throws {
        let original = try globalEditorDraft()
        let repository = ViewModelSaleRepository(sales: [original])
        let draft = saleSelectionDraft(repository: repository)
        _ = try await draft.load()
        draft.presentGlobalDiscount()
        let first = try #require(draft.discountDestination)
        #expect(first.target == .global)
        draft.presentGlobalDiscount()
        draft.presentLineDiscount(for: original.lines[0].id)
        draft.presentServicePicker()
        #expect(draft.discountDestination == first)
        #expect(draft.servicePickerDestination == nil)
        draft.finishDiscount(UUID())
        #expect(draft.discountDestination == first)
        draft.finishDiscount(first.id)
        draft.presentLineDiscount(for: original.lines[0].id)
        let line = try #require(draft.discountDestination)
        #expect(line.target == .line(original.lines[0].id))
        draft.presentGlobalDiscount()
        #expect(draft.discountDestination == line)
        draft.close()
        #expect(draft.discountDestination == nil)
        #expect(!draft.canEditGlobalDiscount)
        #expect(try await repository.sale(id: original.id) == original)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `an inspection or closed parent never grants global editing`() async throws {
        let original = try globalEditorDraft()
        let repository = ViewModelSaleRepository(sales: [original])
        let inspect = saleSelectionDraft(repository: repository, mode: .inspect)
        _ = try await inspect.load()
        inspect.presentGlobalDiscount()
        #expect(!inspect.canEditGlobalDiscount)
        #expect(inspect.discountDestination == nil)
        await #expect(throws: SaleDraftViewModelError.readOnly) {
            _ = try await inspect.setGlobalDiscount(Discount(percentage: 20))
        }
        inspect.close()
        inspect.presentGlobalDiscount()
        #expect(inspect.discountDestination == nil)
        await #expect(throws: SaleDraftViewModelError.closed) {
            _ = try await inspect.setGlobalDiscount(nil)
        }
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `operational inspection includes the historical global term without granting editing`() async throws {
        let draft = try globalEditorDraft()
        var original = try draft.replacingDraft(
            clientID: draft.clientID,
            lines: draft.lines,
            globalDiscount: SaleGlobalDiscount(discount: Discount(percentage: 20), policy: .lineThenGlobalV1)
        )
        try original.start()
        let repository = ViewModelSaleRepository(sales: [original])
        let inspect = saleSelectionDraft(repository: repository, mode: .inspect)
        _ = try await inspect.load()
        let calculation = try #require(inspect.calculation)
        #expect(calculation.lineDiscountAmount.amount == 10)
        #expect(calculation.globalDiscountAmount.amount == 18)
        #expect(calculation.total.amount == 72)
        #expect(inspect.sale == original)
        #expect(!inspect.canEditGlobalDiscount)
        #expect(await repository.writeCount == 0)
    }
}
