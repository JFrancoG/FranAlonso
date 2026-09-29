/// A nonnegative caller-selected minimum in whole units, fixed for one stock observation.
///
/// Zero is valid; decoding applies the same invariant as direct construction.
struct StockMinimum: Codable, Equatable {
    enum ValidationError: Error, Equatable {
        case invalidValue
    }

    private let storedValue: Int
    var value: Int { storedValue }
}

extension StockMinimum {
    /// Rejects negative minima before a stock observation can be created.
    init(_ value: Int) throws {
        guard value >= 0 else { throw ValidationError.invalidValue }
        self.init(storedValue: value)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(container.decode(Int.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
