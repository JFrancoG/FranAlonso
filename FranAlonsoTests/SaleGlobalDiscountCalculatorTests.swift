import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale global discount monetary policy")
struct SaleGlobalDiscountCalculatorTests {
    @Test(
        arguments: [
            GlobalDiscountOracle(
                price: "100",
                linePercentage: "10",
                globalPercentage: "20",
                taxPercentage: "21",
                lineAmount: "10",
                globalAmount: "18",
                discountAmount: "28",
                base: "59.50",
                tax: "12.50",
                total: "72"
            ),
            GlobalDiscountOracle(
                price: "-100",
                linePercentage: "10",
                globalPercentage: "20",
                taxPercentage: "21",
                lineAmount: "-10",
                globalAmount: "-18",
                discountAmount: "-28",
                base: "-59.50",
                tax: "-12.50",
                total: "-72"
            ),
            GlobalDiscountOracle(
                price: "0.07",
                linePercentage: "50",
                globalPercentage: "50",
                taxPercentage: "0",
                lineAmount: "0.04",
                globalAmount: "0.02",
                discountAmount: "0.06",
                base: "0.01",
                tax: "0",
                total: "0.01"
            ),
            GlobalDiscountOracle(
                price: "0.05",
                linePercentage: nil,
                globalPercentage: "10",
                taxPercentage: "0",
                lineAmount: "0",
                globalAmount: "0.01",
                discountAmount: "0.01",
                base: "0.04",
                tax: "0",
                total: "0.04"
            ),
            GlobalDiscountOracle(
                price: "-0.05",
                linePercentage: nil,
                globalPercentage: "10",
                taxPercentage: "0",
                lineAmount: "0",
                globalAmount: "-0.01",
                discountAmount: "-0.01",
                base: "-0.04",
                tax: "0",
                total: "-0.04"
            ),
            GlobalDiscountOracle(
                price: "100",
                linePercentage: "100",
                globalPercentage: "20",
                taxPercentage: "21",
                lineAmount: "100",
                globalAmount: "0",
                discountAmount: "100",
                base: "0",
                tax: "0",
                total: "0"
            ),
            GlobalDiscountOracle(
                price: "100",
                linePercentage: "10",
                globalPercentage: "100",
                taxPercentage: "21",
                lineAmount: "10",
                globalAmount: "90",
                discountAmount: "100",
                base: "0",
                tax: "0",
                total: "0"
            ),
            GlobalDiscountOracle(
                price: "12.10",
                linePercentage: "0",
                globalPercentage: "0",
                taxPercentage: "21",
                lineAmount: "0",
                globalAmount: "0",
                discountAmount: "0",
                base: "10",
                tax: "2.10",
                total: "12.10"
            ),
            GlobalDiscountOracle(
                price: "100",
                linePercentage: "10",
                globalPercentage: nil,
                taxPercentage: "0",
                lineAmount: "10",
                globalAmount: "0",
                discountAmount: "10",
                base: "90",
                tax: "0",
                total: "90"
            ),
            GlobalDiscountOracle(
                price: "19.99",
                linePercentage: nil,
                globalPercentage: "12.345678901234567890123456789012345678",
                taxPercentage: "0",
                lineAmount: "0",
                globalAmount: "2.47",
                discountAmount: "2.47",
                base: "17.52",
                tax: "0",
                total: "17.52"
            ),
            GlobalDiscountOracle(
                price: "19.99",
                linePercentage: "12.5",
                globalPercentage: "12.345678901234567890123456789012345678",
                taxPercentage: "21",
                lineAmount: "2.50",
                globalAmount: "2.16",
                discountAmount: "4.66",
                base: "12.67",
                tax: "2.66",
                total: "15.33"
            )
        ],
        [Currency.eur, .usd]
    )
    private func `each stage rounds before included tax is extracted`(
        oracle: GlobalDiscountOracle,
        currency: Currency
    ) throws {
        let line = try globalDiscountLine(
            price: oracle.price,
            lineDiscount: oracle.linePercentage,
            tax: oracle.taxPercentage,
            currency: currency
        )
        let sale = try globalDiscountSale(lines: [line], percentage: oracle.globalPercentage)

        let calculation = try SaleCalculator().calculate(sale: sale, currency: currency)

        #expect(calculation.subtotal == (try globalDiscountMoney(oracle.price, currency: currency)))
        #expect(calculation.lineDiscountAmount == (try globalDiscountMoney(oracle.lineAmount, currency: currency)))
        #expect(calculation.globalDiscountAmount == (try globalDiscountMoney(oracle.globalAmount, currency: currency)))
        #expect(calculation.discountAmount == (try globalDiscountMoney(oracle.discountAmount, currency: currency)))
        #expect(calculation.taxableBase == (try globalDiscountMoney(oracle.base, currency: currency)))
        #expect(calculation.taxAmount == (try globalDiscountMoney(oracle.tax, currency: currency)))
        #expect(calculation.total == (try globalDiscountMoney(oracle.total, currency: currency)))
        let projection = try #require(calculation.lineCalculations.first)
        #expect(projection.lineDiscountAmount == (try globalDiscountMoney(oracle.lineAmount, currency: currency)))
        #expect(projection.globalDiscountAmount == (try globalDiscountMoney(oracle.globalAmount, currency: currency)))
        #expect(projection.discountAmount == (try globalDiscountMoney(oracle.discountAmount, currency: currency)))
        #expect(projection.taxableBase == (try globalDiscountMoney(oracle.base, currency: currency)))
        #expect(projection.taxAmount == (try globalDiscountMoney(oracle.tax, currency: currency)))
        #expect(projection.total == (try globalDiscountMoney(oracle.total, currency: currency)))
    }

