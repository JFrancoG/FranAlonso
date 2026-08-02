import Foundation
import Testing
@testable import FranAlonso

@Suite("Stock warning policy")
struct StockWarningPolicyTests {
    @Test("Keeps sufficient stock warning-free")
    func keepsSufficientStockWarningFree() throws {
        let productID = stockProductID("10000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 2)

        let impacts = try StockWarningPolicy().analyze(
            lines: [line],
            availableQuantities: [productID: 3]
        )

        let impact = try #require(impacts.first)
        #expect(impacts.count == 1)
        #expect(impact.id == line.id)
        #expect(impact.productID == productID)
        #expect(impact.availableQuantity == 3)
        #expect(impact.consumedQuantity == 2)
        #expect(impact.projectedQuantity == 1)
        #expect(impact.requiresWarning == false)
    }

    @Test("Treats exact stock depletion as sufficient")
    func treatsExactStockDepletionAsSufficient() throws {
        let productID = stockProductID("20000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 2)

        let impacts = try StockWarningPolicy().analyze(
            lines: [line],
            availableQuantities: [productID: 2]
        )

        let impact = try #require(impacts.first)
        #expect(impact.projectedQuantity == 0)
        #expect(impact.requiresWarning == false)
    }

    @Test(
        "Warns without rejecting insufficient stock",
        arguments: [0, -2]
    )
    func warnsWithoutRejectingInsufficientStock(availableQuantity: Int) throws {
        let productID = stockProductID("30000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 1)

        let impacts = try StockWarningPolicy().analyze(
            lines: [line],
            availableQuantities: [productID: availableQuantity]
        )

        let impact = try #require(impacts.first)
        #expect(impact.availableQuantity == availableQuantity)
        #expect(impact.projectedQuantity == availableQuantity - 1)
        #expect(impact.requiresWarning)
    }

    @Test("Accumulates repeated product lines in input order")
    func accumulatesRepeatedProductLinesInInputOrder() throws {
        let productID = stockProductID("40000000-0000-0000-0000-000000000001")
        let firstLine = try stockLine(
            id: stockLineID("40000000-0000-0000-0000-000000000002"),
            productID: productID,
            quantity: 2
        )
        let secondLine = try stockLine(
            id: stockLineID("40000000-0000-0000-0000-000000000003"),
            productID: productID,
            quantity: 2
        )

        let impacts = try StockWarningPolicy().analyze(
            lines: [firstLine, secondLine],
            availableQuantities: [productID: 3]
        )

        #expect(impacts.map(\.id) == [firstLine.id, secondLine.id])
        #expect(impacts.map(\.availableQuantity) == [3, 1])
        #expect(impacts.map(\.projectedQuantity) == [1, -1])
        #expect(impacts.map(\.requiresWarning) == [false, true])
    }

    @Test("Ignores lines without physical inventory")
    func ignoresLinesWithoutPhysicalInventory() throws {
        let line = try stockLine(productID: nil, quantity: 3)

        let impacts = try StockWarningPolicy().analyze(
            lines: [line],
            availableQuantities: [:]
        )

        #expect(impacts.isEmpty)
    }

    @Test("Rejects missing stock for a linked product")
    func rejectsMissingStockForALinkedProduct() throws {
        let productID = stockProductID("50000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 1)

        #expect(
            throws: StockWarningPolicyError.missingAvailableQuantity(
                productID: productID
            )
        ) {
            try StockWarningPolicy().analyze(
                lines: [line],
                availableQuantities: [:]
            )
        }
    }

    @Test("Rejects duplicate sale-line identity")
    func rejectsDuplicateSaleLineIdentity() throws {
        let productID = stockProductID("60000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 1)

        #expect(throws: StockWarningPolicyError.duplicateLineIdentity) {
            try StockWarningPolicy().analyze(
                lines: [line, line],
                availableQuantities: [productID: 2]
            )
        }
    }

    @Test("Rejects stock arithmetic overflow")
    func rejectsStockArithmeticOverflow() throws {
        let productID = stockProductID("70000000-0000-0000-0000-000000000001")
        let line = try stockLine(productID: productID, quantity: 1)

        #expect(
            throws: StockWarningPolicyError.quantityOverflow(
                productID: productID
            )
        ) {
            try StockWarningPolicy().analyze(
                lines: [line],
                availableQuantities: [productID: .min]
            )
        }
    }

    @Test("Produces deterministic Sendable values")
    func producesDeterministicSendableValues() throws {
        let productID = stockProductID("80000000-0000-0000-0000-000000000001")
        let lines = [try stockLine(productID: productID, quantity: 2)]
        let policy = StockWarningPolicy()
        let first = try policy.analyze(
            lines: lines,
            availableQuantities: [productID: 4]
        )
        let repeated = try policy.analyze(
            lines: lines,
            availableQuantities: [productID: 4]
        )

        #expect(repeated == first)
        requireStockSendable(first)
        requireStockSendable(policy)
    }
}

private func stockLine(
    id: SaleLineID = stockLineID("00000000-0000-0000-0000-000000000001"),
    productID: ProductID?,
    quantity: Int
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: id,
        serviceID: ServiceID(
            rawValue: stockUUID("00000000-0000-0000-0000-000000000002")
        ),
        serviceName: "Service snapshot",
        quantity: quantity,
        unitPrice: Money(amount: 1, currency: .eur),
        taxRate: TaxRate(percentage: 0),
        discount: nil,
        linkedProductID: productID
    )
}

private func stockProductID(_ value: String) -> ProductID {
    ProductID(rawValue: stockUUID(value))
}

private func stockLineID(_ value: String) -> SaleLineID {
    SaleLineID(rawValue: stockUUID(value))
}

private func stockUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private func requireStockSendable<Value: Sendable>(_ value: Value) {}
