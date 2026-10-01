import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale service selection pipeline", .timeLimit(.minutes(1)))
@MainActor
struct SaleServiceSelectionPipelineTests {
    @Test(arguments: SaleServiceSelectionOffering.allCases, [Currency.eur, .usd])
    func `adding freezes visible terms before awaiting and preserves them through local reopen`(
        offering: SaleServiceSelectionOffering,
        currency: Currency
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let original = try saleSelectionEmptyDraft()
        try source.createDraft(original, operationID: original.id.rawValue, in: ModelContext(container))
        let sales = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let service = try offering.service(currency: currency)
        let services = InMemoryServiceRepository(services: [service])
        let draft = saleSelectionDraft(repository: sales, currency: currency)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: services, draft: draft)
        await selection.picker.load()
        selection.requestSelection(id: service.id)
        try await services.saveService(offering.service(currency: currency, revised: true))
        await selection.picker.load()

        await selection.submitSelection()

        let persisted = try #require(try source.sale(id: original.id, in: ModelContext(container)))
        let line = try #require(persisted.lines.first)
        let expectedPrice = try viewModelDecimal(offering == .professional ? "12.10" : "43.27")
        let expectedBase = try viewModelDecimal(offering == .professional ? "10.00" : "40.25")
        let expectedTax = try viewModelDecimal(offering == .professional ? "2.10" : "3.02")
        #expect(persisted.lines.count == 1)
        #expect(line.id == SaleLineID(rawValue: viewModelUUID(7_806)))
        #expect(line.serviceName == (offering == .professional ? "Corte original" : "Kit original"))
        #expect(line.quantity == 1)
        #expect(line.unitPrice.amount == expectedPrice)
        #expect(line.unitPrice.currency == currency)
        #expect(line.taxRate.percentage == (offering == .professional ? 21 : 7.5))
        #expect(line.discount?.percentage == (offering == .professional ? nil : 0))
        #expect(line.linkedProductID == (offering == .product ? ProductID(rawValue: viewModelUUID(7_802)) : nil))
        #expect(draft.calculation?.total.amount == expectedPrice)
        #expect(draft.calculation?.taxableBase.amount == expectedBase)
        #expect(draft.calculation?.taxAmount.amount == expectedTax)
        #expect(selection.hasAcceptedSelection)
        draft.close()
        let reopened = saleSelectionDraft(repository: sales, currency: currency)
        _ = try await reopened.load()
        #expect(reopened.sale == persisted)
        #expect(reopened.calculation?.total.amount == expectedPrice)
        reopened.close()
    }

    @Test(arguments: [0, -1])
    func `snapshot capture rejects nonpositive quantity before any draft acceptance`(quantity: Int) throws {
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        #expect(throws: SaleLineError.invalidQuantity) {
            _ = try SaleLine.capturing(
                service: service,
                id: SaleLineID(rawValue: viewModelUUID(7_806)),
                quantity: quantity
            )
        }
    }

    @Test
    func `inactive catalogue offerings cannot become new captured intentions`() throws {
        let inactive = try makeService(status: .inactive)
        #expect(throws: SaleServiceSelectionError.unavailable) {
            _ = try SaleLine.capturing(service: inactive, id: SaleLineID(rawValue: viewModelUUID(7_806)))
        }
    }
}
