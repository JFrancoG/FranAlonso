import Foundation

extension SaleStatus {
    var historySymbol: String {
        switch self {
        case .voided: "arrow.uturn.backward.circle"
        default: "checkmark.circle"
        }
    }

    var isHistoricallyVoided: Bool {
        if case .voided = self {
            return true
        }
        return false
    }

    var historyClosureDate: Date? {
        switch self {
        case let .closed(_, _, _, _, date), let .voided(_, _, _, _, date, _, _): date
        default: nil
        }
    }

    var localizedTitle: LocalizedStringResource {
        switch self {
        case .draft: "sales.status.draft"
        case .inProgress: "sales.status.inProgress"
        case .awaitingPayment: "sales.status.awaitingPayment"
        case .awaitingDocument: "sales.status.awaitingDocument"
        case .closed: "sales.status.closed"
        case .voided: "sales.status.voided"
        }
    }
}

extension SaleLineStatus {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .upcoming: "sales.line.upcoming"
        case .inProgress: "sales.line.inProgress"
        case .completed: "sales.line.completed"
        }
    }
}


extension SalesHistoryFilter {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .all: "sales.history.all"
        case .closed: "sales.status.closed"
        case .voided: "sales.status.voided"
        }
    }
}

extension SalesHistoryOrder {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .newestFirst: "sales.history.newest"
        case .oldestFirst: "sales.history.oldest"
        }
    }
}
