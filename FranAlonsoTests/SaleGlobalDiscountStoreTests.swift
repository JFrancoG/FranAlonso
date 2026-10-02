import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale global discount draft store", .timeLimit(.minutes(1)))
@MainActor
struct SaleGlobalDiscountStoreTests {
    @Test
    func `accepted global totals survive reopening and later captured line changes`() async throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()], percentage: nil)
        let repository = InMemorySaleRepository(sales: [original])
        let store = globalDiscountStore(repository: repository)
        _ = try await store.load(id: original.id)

        let accepted = try await store.setGlobalDiscount(Discount(percentage: 20))
        #expect(accepted.globalDiscount?.discount.percentage == 20)
        #expect(store.calculation?.lineDiscountAmount.amount == 10)
        #expect(store.calculation?.globalDiscountAmount.amount == 18)
        #expect(store.calculation?.total.amount == 72)
        #expect(try await repository.sale(id: original.id) == accepted)

        let reopened = globalDiscountStore(repository: repository)
        _ = try await reopened.load(id: original.id)
        #expect(reopened.calculation?.total.amount == 72)
        _ = try await reopened.addLine(globalDiscountLine(index: 2))
        #expect(reopened.calculation?.total.amount == 144)
        _ = try await reopened.setQuantity(2, for: original.lines[0].id)
        #expect(reopened.calculation?.total.amount == 216)
        _ = try await reopened.setClient(ClientID(rawValue: globalDiscountUUID(802)))
        #expect(reopened.draft?.globalDiscount?.discount.percentage == 20)
        #expect(reopened.calculation?.total.amount == 216)
        _ = try await reopened.removeLine(id: original.lines[0].id)
        #expect(reopened.calculation?.total.amount == 72)
    }

    @Test
    func `removal is independent and zero remains a durable explicit global`() async throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()])
        let repository = InMemorySaleRepository(sales: [original])
        let store = globalDiscountStore(repository: repository)
        _ = try await store.load(id: original.id)
        #expect(store.calculation?.total.amount == 72)

        _ = try await store.setDiscount(nil, for: original.lines[0].id)
        #expect(store.draft?.globalDiscount?.discount.percentage == 20)
        #expect(store.calculation?.total.amount == 80)
        _ = try await store.setGlobalDiscount(Discount(percentage: 0))
        #expect(store.draft?.globalDiscount?.discount.percentage == 0)
        #expect(store.calculation?.total.amount == 100)
        _ = try await store.setGlobalDiscount(nil)
        #expect(store.draft?.globalDiscount == nil)
        #expect(try await repository.sale(id: original.id)?.globalDiscount == nil)
        #expect(store.calculation?.total.amount == 100)
    }

    @Test
    func `an empty recovered sale accepts a global that affects a future service`() async throws {
        let original = try globalDiscountSale(lines: [], percentage: nil)
        let repository = InMemorySaleRepository(sales: [original])
        let store = globalDiscountStore(repository: repository)
        _ = try await store.load(id: original.id)

        _ = try await store.setGlobalDiscount(Discount(percentage: 100))
        #expect(store.draft?.globalDiscount?.discount.percentage == 100)
        #expect(store.calculation?.total.amount == 0)
        _ = try await store.addLine(globalDiscountLine())
        #expect(store.calculation?.lineDiscountAmount.amount == 10)
        #expect(store.calculation?.globalDiscountAmount.amount == 90)
        #expect(store.calculation?.discountAmount.amount == 100)
        #expect(store.calculation?.total.amount == 0)
    }
}

@MainActor
func globalDiscountStore(repository: any SaleRepository) -> SaleDraftStore {
    SaleDraftStore(
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: repository),
        get: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository)
    )
}
