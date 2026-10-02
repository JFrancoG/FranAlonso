import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale line discount navigation")
@MainActor
struct SaleLineDiscountNavigationTests {
    @Test
    func `opening and finishing a line editor preserves the accepted parent and never writes`() async throws {
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let line = try SaleLine.capturing(service: service, id: SaleLineID(rawValue: viewModelUUID(8_001)))
        let original = try saleSelectionEmptyDraft().replacingDraft(clientID: nil, lines: [line])
        let repository = ViewModelSaleRepository(sales: [original])
        let draft = saleSelectionDraft(repository: repository)
        _ = try await draft.load()

        #expect(draft.canEditDiscount(for: line.id))
        draft.presentLineDiscount(for: line.id)
        let first = try #require(draft.discountDestination)
        #expect(first.target == .line(line.id))
        draft.presentLineDiscount(for: line.id)
        #expect(draft.discountDestination == first)
        draft.presentServicePicker()
        #expect(draft.servicePickerDestination == nil)
        draft.finishDiscount(first.id)
        #expect(draft.discountDestination == nil)
        #expect(!draft.isClosed)
        draft.presentLineDiscount(for: line.id)
        let second = try #require(draft.discountDestination)
        #expect(second.id != first.id)
        draft.finishDiscount(first.id)
        #expect(draft.discountDestination == second)
        draft.close()
        #expect(draft.discountDestination == nil)
        #expect(!draft.canEditDiscount(for: line.id))
        #expect(try await repository.sale(id: original.id) == original)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `unknown lines and inspect mode never gain a discount editor`() async throws {
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let line = try SaleLine.capturing(service: service, id: SaleLineID(rawValue: viewModelUUID(8_002)))
        let original = try saleSelectionEmptyDraft().replacingDraft(clientID: nil, lines: [line])
        let repository = ViewModelSaleRepository(sales: [original])
        let draft = saleSelectionDraft(repository: repository)
        _ = try await draft.load()
        let unknown = SaleLineID(rawValue: viewModelUUID(8_003))
        #expect(!draft.canEditDiscount(for: unknown))
        draft.presentLineDiscount(for: unknown)
        #expect(draft.discountDestination == nil)
        let inspect = saleSelectionDraft(repository: repository, mode: .inspect)
        _ = try await inspect.load()
        #expect(!inspect.canEditDiscount(for: line.id))
        inspect.presentLineDiscount(for: line.id)
        #expect(inspect.discountDestination == nil)
        #expect(await repository.writeCount == 0)
    }
}
