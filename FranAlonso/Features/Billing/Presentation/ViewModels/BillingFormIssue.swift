import Foundation

enum BillingFormIssue: Equatable {
    case required(BillingFiscalField)
    case unavailable
}
