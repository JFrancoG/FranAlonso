/// Gives positive units their entry or withdrawal meaning before constructing a movement.
enum StockAdjustmentDirection: String, CaseIterable, Codable, Hashable {
    case entry
    case withdrawal
}
