import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale calculator")
struct SaleCalculatorTests {
    @Test("Returns zero amounts for an empty sale")
    func returnsZeroAmountsForAnEmptySale() throws {
        let calculation = try SaleCalculator().calculate(
            lines: [],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "0",
            discount: "0",
            taxableBase: "0",
            tax: "0",
            total: "0"
        )
        #expect(calculation.lineCalculations.isEmpty)
    }

    @Test("Extracts included tax from quantity-adjusted price")
    func extractsIncludedTaxFromQuantityAdjustedPrice() throws {
        let line = try calculatorLine(
            unitPrice: "12.10",
            quantity: 2,
            taxRate: "21"
        )

        let calculation = try SaleCalculator().calculate(
            lines: [line],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "24.20",
            discount: "0",
            taxableBase: "20",
            tax: "4.20",
            total: "24.20"
        )
    }

    @Test("Applies the line discount before extracting tax")
    func appliesTheLineDiscountBeforeExtractingTax() throws {
        let line = try calculatorLine(
            unitPrice: "100",
            taxRate: "21",
            discount: "10"
        )

        let calculation = try SaleCalculator().calculate(
            lines: [line],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "100",
            discount: "10",
            taxableBase: "74.38",
            tax: "15.62",
            total: "90"
        )
    }

    @Test("Aggregates independently rounded mixed tax lines")
    func aggregatesIndependentlyRoundedMixedTaxLines() throws {
        let standardTaxLine = try calculatorLine(
            id: calculatorUUID("10000000-0000-0000-0000-000000000001"),
            unitPrice: "10",
            taxRate: "21"
        )
        let reducedTaxLine = try calculatorLine(
            id: calculatorUUID("10000000-0000-0000-0000-000000000002"),
            unitPrice: "10",
            taxRate: "10"
        )

        let calculation = try SaleCalculator().calculate(
            lines: [standardTaxLine, reducedTaxLine],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "20",
            discount: "0",
            taxableBase: "17.35",
            tax: "2.65",
            total: "20"
        )
        #expect(calculation.lineCalculations.count == 2)
        let firstCalculation = try #require(calculation.lineCalculations.first)
        let secondCalculation = try #require(calculation.lineCalculations.last)
        try expectAmounts(
            firstCalculation,
            subtotal: "10",
            discount: "0",
            taxableBase: "8.26",
            tax: "1.74",
            total: "10"
        )
        try expectAmounts(
            secondCalculation,
            subtotal: "10",
            discount: "0",
            taxableBase: "9.09",
            tax: "0.91",
            total: "10"
        )
    }

    @Test("Rounds discount for each line before aggregation")
    func roundsDiscountForEachLineBeforeAggregation() throws {
        let firstLine = try calculatorLine(
            id: calculatorUUID("20000000-0000-0000-0000-000000000001"),
            unitPrice: "0.05",
            taxRate: "0",
            discount: "10"
        )
        let secondLine = try calculatorLine(
            id: calculatorUUID("20000000-0000-0000-0000-000000000002"),
            unitPrice: "0.05",
            taxRate: "0",
            discount: "10"
        )

        let calculation = try SaleCalculator().calculate(
            lines: [firstLine, secondLine],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "0.10",
            discount: "0.02",
            taxableBase: "0.08",
            tax: "0",
            total: "0.08"
        )
        for lineCalculation in calculation.lineCalculations {
            try expectAmounts(
                lineCalculation,
                subtotal: "0.05",
                discount: "0.01",
                taxableBase: "0.04",
                tax: "0",
                total: "0.04"
            )
        }
    }

    @Test("Allows a full discount without negative amounts")
    func allowsAFullDiscountWithoutNegativeAmounts() throws {
        let line = try calculatorLine(
            unitPrice: "35",
            taxRate: "21",
            discount: "100"
        )

        let calculation = try SaleCalculator().calculate(
            lines: [line],
            currency: .eur
        )

        try expectAmounts(
            calculation,
            subtotal: "35",
            discount: "35",
            taxableBase: "0",
            tax: "0",
            total: "0"
        )
    }

