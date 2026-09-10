import Foundation

/// Editable client fields, independent of identity and consent-backed activation.
/// Construction and decoding trim the name and reject an empty result.
struct ClientProfile: Codable, Equatable {
    private let storedDisplayName: String
    let taxIdentifier: String?
    let billingAddress: BillingAddress?

    var displayName: String { storedDisplayName }

    private enum CodingKeys: String, CodingKey {
        case storedDisplayName = "displayName"
        case taxIdentifier
        case billingAddress
    }
}

extension ClientProfile {
    /// Accepts profile fields without allowing a caller to change consent or activation.
    /// - Throws: `ClientError.invalidDisplayName` for a whitespace-only name.
    init(displayName: String, taxIdentifier: String? = nil, billingAddress: BillingAddress? = nil) throws {
        let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw ClientError.invalidDisplayName }
        self.init(storedDisplayName: normalizedName, taxIdentifier: taxIdentifier, billingAddress: billingAddress)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            displayName: container.decode(String.self, forKey: .storedDisplayName),
            taxIdentifier: container.decodeIfPresent(String.self, forKey: .taxIdentifier),
            billingAddress: container.decodeIfPresent(BillingAddress.self, forKey: .billingAddress)
        )
    }
}
