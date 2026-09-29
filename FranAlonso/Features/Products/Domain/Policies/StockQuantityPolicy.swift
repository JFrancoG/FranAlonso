/// Derives physical units using exact accumulation independent of ledger fetch order.
struct StockQuantityPolicy {
    /// Allows zero and negative stock, rejecting only a final balance outside `Int`.
    /// An Array holds at most `Int.max` elements, so summing its `Int` deltas fits in `Int128`.
    func quantity(deltas: [Int]) throws -> Int {
        let total = deltas.reduce(Int128.zero) { $0 + Int128($1) }
        guard let quantity = Int(exactly: total) else { throw StockError.quantityOverflow }
        return quantity
    }
}
