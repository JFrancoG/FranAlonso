/// Errors raised when a client payload cannot represent a valid Domain value.
enum ClientMappingError: Error, Equatable {
    /// The transport identifier is not a UUID.
    case invalidIdentifier(String)

    /// An active payload has no consent reference.
    case missingConsentReference

    /// A non-active payload carries a consent reference that would otherwise be discarded.
    case unexpectedConsentReference(ClientStatusDTO)

    /// The persisted lifecycle value is not part of the supported client contract.
    case invalidPersistedStatus(String)

    /// Only part of the flattened persisted billing address is present.
    case incompletePersistedBillingAddress
}