    @Test("Rejects a line expressed in another currency")
    func rejectsALineExpressedInAnotherCurrency() throws {
        let line = try calculatorLine(
            unitPrice: "10",
            taxRate: "21",
            currency: .usd
        )

        #expect(
            throws: SaleCalculatorError.incompatibleCurrency(
                expected: .eur,
                actual: .usd
            )
        ) {
            try SaleCalculator().calculate(
                lines: [line],
                currency: .eur
            )
        }
    }

    @Test("Rejects duplicate line identity")
    func rejectsDuplicateLineIdentity() throws {
        let line = try calculatorLine(
            unitPrice: "10",
            taxRate: "21"
        )

        #expect(throws: SaleCalculatorError.duplicateLineIdentity) {
            try SaleCalculator().calculate(
                lines: [line, line],
                currency: .eur
            )
        }
    }

    @Test("Preserves line identity and input order")
    func preservesLineIdentityAndInputOrder() throws {
        let firstID = SaleLineID(
            rawValue: calculatorUUID("30000000-0000-0000-0000-000000000001")
        )
        let secondID = SaleLineID(
            rawValue: calculatorUUID("30000000-0000-0000-0000-000000000002")
        )
        let lines = [
            try calculatorLine(id: firstID.rawValue, unitPrice: "10", taxRate: "21"),
            try calculatorLine(id: secondID.rawValue, unitPrice: "20", taxRate: "10")
        ]

        let calculation = try SaleCalculator().calculate(
            lines: lines,
            currency: .eur
        )

        #expect(calculation.lineCalculations.map(\.id) == [firstID, secondID])
    }

    @Test("Calculation values are deterministic")
    func calculationValuesAreDeterministic() throws {
        let lines = [try calculatorLine(unitPrice: "19.99", taxRate: "21")]
        let calculation = try SaleCalculator().calculate(
            lines: lines,
            currency: .eur
        )
        let repeatedCalculation = try SaleCalculator().calculate(
            lines: lines,
            currency: .eur
        )

        #expect(repeatedCalculation == calculation)
    }
}

private func calculatorLine(
    id: UUID = calculatorUUID("00000000-0000-0000-0000-000000000001"),
    unitPrice: String,
    quantity: Int = 1,
    taxRate: String,
    discount: String? = nil,
    currency: Currency = .eur
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: id),
        serviceID: ServiceID(rawValue: calculatorUUID("00000000-0000-0000-0000-000000000002")),
        serviceName: "Servicio snapshot",
        quantity: quantity,
        unitPrice: Money(
            amount: calculatorDecimal(unitPrice),
            currency: currency
        ),
        taxRate: TaxRate(percentage: calculatorDecimal(taxRate)),
        discount: try discount.map {
            try Discount(percentage: calculatorDecimal($0))
        },
        linkedProductID: nil
    )
}

private func expectAmounts(
    _ calculation: SaleCalculation,
    subtotal: String,
    discount: String,
    taxableBase: String,
    tax: String,
    total: String
) throws {
    let currency = calculation.total.currency
    let expectedSubtotal = try calculatorMoney(subtotal, currency: currency)
    let expectedDiscount = try calculatorMoney(discount, currency: currency)
    let expectedTaxableBase = try calculatorMoney(taxableBase, currency: currency)
    let expectedTax = try calculatorMoney(tax, currency: currency)
    let expectedTotal = try calculatorMoney(total, currency: currency)

    #expect(calculation.subtotal == expectedSubtotal)
    #expect(calculation.discountAmount == expectedDiscount)
    #expect(calculation.taxableBase == expectedTaxableBase)
    #expect(calculation.taxAmount == expectedTax)
    #expect(calculation.total == expectedTotal)
}

private func expectAmounts(
    _ calculation: SaleLineCalculation,
    subtotal: String,
    discount: String,
    taxableBase: String,
    tax: String,
    total: String
) throws {
    let currency = calculation.total.currency
    let expectedSubtotal = try calculatorMoney(subtotal, currency: currency)
    let expectedDiscount = try calculatorMoney(discount, currency: currency)
    let expectedTaxableBase = try calculatorMoney(taxableBase, currency: currency)
    let expectedTax = try calculatorMoney(tax, currency: currency)
    let expectedTotal = try calculatorMoney(total, currency: currency)

    #expect(calculation.subtotal == expectedSubtotal)
    #expect(calculation.discountAmount == expectedDiscount)
    #expect(calculation.taxableBase == expectedTaxableBase)
    #expect(calculation.taxAmount == expectedTax)
    #expect(calculation.total == expectedTotal)
}

private func calculatorMoney(_ value: String, currency: Currency) throws -> Money {
    try Money(
        amount: calculatorDecimal(value),
        currency: currency
    )
}

private func calculatorDecimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
}

private func calculatorUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
