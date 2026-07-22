import Foundation

enum DiscountError: Error, Equatable {
    case outOfRange
}

struct Discount: Codable, Equatable, Hashable {
    let percentage: Decimal

    init(percentage: Decimal) throws {
        guard !percentage.isNaN, (Decimal.zero ... 100).contains(percentage) else {
            throw DiscountError.outOfRange
        }

        self.percentage = percentage
    }

    private enum CodingKeys: String, CodingKey {
        case percentage
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            percentage: container.decode(Decimal.self, forKey: .percentage)
        )
    }
}
