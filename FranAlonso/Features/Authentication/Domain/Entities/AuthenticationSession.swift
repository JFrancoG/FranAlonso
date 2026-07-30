/// A provider-neutral snapshot of the currently authenticated identity.
///
/// The identifier is stable for the principal and contains neither credentials nor provider
/// tokens. A snapshot represents the identity known locally by the provider, not proof of a
/// freshly validated authorization.
struct AuthenticationSession: Identifiable, Codable, Equatable {
    let id: String
}
