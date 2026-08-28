import Foundation
import Testing
@testable import FranAlonso

@Suite("Money")
struct MoneyTests {
    @Test("Rounds to the currency minor units")
    func roundsToTheCurrencyMinorUnits() throws {
        let money = try Money(
            amount: decimal("10.005"),
            currency: .eur
        )
        let amount: Decimal = money.amount

        #expect(amount == decimal("10.01"))
        #expect(money.currency == .eur)
    }

    @Test("Rejects nonnumeric amounts")
    func rejectsNonnumericAmounts() {
        #expect(throws: MoneyError.invalidAmount) {
            try Money(amount: .nan, currency: .eur)
        }
    }

    @Test("Adds values that share a currency")
    func addsValuesThatShareACurrency() throws {
        let left = try Money(amount: decimal("12.34"), currency: .eur)
        let right = try Money(amount: decimal("0.666"), currency: .eur)

        let result = try left.adding(right)
        let expected = try Money(amount: decimal("13.01"), currency: .eur)

        #expect(result == expected)
    }

    @Test("Rejects arithmetic between incompatible currencies")
    func rejectsArithmeticBetweenIncompatibleCurrencies() throws {
        let euros = try Money(amount: decimal("10"), currency: .eur)
        let dollars = try Money(amount: decimal("10"), currency: .usd)

        #expect(
            throws: MoneyError.incompatibleCurrencies(
                expected: .eur,
                actual: .usd
            )
        ) {
            try euros.adding(dollars)
        }
    }

    @Test("Preserves value through a Codable round trip")
    func preservesValueThroughACodableRoundTrip() throws {
        let money = try Money(amount: decimal("19.995"), currency: .eur)

        #expect(try roundTrip(money) == money)
    }

    @Test("Decoding normalizes the amount to currency minor units")
    func decodingNormalizesTheAmountToCurrencyMinorUnits() throws {
        let data = Data(#"{"amount":10.005,"currency":"EUR"}"#.utf8)

        let money = try JSONDecoder().decode(Money.self, from: data)

        #expect(money.amount == decimal("10.01"))
        #expect(money.currency == .eur)
    }
}

@Suite("Tax rate")
struct TaxRateTests {
    @Test(
        "Accepts percentages inside the closed range",
        arguments: ["0", "21", "100"]
    )
    func acceptsPercentagesInsideTheClosedRange(_ rawPercentage: String) throws {
        let percentage = decimal(rawPercentage)

        #expect(try TaxRate(percentage: percentage).percentage == percentage)
    }

    @Test(
        "Rejects percentages outside the closed range",
        arguments: ["-0.01", "100.01"]
    )
    func rejectsPercentagesOutsideTheClosedRange(_ rawPercentage: String) {
        #expect(throws: TaxRateError.outOfRange) {
            try TaxRate(percentage: decimal(rawPercentage))
        }
    }

    @Test("Rejects a nonnumeric percentage")
    func rejectsANonnumericPercentage() {
        #expect(throws: TaxRateError.outOfRange) {
            try TaxRate(percentage: .nan)
        }
    }

    @Test("Decoding cannot bypass percentage validation")
    func decodingCannotBypassPercentageValidation() {
        let data = Data(#"{"percentage":101}"#.utf8)

        #expect(throws: TaxRateError.outOfRange) {
            try JSONDecoder().decode(TaxRate.self, from: data)
        }
    }
}

@Suite("Discount")
struct DiscountTests {
    @Test(
        "Accepts percentages inside the closed range",
        arguments: ["0", "15", "100"]
    )
    func acceptsPercentagesInsideTheClosedRange(_ rawPercentage: String) throws {
        let percentage = decimal(rawPercentage)

        #expect(try Discount(percentage: percentage).percentage == percentage)
    }

    @Test(
        "Rejects percentages outside the closed range",
        arguments: ["-0.01", "100.01"]
    )
    func rejectsPercentagesOutsideTheClosedRange(_ rawPercentage: String) {
        #expect(throws: DiscountError.outOfRange) {
            try Discount(percentage: decimal(rawPercentage))
        }
    }

    @Test("Rejects a nonnumeric percentage")
    func rejectsANonnumericPercentage() {
        #expect(throws: DiscountError.outOfRange) {
            try Discount(percentage: .nan)
        }
    }

    @Test("Decoding cannot bypass percentage validation")
    func decodingCannotBypassPercentageValidation() {
        let data = Data(#"{"percentage":101}"#.utf8)

        #expect(throws: DiscountError.outOfRange) {
            try JSONDecoder().decode(Discount.self, from: data)
        }
    }
}

private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
}

private func roundTrip<Value: Codable>(_ value: Value) throws -> Value {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(Value.self, from: data)
}
