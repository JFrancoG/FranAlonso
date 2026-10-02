import Foundation
import Testing
@testable import FranAlonso

@Suite("Analyze sale stock impact")
struct AnalyzeSaleStockImpactUseCaseTests {
    private let firstProduct = impactProductID(1)
    private let secondProduct = impactProductID(2)

    @Test(
        "Projects sufficient, exactly depleted, zero and negative stock without blocking",
        arguments: [(3, 1, false), (2, 0, false), (0, -2, true), (-3, -5, true)]
    )
    func projectsStock(scenario: (available: Int, projected: Int, warns: Bool)) throws {
        let line = try impactLine(index: 1, productID: firstProduct, quantity: 2)
        let impacts = try AnalyzeSaleStockImpactUseCase()(
            lines: [line],
            availableQuantities: [firstProduct: scenario.available]
        )

        let impact = try #require(impacts.first)
        #expect(impacts.count == 1)
        #expect(impact.id == line.id)
        #expect(impact.productID == firstProduct)
        #expect(impact.availableQuantity == scenario.available)
        #expect(impact.consumedQuantity == 2)
        #expect(impact.projectedQuantity == scenario.projected)
        #expect(impact.requiresWarning == scenario.warns)
    }

    @Test("Accumulates interleaved product lines in input order and omits professional services")
    func accumulatesInterleavedLines() throws {
        let lines = try [
            impactLine(index: 1, productID: firstProduct, quantity: 2),
            impactLine(index: 2, productID: nil, quantity: 99),
            impactLine(index: 3, productID: secondProduct, quantity: 1),
            impactLine(index: 4, productID: firstProduct, quantity: 2),
            impactLine(index: 5, productID: secondProduct, quantity: 1)
        ]
        let quantities = [firstProduct: 3, secondProduct: 1]
        let impacts = try AnalyzeSaleStockImpactUseCase()(lines: lines, availableQuantities: quantities)

        #expect(impacts.map(\.id) == [lines[0].id, lines[2].id, lines[3].id, lines[4].id])
        #expect(impacts.map(\.productID) == [firstProduct, secondProduct, firstProduct, secondProduct])
        #expect(impacts.map(\.availableQuantity) == [3, 1, 1, 0])
        #expect(impacts.map(\.consumedQuantity) == [2, 1, 2, 1])
        #expect(impacts.map(\.projectedQuantity) == [1, 0, -1, -1])
        #expect(impacts.map(\.requiresWarning) == [false, false, true, true])
        #expect(quantities == [firstProduct: 3, secondProduct: 1])
        #expect(lines.map(\.quantity) == [2, 99, 1, 2, 1])
    }

    @Test("Empty and professional-only sales have no stock impact", arguments: [false, true])
    func returnsNoPhysicalImpact(includeProfessionalLine: Bool) throws {
        let lines = includeProfessionalLine ? [try impactLine(index: 1, productID: nil, quantity: 2)] : []
        let impacts = try AnalyzeSaleStockImpactUseCase()(lines: lines, availableQuantities: [:])

        #expect(impacts.isEmpty)
    }

    @Test("Missing inventory remains a data error rather than a zero-stock warning")
    func propagatesMissingInventory() throws {
        let line = try impactLine(index: 1, productID: firstProduct, quantity: 1)

        #expect(throws: StockWarningPolicyError.missingAvailableQuantity(productID: firstProduct)) {
            try AnalyzeSaleStockImpactUseCase()(lines: [line], availableQuantities: [:])
        }
    }

    @Test("Duplicate line identities are rejected even without a product link")
    func rejectsDuplicateIdentity() throws {
        let line = try impactLine(index: 1, productID: nil, quantity: 1)

        #expect(throws: StockWarningPolicyError.duplicateLineIdentity) {
            try AnalyzeSaleStockImpactUseCase()(lines: [line, line], availableQuantities: [:])
        }
    }

    @Test("Overflow on a later repeated-product line propagates without a partial result")
    func propagatesAccumulatedOverflow() throws {
        let lines = try [
            impactLine(index: 1, productID: firstProduct, quantity: 1),
            impactLine(index: 2, productID: firstProduct, quantity: 1)
        ]

        #expect(throws: StockWarningPolicyError.quantityOverflow(productID: firstProduct)) {
            try AnalyzeSaleStockImpactUseCase()(lines: lines, availableQuantities: [firstProduct: Int.min + 1])
        }
    }
}

private func impactLine(index: UInt8, productID: ProductID?, quantity: Int) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: impactUUID(index)),
        serviceID: ServiceID(rawValue: impactUUID(100)),
        serviceName: "Synthetic service",
        quantity: quantity,
        unitPrice: Money(amount: 1, currency: .eur),
        taxRate: TaxRate(percentage: 0),
        discount: nil,
        linkedProductID: productID
    )
}

private func impactProductID(_ index: UInt8) -> ProductID {
    ProductID(rawValue: impactUUID(index))
}

private func impactUUID(_ index: UInt8) -> UUID {
    UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, index))
}
