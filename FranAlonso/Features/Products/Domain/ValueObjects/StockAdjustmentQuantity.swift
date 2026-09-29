import Foundation

/// A nonzero signed delta entered as positive ASCII whole units and an explicit direction.
struct StockAdjustmentQuantity: Equatable {
    private let storedDelta: Int
    var delta: Int { storedDelta }
}

extension StockAdjustmentQuantity {
    /// Accepts outer whitespace and digits from 1 through Int.max; separators and signs are rejected.
    init(unitsText: String, direction: StockAdjustmentDirection) throws {
        let normalized = unitsText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized.utf8.allSatisfy({ (48...57).contains($0) }),
              let magnitude = Int(normalized), magnitude > 0 else { throw StockError.invalidQuantity }
        self.init(storedDelta: direction == .entry ? magnitude : -magnitude)
    }
}
