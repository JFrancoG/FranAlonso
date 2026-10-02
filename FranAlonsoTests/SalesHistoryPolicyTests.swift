import Foundation
import Testing
@testable import FranAlonso

struct SalesHistoryPolicyTests {
    @Test(arguments: [SalesHistoryFilter.all, .closed, .voided])
    func `only terminal operations pass the selected filter`(filter: SalesHistoryFilter) throws {
        let closed = try viewModelSale(index: 1, stage: .closed)
        let voided = try viewModelSale(index: 2, stage: .voided)
        let paid = try viewModelSale(index: 3, stage: .awaitingDocument)
        let draft = try viewModelSale(index: 4)
        let result = SalesHistoryPolicy()([draft, paid, voided, closed], filter: filter)
        let expected = filter == .all ? [closed.id, voided.id] : [filter == .closed ? closed.id : voided.id]
        #expect(result.map(\.id) == expected)
    }

    @Test(arguments: [SalesHistoryOrder.newestFirst, .oldestFirst])
    func `original closure chronology survives later compensation`(order: SalesHistoryOrder) throws {
        let old = try historySale(index: 1, closedAt: 300, voidedAt: 900)
        let recent = try historySale(index: 2, closedAt: 400)
        let result = SalesHistoryPolicy()([old, recent], order: order)
        #expect(result.map(\.id) == (order == .newestFirst ? [recent.id, old.id] : [old.id, recent.id]))
        #expect(SalesHistoryPolicy().closureDate(of: old) == Date(timeIntervalSince1970: 300))
    }

    @Test(arguments: [SalesHistoryOrder.newestFirst, .oldestFirst])
    func `equal closure dates use stable identity despite stream ordering`(order: SalesHistoryOrder) throws {
        let first = try viewModelSale(index: 1, stage: .closed)
        let second = try viewModelSale(index: 2, stage: .voided)
        #expect(SalesHistoryPolicy()([second, first], order: order).map(\.id) == [first.id, second.id])
    }

    @Test
    func `unpaid and paid without document have no historical closure date`() throws {
        #expect(SalesHistoryPolicy().closureDate(of: try viewModelSale()) == nil)
        #expect(SalesHistoryPolicy().closureDate(of: try viewModelSale(stage: .awaitingDocument)) == nil)
    }
}

func historySale(index: Int, closedAt: TimeInterval, voidedAt: TimeInterval? = nil) throws -> Sale {
    var sale = try viewModelSale(index: index, stage: .awaitingDocument)
    try sale.close(
        documentID: BillingDocumentID(rawValue: viewModelUUID(900)),
        closedAt: Date(timeIntervalSince1970: closedAt)
    )
    if let voidedAt {
        try sale.void(
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: voidedAt)
        )
    }
    return sale
}
