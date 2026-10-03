import SwiftUI
import UIKit

extension BillingFiscalField {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .displayName: "billing.fiscal.displayName"
        case .taxIdentifier: "billing.fiscal.taxIdentifier"
        case .streetLine: "billing.fiscal.streetLine"
        case .postalCode: "billing.fiscal.postalCode"
        case .city: "billing.fiscal.city"
        case .province: "billing.fiscal.province"
        }
    }

    var requiredMessage: LocalizedStringResource {
        switch self {
        case .displayName: "billing.fiscal.error.displayName"
        case .taxIdentifier: "billing.fiscal.error.taxIdentifier"
        case .streetLine: "billing.fiscal.error.streetLine"
        case .postalCode: "billing.fiscal.error.postalCode"
        case .city: "billing.fiscal.error.city"
        case .province: "billing.fiscal.error.province"
        }
    }

    var contentType: UITextContentType? {
        switch self {
        case .displayName: .name
        case .taxIdentifier: nil
        case .streetLine: .fullStreetAddress
        case .postalCode: .postalCode
        case .city: .addressCity
        case .province: .addressState
        }
    }

    var capitalization: TextInputAutocapitalization {
        switch self {
        case .taxIdentifier, .postalCode: .never
        case .displayName, .streetLine, .city, .province: .words
        }
    }
}

extension BillingDocumentKind {
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .ticket: "billing.kind.ticket"
        case .invoice: "billing.kind.invoice"
        }
    }
}
