/// A client payload that remains independent of Domain and backend SDK types.
struct ClientDTO: Codable, Equatable {
    let id: String
    let displayName: String
    let taxIdentifier: String?
    let billingAddress: BillingAddressDTO?
    let status: ClientStatusDTO
    let consentReference: String?
}

/// The transport representation nested under a client's billing address field.
struct BillingAddressDTO: Codable, Equatable {
    let streetLine: String
    let postalCode: String
    let city: String
    let province: String
}

/// Stable transport values for the consent-backed client lifecycle.
enum ClientStatusDTO: String, Codable, Equatable {
    case draft
    case consentPendingUpload
    case active
}
