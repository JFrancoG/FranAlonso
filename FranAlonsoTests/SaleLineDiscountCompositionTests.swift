import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale line discount composition")
@MainActor
struct SaleLineDiscountCompositionTests {
    @Test
    func `App editor accepts a localized percentage and reopening recovers the same captured line`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let line = try SaleLine.capturing(service: service, id: SaleLineID(rawValue: viewModelUUID(8_010)))
        let original = try saleSelectionEmptyDraft().replacingDraft(clientID: nil, lines: [line])
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let draft = dependencies.makeSaleDraft(SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft))
        _ = try await draft.load()
        draft.presentLineDiscount(for: line.id)
        let destination = try #require(draft.discountDestination)
        let editor = dependencies.makeSaleDiscount(
            for: draft,
            destination: destination,
            locale: Locale(identifier: "es_ES")
        )
        editor.discountText = "12,5"
        editor.requestApply()
        await editor.submit()
        #expect(editor.hasAcceptedChange)
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("10.59")))
        #expect(draft.sale?.lines.first?.serviceName == "Corte original")
        editor.close()
        draft.finishDiscount(destination.id)
        #expect(!draft.isClosed)
        let persisted = try #require(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)))
        #expect(persisted.lines.first?.discount?.percentage == (try viewModelDecimal("12.5")))
        draft.close()
        let reopened = dependencies.makeSaleDraft(
            SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft)
        )
        _ = try await reopened.load()
        #expect(reopened.calculation?.total.amount == (try viewModelDecimal("10.59")))
        #expect(reopened.sale == persisted)
        reopened.close()
    }
}
