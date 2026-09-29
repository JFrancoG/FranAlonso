import Foundation

/// Stable identity of one immutable inventory adjustment, reused on retries.
struct StockMovementID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}
