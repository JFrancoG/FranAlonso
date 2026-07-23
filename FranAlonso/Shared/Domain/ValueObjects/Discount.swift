import Foundation

/// Errors produced while validating a discount.
enum DiscountError: Error, Equatable {
    /// The percentage is not a number or lies outside the closed range `0...100`.
    case outOfRange
}

/// A discount expressed in percentage points within the closed range `0...100`.
///
/// For example, `15` represents a 15 percent discount. Construction and decoding
/// enforce the range.
struct Discount: Codable, Hashable {
    private let storedPercentage: Decimal

    var percentage: Decimal {
        storedPercentage
    }

    private enum CodingKeys: String, CodingKey {
        case percentage
    }
}

extension Discount {
    /// Creates a discount from percentage points.
    ///
    /// - Parameter percentage: A decimal value in the closed range `0...100`.
    /// - Throws: `DiscountError.outOfRange` when `percentage` is not a number or
    ///   lies outside the accepted range.
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
