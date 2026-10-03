import Foundation

/// A violation of the application's recipient-completeness or ticket-privacy contract.
enum BillingFiscalRecipientError: Error, Equatable {
    case required(BillingFiscalField)
    case unexpectedRecipient
}

/// An immutable recipient snapshot retained with an invoice request, independently of the client profile.
struct BillingFiscalRecipient: Codable, Equatable, Sendable {
    private let storedName: String
    private let storedTaxIdentifier: String
    private let storedAddress: BillingAddress

    var displayName: String { storedName }
    var taxIdentifier: String { storedTaxIdentifier }
    var billingAddress: BillingAddress { storedAddress }
    var input: BillingFiscalRecipientInput {
        BillingFiscalRecipientInput(
            displayName: displayName,
            taxIdentifier: taxIdentifier,
            streetLine: billingAddress.streetLine,
            postalCode: billingAddress.postalCode,
            city: billingAddress.city,
            province: billingAddress.province
        )
    }

    private enum CodingKeys: String, CodingKey { case displayName, taxIdentifier, billingAddress }
}

extension BillingFiscalRecipient {
    /// Trims boundary whitespace and requires all six application fields; no fiscal-format certification is implied.
    init(_ input: BillingFiscalRecipientInput) throws {
        var normalized = input
        for field in BillingFiscalField.allCases {
            let value = input[field].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { throw BillingFiscalRecipientError.required(field) }
            normalized[field] = value
        }
        self.init(
            storedName: normalized.displayName,
            storedTaxIdentifier: normalized.taxIdentifier,
            storedAddress: BillingAddress(
                streetLine: normalized.streetLine,
                postalCode: normalized.postalCode,
                city: normalized.city,
                province: normalized.province
            )
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(BillingAddress.self, forKey: .billingAddress)
        try self.init(BillingFiscalRecipientInput(
            displayName: container.decode(String.self, forKey: .displayName),
            taxIdentifier: container.decode(String.self, forKey: .taxIdentifier),
            streetLine: address.streetLine,
            postalCode: address.postalCode,
            city: address.city,
            province: address.province
        ))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(taxIdentifier, forKey: .taxIdentifier)
        try container.encode(billingAddress, forKey: .billingAddress)
    }
}
