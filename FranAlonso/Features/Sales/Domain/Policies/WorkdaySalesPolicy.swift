import Foundation

/// The three operational buckets that remain visible until a sale receives its final document.
struct WorkdaySales: Equatable {
    let upcoming: [Sale]
    let inProgress: [Sale]
    let awaitingClosure: [Sale]

    var isEmpty: Bool { upcoming.isEmpty && inProgress.isEmpty && awaitingClosure.isEmpty }
    var sales: [Sale] { upcoming + inProgress + awaitingClosure }
}

/// Operational visibility is independent of creation date, client association and payment completion.
enum WorkdaySaleCategory {
    case upcoming
    case inProgress
    case awaitingClosure
}

/// Classifies complete local snapshots without imposing a calendar-day filter.
struct WorkdaySalesPolicy {
    /// Preserves distinct sales and orders each bucket by creation time, then stable sale identity.
    func callAsFunction(_ sales: [Sale]) -> WorkdaySales {
        let ordered = sales.sorted {
            if $0.createdAt != $1.createdAt {
                return $0.createdAt < $1.createdAt
            }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
        return WorkdaySales(
            upcoming: ordered.filter { category(of: $0) == .upcoming },
            inProgress: ordered.filter { category(of: $0) == .inProgress },
            awaitingClosure: ordered.filter { category(of: $0) == .awaitingClosure }
        )
    }

    /// Terminal operations are absent; payment without a final document remains actionable.
    func category(of sale: Sale) -> WorkdaySaleCategory? {
        switch sale.status {
        case .draft:
            .upcoming
        case .inProgress:
            .inProgress
        case .awaitingPayment, .awaitingDocument:
            .awaitingClosure
        case .closed, .voided:
            nil
        }
    }
}
