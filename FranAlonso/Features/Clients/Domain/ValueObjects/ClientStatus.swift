/// The consent-backed activation state of a client.
///
/// Only an active client can participate in business operations. Deactivation is
/// represented by synchronization metadata rather than another activation state.
enum ClientStatus: Codable, Equatable {
    /// A locally saved, editable profile that is not yet operational.
    case draft

    /// Consent is awaiting remote persistence, so the client remains non-operational.
    case consentPendingUpload

    /// Consent is persisted and referenced, so the client can participate in business operations.
    case active(consentReference: ClientConsentReference)
}