    @Test(arguments: [Currency.eur, .usd])
    func `global rounding occurs per line rather than against the sale aggregate`(_ currency: Currency) throws {
        let first = try globalDiscountLine(price: "0.05", lineDiscount: nil, currency: currency)
        let second = try globalDiscountLine(
            price: "0.05",
            lineDiscount: nil,
            currency: currency,
            index: 2
        )
        let sale = try globalDiscountSale(lines: [first, second], percentage: "10")

        let calculation = try SaleCalculator().calculate(sale: sale, currency: currency)

        let fourCents = try globalDiscountDecimal("0.04")
        #expect(calculation.lineCalculations.map(\.total.amount) == [fourCents, fourCents])
        #expect(calculation.lineDiscountAmount.amount == 0)
        #expect(calculation.globalDiscountAmount.amount == (try globalDiscountDecimal("0.02")))
        #expect(calculation.discountAmount.amount == (try globalDiscountDecimal("0.02")))
        #expect(calculation.total.amount == (try globalDiscountDecimal("0.08")))
        #expect(calculation.lineCalculations.map(\.id) == [first.id, second.id])
    }

    @Test(arguments: [Currency.eur, .usd])
    func `an empty sale retains a global term and produces zero in its explicit currency`(_ currency: Currency) throws {
        let sale = try globalDiscountSale(lines: [], percentage: "100")

        let calculation = try SaleCalculator().calculate(sale: sale, currency: currency)

        #expect(calculation.lineCalculations.isEmpty)
        #expect(calculation.subtotal == (try globalDiscountMoney("0", currency: currency)))
        #expect(calculation.lineDiscountAmount == (try globalDiscountMoney("0", currency: currency)))
        #expect(calculation.globalDiscountAmount == (try globalDiscountMoney("0", currency: currency)))
        #expect(calculation.total == (try globalDiscountMoney("0", currency: currency)))
    }

    @Test(arguments: [Currency.eur, .usd])
    func `a complete global discount certifies an extreme representable subtotal`(_ currency: Currency) throws {
        let price = "10000000000000000000000000000000000000e127"
        let sale = try globalDiscountSale(
            lines: [
                globalDiscountLine(
                    price: price,
                    lineDiscount: nil,
                    tax: "21",
                    currency: currency
                )
            ],
            percentage: "100"
        )

        let calculation = try SaleCalculator().calculate(sale: sale, currency: currency)

        #expect(calculation.globalDiscountAmount == (try globalDiscountMoney(price, currency: currency)))
        #expect(calculation.total.amount == 0)
        #expect(calculation.taxableBase.amount == 0)
        #expect(calculation.taxAmount.amount == 0)
    }

    @Test(
        arguments: [
            ("999999999999999999999999999999999999.99", Int.max),
            ("10000000000000000000000000000000000000e127", 100)
        ],
        [Currency.eur, .usd]
    )
    func `a global discount cannot hide subtotal precision loss or overflow`(
        scenario: (String, Int),
        currency: Currency
    ) throws {
        let line = try globalDiscountLine(price: scenario.0, currency: currency, quantity: scenario.1)
        let sale = try globalDiscountSale(lines: [line], percentage: "100")

        #expect(throws: MoneyError.invalidAmount) {
            try SaleCalculator().calculate(sale: sale, currency: currency)
        }
    }

    @Test
    func `a global discount does not permit mixed currencies`() throws {
        let sale = try globalDiscountSale(lines: [globalDiscountLine(price: "100", currency: .usd)], percentage: "20")

        #expect(throws: SaleCalculatorError.incompatibleCurrency(expected: .eur, actual: .usd)) {
            try SaleCalculator().calculate(sale: sale, currency: .eur)
        }
    }
}

private struct GlobalDiscountOracle {
    let price: String
    let linePercentage: String?
    let globalPercentage: String?
    let taxPercentage: String
    let lineAmount: String
    let globalAmount: String
    let discountAmount: String
    let base: String
    let tax: String
    let total: String
}

func globalDiscountSale(lines: [SaleLine], percentage: String? = "20") throws -> Sale {
    try Sale.draft(
        id: SaleID(rawValue: globalDiscountUUID(500)),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 1_100),
        lines: lines,
        globalDiscount: try percentage.map {
            try SaleGlobalDiscount(discount: Discount(percentage: globalDiscountDecimal($0)), policy: .lineThenGlobalV1)
        }
    )
}

func globalDiscountLine(
    price: String = "100",
    lineDiscount: String? = "10",
    tax: String = "0",
    currency: Currency = .eur,
    index: Int = 1,
    quantity: Int = 1
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: globalDiscountUUID(index)),
        serviceID: ServiceID(rawValue: globalDiscountUUID(100 + index)),
        serviceName: "Captured promotion",
        quantity: quantity,
        unitPrice: globalDiscountMoney(price, currency: currency),
        taxRate: TaxRate(percentage: globalDiscountDecimal(tax)),
        discount: try lineDiscount.map { try Discount(percentage: globalDiscountDecimal($0)) },
        linkedProductID: nil
    )
}

func globalDiscountMoney(_ literal: String, currency: Currency = .eur) throws -> Money {
    try Money(amount: globalDiscountDecimal(literal), currency: currency)
}

func globalDiscountDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}

func globalDiscountUUID(_ index: Int) -> UUID {
    UUID(uuidString: String(format: "11720000-0000-0000-0000-%012d", index))!
}
