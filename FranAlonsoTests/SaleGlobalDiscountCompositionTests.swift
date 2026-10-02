import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Global discount editor composition")
@MainActor
struct SaleGlobalDiscountCompositionTests {
    @Test
    func `global editor stacks with a captured promotion and removing it preserves that promotion`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let original = try globalEditorDraft()
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let draft = dependencies.makeSaleDraft(SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft))
        _ = try await draft.load()
        draft.presentGlobalDiscount()
        let first = try #require(draft.discountDestination)
        let editor = dependencies.makeSaleDiscount(for: draft, destination: first, locale: Locale(identifier: "es_ES"))
        editor.discountText = "20"
        editor.requestApply()
        await editor.submit()
        #expect(editor.hasAcceptedChange)
        #expect(draft.sale?.globalDiscount?.discount.percentage == 20)
        #expect(draft.sale?.globalDiscount?.policy == .lineThenGlobalV1)
        #expect(draft.sale?.lines.first?.discount?.percentage == 10)
        #expect(draft.calculation?.lineDiscountAmount.amount == 10)
        #expect(draft.calculation?.globalDiscountAmount.amount == 18)
        #expect(draft.calculation?.total.amount == 72)
        editor.close()
        draft.finishDiscount(first.id)
        draft.close()

        let reopened = dependencies.makeSaleDraft(
            SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft)
        )
        _ = try await reopened.load()
        #expect(reopened.calculation?.total.amount == 72)
        reopened.presentGlobalDiscount()
        let second = try #require(reopened.discountDestination)
        let removal = dependencies.makeSaleDiscount(
            for: reopened,
            destination: second,
            locale: Locale(identifier: "en_US")
        )
        #expect(removal.discountText == "20")
        removal.requestRemoval()
        await removal.submit()
        #expect(removal.hasAcceptedChange)
        #expect(reopened.sale?.globalDiscount == nil)
        #expect(reopened.sale?.lines.first?.discount?.percentage == 10)
        #expect(reopened.calculation?.total.amount == 90)
        let persisted = try #require(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)))
        #expect(persisted.lines == original.lines)
        #expect(persisted.globalDiscount == nil)
        reopened.close()
    }

    @Test
    func `finishing an editor revokes its global acceptance capability without writing`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let original = try globalEditorDraft()
        let source = SaleLocalDataSource()
        try source.upsert(original, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let draft = dependencies.makeSaleDraft(SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft))
        _ = try await draft.load()
        draft.presentGlobalDiscount()
        let destination = try #require(draft.discountDestination)
        let editor = dependencies.makeSaleDiscount(
            for: draft,
            destination: destination,
            locale: Locale(identifier: "es_ES")
        )
        #expect(editor.canEdit)
        draft.finishDiscount(destination.id)
        editor.discountText = "20"
        editor.requestApply()
        await editor.submit()
        #expect(editor.isUnavailable)
        #expect(!editor.hasAcceptedChange)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == original)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(!draft.isClosed)
        draft.close()
    }
}

@MainActor
func globalEditorDraft() throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(rawValue: viewModelUUID(8_301)),
        serviceID: ServiceID(rawValue: viewModelUUID(8_302)),
        serviceName: "Servicio con promoción",
        quantity: 1,
        unitPrice: Money(amount: 100, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10),
        linkedProductID: nil
    )
    return try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(7_805)),
        clientID: nil,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        lines: [line]
    )
}
