import Foundation
import Testing
@testable import FranAlonso

struct WorkdaySalesPolicyTests {
    @Test
    func `all operational states remain visible regardless of date while terminal states disappear`() throws {
        let oldDraft = try viewModelSale(index: 1, stage: .draft, createdAt: Date(timeIntervalSince1970: 1))
        let draft = try viewModelSale(index: 2, stage: .draft)
        let working = try viewModelSale(index: 3, stage: .inProgress)
        let unpaid = try viewModelSale(index: 4, stage: .awaitingPayment)
        let paid = try viewModelSale(index: 5, stage: .awaitingDocument)
        let closed = try viewModelSale(index: 6, stage: .closed)
        let voided = try viewModelSale(index: 7, stage: .voided)

        let board = WorkdaySalesPolicy()([voided, paid, working, draft, closed, unpaid, oldDraft])

        #expect(board.upcoming.map(\.id) == [oldDraft.id, draft.id])
        #expect(board.inProgress.map(\.id) == [working.id])
        #expect(board.awaitingClosure.map(\.id) == [unpaid.id, paid.id])
        #expect(board.sales.count == 5)
    }

    @Test
    func `equal creation dates use stable identity ordering instead of input ordering`() throws {
        let first = try viewModelSale(index: 1)
        let second = try viewModelSale(index: 2)
        let third = try viewModelSale(index: 3)

        let board = WorkdaySalesPolicy()([third, first, second])

        #expect(board.upcoming.map(\.id) == [first.id, second.id, third.id])
    }

    @Test
    func `separate sales for the same client and unassigned sales are never merged`() throws {
        let clientID = ClientID(rawValue: viewModelUUID(600))
        let first = try viewModelSale(index: 1, clientID: clientID)
        let second = try viewModelSale(index: 2, clientID: clientID)
        let unassigned = try viewModelSale(index: 3)

        let board = WorkdaySalesPolicy()([second, unassigned, first])

        #expect(board.upcoming.map(\.id) == [first.id, second.id, unassigned.id])
        #expect(board.upcoming.filter { $0.clientID == clientID }.count == 2)
        #expect(board.upcoming.last?.clientID == nil)
    }

    @Test
    func `a collection containing only terminal operations is an empty board`() throws {
        let closed = try viewModelSale(index: 1, stage: .closed)
        let voided = try viewModelSale(index: 2, stage: .voided)

        #expect(WorkdaySalesPolicy()([voided, closed]).isEmpty)
        #expect(WorkdaySalesPolicy()([]).isEmpty)
    }
}

enum ViewModelSaleStage {
    case draft, inProgress, awaitingPayment, awaitingDocument, closed, voided
}

func viewModelSale(
    index: Int = 1,
    stage: ViewModelSaleStage = .draft,
    createdAt: Date = Date(timeIntervalSince1970: 100),
    clientID: ClientID? = nil
) throws -> Sale {
    let line = try viewModelLine()
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(index)),
        clientID: clientID,
        createdAt: createdAt,
        lines: [line]
    )
    guard stage != .draft else { return sale }
    try sale.start()
    guard stage != .inProgress else { return sale }
    try sale.startLine(id: line.id)
    try sale.completeLine(id: line.id)
    guard stage != .awaitingPayment else { return sale }
    try sale.registerPayment(
        id: PaymentID(rawValue: viewModelUUID(800)),
        method: .cash,
        paidAt: Date(timeIntervalSince1970: 200)
    )
    guard stage != .awaitingDocument else { return sale }
    try sale.close(
        documentID: BillingDocumentID(rawValue: viewModelUUID(900)),
        closedAt: Date(timeIntervalSince1970: 300)
    )
    guard stage == .voided else { return sale }
    try sale.void(reversalID: SaleReversalID(rawValue: viewModelUUID(999)), voidedAt: Date(timeIntervalSince1970: 400))
    return sale
}

func viewModelLine(index: Int = 100, quantity: Int = 1) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: viewModelUUID(index)),
        serviceID: ServiceID(rawValue: viewModelUUID(200)),
        serviceName: "Captured cut",
        quantity: quantity,
        unitPrice: Money(amount: viewModelDecimal("12.10"), currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
}

func viewModelDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}

func viewModelUUID(_ index: Int) -> UUID {
    let hundreds = UInt8(index / 100)
    let lastDigits = UInt8((index / 10) % 10) * 16 + UInt8(index % 10)
    return UUID(uuid: (0x11, 0x40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, hundreds, lastDigits))
}
