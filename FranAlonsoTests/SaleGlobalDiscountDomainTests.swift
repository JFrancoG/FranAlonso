import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale global discount snapshot behavior")
struct SaleGlobalDiscountDomainTests {
    @Test
    func `setting a global discount keeps the promotion and captured service terms`() throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()], percentage: nil)

        let edited = try SaleDraftEditingPolicy().settingGlobalDiscount(Discount(percentage: 20), in: original)
        let calculation = try SaleCalculator().calculate(sale: edited, currency: .eur)

        #expect(edited.lines == original.lines)
        #expect(edited.id == original.id)
        #expect(edited.createdAt == original.createdAt)
        #expect(edited.globalDiscount?.discount.percentage == 20)
        #expect(edited.globalDiscount?.policy == .lineThenGlobalV1)
        #expect(calculation.lineDiscountAmount.amount == 10)
        #expect(calculation.globalDiscountAmount.amount == 18)
        #expect(calculation.total.amount == 72)
    }

    @Test
    func `zero is an accepted global term and explicit removal restores absence`() throws {
        let original = try globalDiscountSale(lines: [], percentage: nil)
        let zero = try SaleDraftEditingPolicy().settingGlobalDiscount(Discount(percentage: 0), in: original)

        #expect(zero.globalDiscount?.discount.percentage == 0)
        #expect(zero != original)
        let removed = try SaleDraftEditingPolicy().settingGlobalDiscount(nil, in: zero)
        #expect(removed.globalDiscount == nil)
        #expect(removed == original)
    }

    @Test
    func `future captured services receive the global without replacing their own promotion`() throws {
        let original = try globalDiscountSale(lines: [], percentage: "20")
        let service = try Service(
            id: ServiceID(rawValue: globalDiscountUUID(701)),
            name: "Future promoted service",
            type: .professional,
            price: globalDiscountMoney("100"),
            taxRate: TaxRate(percentage: 21),
            discount: Discount(percentage: 10),
            status: .active
        )
        let line = try SaleLine.capturing(service: service, id: SaleLineID(rawValue: globalDiscountUUID(702)))

        let added = try SaleDraftEditingPolicy().adding(line, to: original)
        let calculation = try SaleCalculator().calculate(sale: added, currency: .eur)

        #expect(added.globalDiscount?.discount.percentage == 20)
        #expect(added.lines.first?.discount?.percentage == 10)
        #expect(calculation.total.amount == 72)
        #expect(calculation.taxableBase.amount == (try globalDiscountDecimal("59.50")))
    }

    @Test
    func `removing the global retains line promotions and removing a line promotion retains the global`() throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()])
        let policy = SaleDraftEditingPolicy()

        let withoutGlobal = try policy.settingGlobalDiscount(nil, in: original)
        #expect(withoutGlobal.globalDiscount == nil)
        #expect(withoutGlobal.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: withoutGlobal, currency: .eur).total.amount == 90)

        let withoutLine = try policy.settingDiscount(nil, for: original.lines[0].id, in: original)
        #expect(withoutLine.globalDiscount?.discount.percentage == 20)
        #expect(withoutLine.lines.first?.discount == nil)
        #expect(try SaleCalculator().calculate(sale: withoutLine, currency: .eur).total.amount == 80)
    }

    @Test
    func `client quantity removal and the preserving overload retain the commercial global term`() throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()])
        let policy = SaleDraftEditingPolicy()
        let withClient = try policy.settingClient(ClientID(rawValue: globalDiscountUUID(800)), in: original)
        let doubled = try policy.settingQuantity(2, for: original.lines[0].id, in: withClient)
        let retained = try doubled.replacingDraft(clientID: nil, lines: doubled.lines)
        let emptied = try policy.removing(id: original.lines[0].id, from: retained)

        #expect(try SaleCalculator().calculate(sale: retained, currency: .eur).total.amount == 144)
        #expect(emptied.globalDiscount?.discount.percentage == 20)
        #expect(emptied.lines.isEmpty)
        let explicitlyRemoved = try retained.replacingDraft(clientID: nil, lines: retained.lines, globalDiscount: nil)
        #expect(explicitlyRemoved.globalDiscount == nil)
        #expect(try SaleCalculator().calculate(sale: explicitlyRemoved, currency: .eur).total.amount == 180)
    }

    @Test(arguments: [GlobalDiscountHistoricalStage.paid, .closed, .voided])
    private func `paid closed and voided snapshots preserve historical calculation after Codable`(
        stage: GlobalDiscountHistoricalStage
    ) throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine(tax: "21")])
        let progressed = try stage.advance(original)
        let recovered = try JSONDecoder().decode(Sale.self, from: JSONEncoder().encode(progressed))

        #expect(recovered.status == progressed.status)
        #expect(recovered.globalDiscount?.discount.percentage == 20)
        #expect(recovered.lines.first?.discount?.percentage == 10)
        let calculation = try SaleCalculator().calculate(sale: recovered, currency: .eur)
        #expect(calculation.total.amount == 72)
        #expect(calculation.taxableBase.amount == (try globalDiscountDecimal("59.50")))
        #expect(calculation.taxAmount.amount == (try globalDiscountDecimal("12.50")))
        #expect(throws: SaleDraftError.requiresDraft) {
            try SaleDraftEditingPolicy().settingGlobalDiscount(nil, in: recovered)
        }
    }

    @Test
    func `the repository rejects a stale snapshot whose only difference is the global term`() async throws {
        let expected = try globalDiscountSale(lines: [globalDiscountLine()], percentage: "10")
        let current = try globalDiscountSale(lines: [globalDiscountLine()], percentage: "20")
        let repository = InMemorySaleRepository(sales: [current])

        await #expect(throws: SaleDraftError.staleDraft) {
            try await UpdateSaleDraftUseCase(repository: repository)(expected, clientID: nil, lines: expected.lines)
        }
        #expect(try await repository.sale(id: expected.id) == current)
    }

    @Test
    func `the repository preserving overload retains global and the explicit overload removes it`() async throws {
        let original = try globalDiscountSale(lines: [globalDiscountLine()])
        let repository = InMemorySaleRepository(sales: [original])
        let update = UpdateSaleDraftUseCase(repository: repository)
        let clientID = ClientID(rawValue: globalDiscountUUID(801))

        let retained = try await update(original, clientID: clientID, lines: original.lines)
        #expect(retained.globalDiscount?.discount.percentage == 20)
        #expect(try SaleCalculator().calculate(sale: retained, currency: .eur).total.amount == 72)
        let removed = try await update(
            retained,
            clientID: clientID,
            lines: retained.lines,
            globalDiscount: nil
        )
        #expect(removed.globalDiscount == nil)
        #expect(try await repository.sale(id: original.id) == removed)
    }

    @Test
    func `an unknown historical global policy is rejected before it can be recalculated`() throws {
        let unknown = #"{"discount":{"percentage":20},"policy":"lineThenGlobalV2"}"#

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SaleGlobalDiscount.self, from: Data(unknown.utf8))
        }
    }
}

private enum GlobalDiscountHistoricalStage {
    case paid, closed, voided

    func advance(_ original: Sale) throws -> Sale {
        var sale = original
        let lineID = try #require(sale.lines.first?.id)
        try sale.start()
        try sale.startLine(id: lineID)
        try sale.completeLine(id: lineID)
        try sale.registerPayment(
            id: PaymentID(rawValue: globalDiscountUUID(901)),
            method: .card,
            paidAt: Date(timeIntervalSinceReferenceDate: 1_101)
        )
        switch self {
        case .paid:
            return sale
        case .closed, .voided:
            try sale.close(
                documentID: BillingDocumentID(rawValue: globalDiscountUUID(902)),
                closedAt: Date(timeIntervalSinceReferenceDate: 1_102)
            )
        }
        if self == .voided {
            try sale.void(
                reversalID: SaleReversalID(rawValue: globalDiscountUUID(903)),
                voidedAt: Date(timeIntervalSinceReferenceDate: 1_103)
            )
        }
        return sale
    }
}
