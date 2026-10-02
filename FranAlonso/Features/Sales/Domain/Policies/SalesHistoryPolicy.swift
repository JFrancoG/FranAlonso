import Foundation

/// Restricts historical queries to materialized terminal operations.
enum SalesHistoryFilter: String, Codable, Hashable {
    case all, closed, voided
}

/// Orders the original closure date; compensation never rewrites that chronology.
enum SalesHistoryOrder: String, Codable, Hashable {
    case newestFirst, oldestFirst
}

/// Selects terminal sales by original closure date, breaking ties by ascending stable identity.
/// A later compensation retains the original position; its effective date remains in the sale's status.
struct SalesHistoryPolicy {
    func callAsFunction(
        _ sales: [Sale],
        filter: SalesHistoryFilter = .all,
        order: SalesHistoryOrder = .newestFirst
    ) -> [Sale] {
        sales.filter { sale in
            switch sale.status {
            case .closed: filter != .voided
            case .voided: filter != .closed
            default: false
            }
        }.sorted { first, second in
            guard let firstDate = closureDate(of: first), let secondDate = closureDate(of: second) else { return false }
            if firstDate == secondDate {
                return first.id.rawValue.uuidString < second.id.rawValue.uuidString
            }
            return order == .newestFirst ? firstDate > secondDate : firstDate < secondDate
        }
    }

    /// Returns nil for operational sales, including paid sales awaiting their final document.
    func closureDate(of sale: Sale) -> Date? {
        switch sale.status {
        case let .closed(_, _, _, _, date), let .voided(_, _, _, _, date, _, _): date
        default: nil
        }
    }
}
