import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale reversal domain invariants")
struct SaleReversalDomainTests {
    @Test
    func `captured lines invert exactly and payment document and closure remain immutable`() throws {
        let closed = try saleReversalClosedFixture()
        let voided = try saleReversalVoidedFixture(closed)
        let events = try SaleStockReversalPolicy()(sale: voided, reversalID: saleReversalTestID)
        #expect(events.map(\.quantityDelta) == [2, 3, 4])
        #expect(events.map(\.productID) == [saleStockProductID(1), saleStockProductID(1), saleStockProductID(2)])
        #expect(events.first?.id.rawValue.uuidString == saleReversalLiteralID)
        #expect(events.allSatisfy { $0.occurredAt == saleReversalTestDate })
        #expect(voided.lines == closed.lines)
        #expect(voided.globalDiscount == closed.globalDiscount)
        guard case let .voided(payment, method, paidAt, document, closedAt, reversal, voidedAt) = voided.status else {
            Issue.record("Expected recorded reversal")
            return
        }
        #expect(payment == saleStockPaymentID)
        #expect(method == .cash)
        #expect(paidAt == Date(timeIntervalSinceReferenceDate: 100.125))
        #expect(document.rawValue == saleStockUUID(0xe9, 1))
        #expect(closedAt == Date(timeIntervalSinceReferenceDate: 200.125))
        #expect(reversal == saleReversalTestID)
        #expect(voidedAt == saleReversalTestDate)
        let expectedOrigin = StockMovementOrigin.saleReversal(
            saleID: closed.id,
            lineID: try #require(closed.lines.first).id,
            paymentID: saleStockPaymentID,
            reversalID: saleReversalTestID,
            originalMovementID: StockMovementID(rawValue: try #require(
                UUID(uuidString: "C0969BE6-6A1B-8497-8388-E059E9006643")
            ))
        )
        #expect(events.first?.origin == expectedOrigin)
    }

    @Test(arguments: [false, true])
    func `payment alone never opens the closed reversal lifecycle`(paid: Bool) throws {
        let sale = try saleStockFixture(paid: paid)
        #expect(throws: SaleError.invalidSaleTransition) {
            try SaleReversalAcceptancePolicy()(
                expected: sale,
                current: sale,
                reversalID: saleReversalTestID,
                voidedAt: saleReversalTestDate
            )
        }
        #expect(throws: SaleError.invalidSaleTransition) {
            try SaleStockReversalPolicy()(sale: sale, reversalID: saleReversalTestID)
        }
    }

    @Test(arguments: ["quantity", "payment", "document", "closure"])
    func `closed or voided replay rejects every changed historical term`(field: String) throws {
        let closed = try saleReversalClosedFixture()
        var changed = try saleStockFixture(
            paymentID: field == "payment"
                ? PaymentID(rawValue: saleStockUUID(0xc2, 2)) : saleStockPaymentID,
            firstQuantity: field == "quantity" ? 8 : 2
        )
        try changed.close(
            documentID: BillingDocumentID(rawValue: saleStockUUID(0xe9, field == "document" ? 2 : 1)),
            closedAt: Date(timeIntervalSinceReferenceDate: field == "closure" ? 201.125 : 200.125)
        )
        for current in [closed, try saleReversalVoidedFixture(closed)] {
            #expect(throws: SaleReversalError.staleSale) {
                try SaleReversalAcceptancePolicy()(
                    expected: changed,
                    current: current,
                    reversalID: saleReversalTestID,
                    voidedAt: saleReversalTestDate
                )
            }
        }
    }
}
