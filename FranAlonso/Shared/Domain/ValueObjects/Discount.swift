import Foundation

enum DiscountError: Error, Equatable {
    case outOfRange
}

struct Discount: Codable, Equatable, Hashable {
    private let storedPercentage: Decimal

    var percentage: Decimal {
        storedPercentage
    }

    private enum CodingKeys: String, CodingKey {
        case percentage
    }
}

extension Discount {
    init(percentage: Decimal) throws {
        guard !percentage.isNaN, (Decimal.zero ... 100).contains(percentage) else {
            throw DiscountError.outOfRange
        }

        self.init(storedPercentage: percentage)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            percentage: container.decode(Decimal.self, forKey: .percentage)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(percentage, forKey: .percentage)
    }
}
