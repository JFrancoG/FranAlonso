import Foundation

/// A supported currency whose ISO code and minor-unit scale govern monetary normalization.
enum Currency: String, Codable, CaseIterable {
    case eur = "EUR"
    case usd = "USD"

    fileprivate var minorUnitScale: Int {
        switch self {
        case .eur, .usd:
            2
        }
    }
}

/// Errors produced while creating or combining monetary values.
enum MoneyError: Error, Equatable {
    /// The amount is not a number.
    case invalidAmount

    /// The operands use different currencies.
    case incompatibleCurrencies(expected: Currency, actual: Currency)
}

/// A decimal monetary value normalized to the minor units of its currency.
///
/// Construction and decoding use `NSDecimalNumber.RoundingMode.plain` and reject
/// amounts that are not numbers.
struct Money: Codable, Equatable, Hashable {
    private let storedAmount: Decimal
    let currency: Currency

    /// The amount after currency-specific minor-unit normalization.
    var amount: Decimal {
        storedAmount
    }

    /// Adds another monetary value expressed in the same currency.
    ///
    /// - Parameter other: The monetary value to add.
    /// - Returns: The sum normalized to the shared currency's minor units.
    /// - Throws: `MoneyError.incompatibleCurrencies` when the currencies differ,
    ///   or `MoneyError.invalidAmount` when the resulting amount is not a number.
    func adding(_ other: Money) throws -> Money {
        guard currency == other.currency else {
            throw MoneyError.incompatibleCurrencies(
                expected: currency,
                actual: other.currency
            )
        }

        return try Money(
            amount: amount + other.amount,
            currency: currency
        )
    }

    private enum CodingKeys: String, CodingKey {
        case amount
        case currency
    }
}

extension Money {
    /// Creates a monetary value normalized to the minor units of `currency`.
    ///
    /// Rounding uses `NSDecimalNumber.RoundingMode.plain`.
    /// - Parameters:
    ///   - amount: The decimal amount to normalize.
    ///   - currency: The currency that determines the minor-unit scale.
    /// - Throws: `MoneyError.invalidAmount` when `amount` is not a number.
    init(amount: Decimal, currency: Currency) throws {
        guard !amount.isNaN else {
            throw MoneyError.invalidAmount
        }

        self.init(
            storedAmount: amount.rounded(
                scale: currency.minorUnitScale,
                mode: .plain
            ),
            currency: currency
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            amount: container.decode(Decimal.self, forKey: .amount),
            currency: container.decode(Currency.self, forKey: .currency)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
    }
}

private extension Decimal {
    func rounded(
        scale: Int,
        mode: NSDecimalNumber.RoundingMode
    ) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }
}
