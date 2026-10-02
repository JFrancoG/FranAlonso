import Foundation
import Testing
@testable import FranAlonso

@MainActor
struct SalesHistoryViewModelTests {
    @Test
    func `history excludes operational sales and filters searches immutable service snapshots`() async throws {
        let closed = try viewModelSale(index: 1, stage: .closed)
        let voided = try viewModelSale(index: 2, stage: .voided)
        let paid = try viewModelSale(index: 3, stage: .awaitingDocument)
        let repository = ViewModelSaleRepository(sales: [voided, paid, closed])
        let model = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        #expect(model.visibleSales.map(\.id) == [closed.id, voided.id])
        model.filter = .voided
        #expect(model.visibleSales.map(\.id) == [voided.id])
        model.query = "  CAPTURED  "
        #expect(model.visibleSales.map(\.id) == [voided.id])
        model.query = "absent"
        #expect(model.visibleSales.isEmpty)
        model.query = voided.id.rawValue.uuidString.lowercased()
        #expect(model.visibleSales.map(\.id) == [voided.id])
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `navigation accepts only visible rows and delayed dismissal cannot close replacement`() async throws {
        let sale = try viewModelSale(stage: .closed)
        let repository = ViewModelSaleRepository(sales: [sale])
        var next = 500
        let model = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository)) {
            defer {
                next += 1
            }
            return viewModelUUID(next)
        }
        await model.load()
        model.openSale(SaleID(rawValue: viewModelUUID(99)))
        #expect(model.destination == nil)
        model.openSale(sale.id)
        let first = try #require(model.destination)
        model.openSale(sale.id)
        #expect(model.destination == first)
        model.filter = .voided
        #expect(model.destination == first)
        model.finishSession(first.id)
        model.openSale(sale.id)
        #expect(model.destination == nil)
        model.filter = .all
        model.openSale(sale.id)
        let second = try #require(model.destination)
        model.finishSession(first.id)
        #expect(model.destination == second)
        #expect(second.id != first.id)
        #expect(second.saleID == sale.id)
    }

    @Test
    func `authoritative disappearance invalidates navigation but void does not`() async throws {
        let sale = try viewModelSale(stage: .closed)
        let repository = ViewModelSaleRepository(sales: [sale])
        let model = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        model.openSale(sale.id)
        let session = try #require(model.destination)
        await repository.saveSale(try viewModelSale(stage: .voided))
        await model.load()
        #expect(model.destination == session)
        await repository.removeFixture(id: sale.id)
        await model.load()
        #expect(model.destination == nil)
        #expect(model.visibleSales.isEmpty)
    }

    @Test
    func `retry clears failure and retains query preferences`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale(stage: .voided)])
        let model = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository))
        model.filter = .voided
        model.order = .oldestFirst
        model.query = "cut"
        await repository.failNextObservation()
        await model.load()
        #expect(model.state == .failed)
        #expect(model.lastError as? ViewModelRepositoryError == .unavailable)
        await model.load()
        #expect(model.visibleSales.count == 1)
        #expect(model.lastError == nil)
        #expect(model.filter == .voided)
        #expect(model.order == .oldestFirst)
        #expect(model.query == "cut")
    }

    @Test
    func `empty snapshot is ready and closing is terminal`() async {
        let repository = ViewModelSaleRepository()
        let model = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        #expect(model.state == .content([]))
        model.close()
        await model.load()
        #expect(model.state == .closed)
        #expect(model.destination == nil)
    }
}
