import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale calculator monetary boundaries")
struct SaleCalculatorBoundaryTests {
    @Test
    func `A full discount of an extreme representable price leaves zero tax and total`() throws {
        let line = try BoundaryLineFixture(
            price: "10000000000000000000000000000000000000e127",
            tax: "21",
            discount: "100"
        ).line

        let calculation = try SaleCalculator().calculate(lines: [line], currency: .eur)

        try BoundaryAmounts(
            subtotal: "10000000000000000000000000000000000000e127",
            discount: "10000000000000000000000000000000000000e127",
            base: "0",
            tax: "0",
            total: "0"
        ).expect(calculation, currency: .eur)
    }

    @Test
    func `Aggregating an extreme price and one cent rejects the lost cent`() throws {
        let largeLine = try BoundaryLineFixture(price: "10000000000000000000000000000000000000e127").line
        let centLine = try BoundaryLineFixture(price: "0.01", id: "11000000-0000-0000-0000-000000000002").line

        #expect(throws: MoneyError.invalidAmount) {
            try SaleCalculator().calculate(lines: [largeLine, centLine], currency: .eur)
        }
    }

    @Test
    func `Aggregating at the coefficient boundary rejects silent precision loss`() throws {
        let price = "3402823669209384634633746074317682114.55"
        let boundaryLine = try BoundaryLineFixture(price: price).line
        let centLine = try BoundaryLineFixture(price: "0.01", id: "14000000-0000-0000-0000-000000000002").line
        try #require(boundaryLine.unitPrice.amount.description == price)

        #expect(throws: MoneyError.invalidAmount) {
            try SaleCalculator().calculate(lines: [boundaryLine, centLine], currency: .eur)
        }
    }

    @Test(arguments: [Currency.eur, .usd])
    func `Opposite extreme prices cancel exactly and preserve ordered line identity`(_ currency: Currency) throws {
        let positiveID = "15000000-0000-0000-0000-000000000001"
        let negativeID = "15000000-0000-0000-0000-000000000002"
        let positiveLine = try BoundaryLineFixture(
            price: "10000000000000000000000000000000000000e127",
            currency: currency,
            id: positiveID
        ).line
        let negativeLine = try BoundaryLineFixture(
            price: "-10000000000000000000000000000000000000e127",
            currency: currency,
            id: negativeID
        ).line

        let calculation = try SaleCalculator().calculate(lines: [positiveLine, negativeLine], currency: currency)

        try BoundaryAmounts(
            subtotal: "0",
            discount: "0",
            base: "0",
            tax: "0",
            total: "0"
        ).expect(calculation, currency: currency)
        #expect(calculation.lineCalculations.map(\.id.rawValue.uuidString) == [positiveID, negativeID])
    }

    @Test(arguments: [Currency.eur, .usd])
    func `Adding a cent to a negative price preserves the exact borrow and sign`(_ currency: Currency) throws {
        let centLine = try BoundaryLineFixture(price: "0.01", currency: currency).line
        let negativeLine = try BoundaryLineFixture(
            price: "-1.01",
            currency: currency,
            id: "16000000-0000-0000-0000-000000000002"
        ).line

        let calculation = try SaleCalculator().calculate(lines: [centLine, negativeLine], currency: currency)

        try BoundaryAmounts(
            subtotal: "-1",
            discount: "0",
            base: "-1",
            tax: "0",
            total: "-1"
        ).expect(calculation, currency: currency)
    }

    @Test(
        arguments: [
            BoundaryCase(
                price: "0",
                quantity: Int.max,
                tax: "21",
                discount: "100",
                expected: BoundaryAmounts(
                    subtotal: "0",
                    discount: "0",
                    base: "0",
                    tax: "0",
                    total: "0"
                )
            ),
            BoundaryCase(
                price: "1.21",
                quantity: 1,
                tax: "21",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "1.21",
                    discount: "0",
                    base: "1",
                    tax: "0.21",
                    total: "1.21"
                )
            ),
            BoundaryCase(
                price: "1.21",
                quantity: 1,
                tax: "21",
                discount: "0",
                expected: BoundaryAmounts(
                    subtotal: "1.21",
                    discount: "0",
                    base: "1",
                    tax: "0.21",
                    total: "1.21"
                )
            ),
            BoundaryCase(
                price: "12.10",
                quantity: 3,
                tax: "21",
                discount: "12.5",
                expected: BoundaryAmounts(
                    subtotal: "36.30",
                    discount: "4.54",
                    base: "26.25",
                    tax: "5.51",
                    total: "31.76"
                )
            ),
            BoundaryCase(
                price: "9.99",
                quantity: 1,
                tax: "5.5",
                discount: "5.5",
                expected: BoundaryAmounts(
                    subtotal: "9.99",
                    discount: "0.55",
                    base: "8.95",
                    tax: "0.49",
                    total: "9.44"
                )
            ),
            BoundaryCase(
                price: "0.01",
                quantity: Int.max,
                tax: "0",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "92233720368547758.07",
                    discount: "0",
                    base: "92233720368547758.07",
                    tax: "0",
                    total: "92233720368547758.07"
                )
            ),
            BoundaryCase(
                price: "0.03",
                quantity: 1,
                tax: "100",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "0.03",
                    discount: "0",
                    base: "0.02",
                    tax: "0.01",
                    total: "0.03"
                )
            ),
            BoundaryCase(
                price: "-0.03",
                quantity: 1,
                tax: "100",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "-0.03",
                    discount: "0",
                    base: "-0.02",
                    tax: "-0.01",
                    total: "-0.03"
                )
            ),
            BoundaryCase(
                price: "0.05",
                quantity: 1,
                tax: "0",
                discount: "10",
                expected: BoundaryAmounts(
                    subtotal: "0.05",
                    discount: "0.01",
                    base: "0.04",
                    tax: "0",
                    total: "0.04"
                )
            ),
            BoundaryCase(
                price: "-0.05",
                quantity: 1,
                tax: "0",
                discount: "10",
                expected: BoundaryAmounts(
                    subtotal: "-0.05",
                    discount: "-0.01",
                    base: "-0.04",
                    tax: "0",
                    total: "-0.04"
                )
            ),
            BoundaryCase(
                price: "0.02",
                quantity: 1,
                tax: "33.333334",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "0.02",
                    discount: "0",
                    base: "0.01",
                    tax: "0.01",
                    total: "0.02"
                )
            ),
            BoundaryCase(
                price: "0.02",
                quantity: 1,
                tax: "33.333332",
                discount: nil,
                expected: BoundaryAmounts(
                    subtotal: "0.02",
                    discount: "0",
                    base: "0.02",
                    tax: "0",
                    total: "0.02"
                )
            ),
            BoundaryCase(
                price: "19.99",
                quantity: 1,
                tax: "0",
                discount: "12.345678901234567890123456789012345678",
                expected: BoundaryAmounts(
                    subtotal: "19.99",
                    discount: "2.47",
                    base: "17.52",
                    tax: "0",
                    total: "17.52"
                )
            )
        ],
        [Currency.eur, .usd]
    )
    private func `Exact line oracles hold in each supported currency`(
        _ scenario: BoundaryCase,
        currency: Currency
    ) throws {
        let line = try BoundaryLineFixture(
            price: scenario.price,
            quantity: scenario.quantity,
            tax: scenario.tax,
            discount: scenario.discount,
            currency: currency
        ).line

        let calculation = try SaleCalculator().calculate(lines: [line], currency: currency)

        try scenario.expected.expect(calculation, currency: currency)
        let lineCalculation = try #require(calculation.lineCalculations.first)
        try scenario.expected.expect(lineCalculation, currency: currency)
    }

    @Test(
        arguments: [
            (price: "999999999999999999999999999999999999.99", quantity: Int.max),
            (price: "10000000000000000000000000000000000000e127", quantity: 100)
        ],
        [Currency.eur, .usd]
    )
    func `Quantity multiplication rejects precision loss and overflow`(
        _ scenario: (price: String, quantity: Int),
        currency: Currency
    ) throws {
        let line = try BoundaryLineFixture(price: scenario.price, quantity: scenario.quantity, currency: currency).line

        #expect(throws: MoneyError.invalidAmount) {
            try SaleCalculator().calculate(lines: [line], currency: currency)
        }
    }

    @Test(arguments: ["0.03", "-0.03"], [Currency.eur, .usd])
    func `A percentage below the half cent cannot round up silently`(_ price: String, currency: Currency) throws {
        let line = try BoundaryLineFixture(
            price: price,
            discount: "16.666666666666666666666666666666666666",
            currency: currency
        ).line

        do {
            let calculation = try SaleCalculator().calculate(lines: [line], currency: currency)
            let zero = try boundaryMoney("0", currency: currency)
            let expectedTotal = try boundaryMoney(price, currency: currency)

            #expect(calculation.discountAmount == zero)
            #expect(calculation.taxAmount == zero)
            #expect(calculation.taxableBase == expectedTotal)
            #expect(calculation.total == expectedTotal)
        } catch let error as MoneyError {
            #expect(error == .invalidAmount)
        }
    }

    @Test
    func `An unrepresentable tax factor rejects an extreme price instead of hiding tax`() throws {
        let line = try BoundaryLineFixture(price: "10000000000000000000000000000000000000e127", tax: "1e-100").line

        #expect(throws: MoneyError.invalidAmount) {
            try SaleCalculator().calculate(lines: [line], currency: .eur)
        }
    }

    @Test(
        arguments: [
            BoundaryPayload(
                json: #"""
                {
                  "payloadVersion": 1,
                  "id": "12000000-0000-0000-0000-000000000001",
                  "createdAt": "0000000000000000",
                  "lines": [
                    {
                      "id": "12000000-0000-0000-0000-000000000002",
                      "serviceID": "12000000-0000-0000-0000-000000000003",
                      "serviceName": "Historical fractional snapshot",
                      "quantity": 3,
                      "unitPrice": { "amount": "12.1", "currency": "EUR" },
                      "taxRate": { "percentage": "21" },
                      "discount": { "percentage": "12.5" },
                      "status": "upcoming"
                    },
                    {
                      "id": "12000000-0000-0000-0000-000000000004",
                      "serviceID": "12000000-0000-0000-0000-000000000005",
                      "serviceName": "Historical reduced tax snapshot",
                      "quantity": 1,
                      "unitPrice": { "amount": "9.99", "currency": "EUR" },
                      "taxRate": { "percentage": "5.5" },
                      "discount": { "percentage": "5.5" },
                      "status": "upcoming"
                    }
                  ],
                  "status": { "kind": "draft" }
                }
                """#,
                expected: BoundaryAmounts(
                    subtotal: "46.29",
                    discount: "5.09",
                    base: "35.20",
                    tax: "6",
                    total: "41.20"
                )
            ),
            BoundaryPayload(
                json: #"""
                {
                  "payloadVersion": 1,
                  "id": "13000000-0000-0000-0000-000000000001",
                  "createdAt": "0000000000000000",
                  "lines": [
                    {
                      "id": "13000000-0000-0000-0000-000000000002",
                      "serviceID": "13000000-0000-0000-0000-000000000003",
                      "serviceName": "Historical exact percentage snapshot",
                      "quantity": 1,
                      "unitPrice": { "amount": "19.99", "currency": "EUR" },
                      "taxRate": { "percentage": "0" },
                      "discount": { "percentage": "12.345678901234567890123456789012345678" },
                      "status": "upcoming"
                    }
                  ],
                  "status": { "kind": "draft" }
                }
                """#,
                expected: BoundaryAmounts(
                    subtotal: "19.99",
                    discount: "2.47",
                    base: "17.52",
                    tax: "0",
                    total: "17.52"
                )
            )
        ]
    )
    private func `Historical decimal payloads reconstruct the literal monetary breakdown`(
        _ payload: BoundaryPayload
    ) throws {
        let dto = try JSONDecoder().decode(SaleDTO.self, from: Data(payload.json.utf8))
        let sale = try dto.toDomain()

        let calculation = try SaleCalculator().calculate(lines: sale.lines, currency: .eur)

        try payload.expected.expect(calculation, currency: .eur)
    }
}

private struct BoundaryCase {
    let price: String
    let quantity: Int
    let tax: String
    let discount: String?
    let expected: BoundaryAmounts
}

private struct BoundaryPayload {
    let json: String
    let expected: BoundaryAmounts
}

private struct BoundaryAmounts {
    let subtotal: String
    let discount: String
    let base: String
    let tax: String
    let total: String
}

private extension BoundaryAmounts {
    func expect(_ calculation: SaleCalculation, currency: Currency) throws {
        let expectedSubtotal = try boundaryMoney(subtotal, currency: currency)
        let expectedDiscount = try boundaryMoney(discount, currency: currency)
        let expectedBase = try boundaryMoney(base, currency: currency)
        let expectedTax = try boundaryMoney(tax, currency: currency)
        let expectedTotal = try boundaryMoney(total, currency: currency)

        #expect(calculation.subtotal == expectedSubtotal)
        #expect(calculation.discountAmount == expectedDiscount)
        #expect(calculation.taxableBase == expectedBase)
        #expect(calculation.taxAmount == expectedTax)
        #expect(calculation.total == expectedTotal)
    }

    func expect(_ calculation: SaleLineCalculation, currency: Currency) throws {
        let expectedSubtotal = try boundaryMoney(subtotal, currency: currency)
        let expectedDiscount = try boundaryMoney(discount, currency: currency)
        let expectedBase = try boundaryMoney(base, currency: currency)
        let expectedTax = try boundaryMoney(tax, currency: currency)
        let expectedTotal = try boundaryMoney(total, currency: currency)

        #expect(calculation.subtotal == expectedSubtotal)
        #expect(calculation.discountAmount == expectedDiscount)
        #expect(calculation.taxableBase == expectedBase)
        #expect(calculation.taxAmount == expectedTax)
        #expect(calculation.total == expectedTotal)
    }
}

private struct BoundaryLineFixture {
    let line: SaleLine
}

private extension BoundaryLineFixture {
    init(
        price: String,
        quantity: Int = 1,
        tax: String = "0",
        discount: String? = nil,
        currency: Currency = .eur,
        id: String = "11000000-0000-0000-0000-000000000001"
    ) throws {
        let amount = try boundaryDecimal(price)
        let unitPrice = try Money(amount: amount, currency: currency)
        try #require(unitPrice.amount == amount, "The input price must already be representable as Money")
        let lineID = try #require(UUID(uuidString: id))
        let serviceID = try #require(UUID(uuidString: "11000000-0000-0000-0000-000000000003"))
        let line = try SaleLine.upcoming(
            id: SaleLineID(rawValue: lineID),
            serviceID: ServiceID(rawValue: serviceID),
            serviceName: "Boundary snapshot",
            quantity: quantity,
            unitPrice: unitPrice,
            taxRate: TaxRate(percentage: boundaryDecimal(tax)),
            discount: try discount.map { try Discount(percentage: boundaryDecimal($0)) },
            linkedProductID: nil
        )
        self.init(line: line)
    }
}

private func boundaryMoney(_ literal: String, currency: Currency) throws -> Money {
    try Money(amount: boundaryDecimal(literal), currency: currency)
}

private func boundaryDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}
