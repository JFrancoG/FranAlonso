import Foundation

extension SaleStatus {
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
