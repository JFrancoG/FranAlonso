import Foundation

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

enum MoneyError: Error, Equatable {
    case invalidAmount
    case incompatibleCurrencies(expected: Currency, actual: Currency)
}

struct Money: Codable, Equatable, Hashable {
    private let storedAmount: Decimal
    let currency: Currency

    var amount: Decimal {
        storedAmount
    }

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
