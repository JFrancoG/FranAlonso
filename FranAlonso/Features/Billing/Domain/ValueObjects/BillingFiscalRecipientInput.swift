/// The ordered application fields required before preparing a new invoice.
enum BillingFiscalField: String, Codable, CaseIterable, Hashable, Sendable {
    case displayName, taxIdentifier, streetLine, postalCode, city, province
}

/// Editable input whose completeness belongs to the fiscal-recipient construction boundary.
struct BillingFiscalRecipientInput: Equatable, Sendable {
    var displayName = ""
    var taxIdentifier = ""
    var streetLine = ""
    var postalCode = ""
    var city = ""
    var province = ""

    subscript(field: BillingFiscalField) -> String {
        get {
            switch field {
            case .displayName: displayName
            case .taxIdentifier: taxIdentifier
            case .streetLine: streetLine
            case .postalCode: postalCode
            case .city: city
            case .province: province
            }
        }
        set {
            switch field {
            case .displayName: displayName = newValue
            case .taxIdentifier: taxIdentifier = newValue
            case .streetLine: streetLine = newValue
            case .postalCode: postalCode = newValue
            case .city: city = newValue
            case .province: province = newValue
            }
        }
    }
}
