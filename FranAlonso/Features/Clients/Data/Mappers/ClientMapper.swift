import Foundation

/// Errors raised when a client payload cannot represent a valid Domain value.
enum ClientMapperError: Error, Equatable {
    /// The transport identifier is not a UUID.
    case invalidIdentifier(String)

    /// An active payload has no consent reference.
    case missingConsentReference

    /// A non-active payload carries a consent reference that would otherwise be discarded.
    case unexpectedConsentReference(ClientStatusDTO)
}

/// Translates between the Clients transport contract and its Domain model.
enum ClientMapper {}

extension ClientMapper {
    /// Reconstructs a validated Domain client from its transport representation.
    ///
    /// - Parameter dto: The decoded client payload.
    /// - Returns: A Domain client preserving the payload's stable identity and lifecycle state.
    /// - Throws: `ClientMapperError` when identity or consent metadata is inconsistent, or
    ///   `ClientConsentReferenceError` when the supplied consent reference is invalid.
    static func domain(from dto: ClientDTO) throws -> Client {
        guard let identifier = UUID(uuidString: dto.id) else {
            throw ClientMapperError.invalidIdentifier(dto.id)
        }

        return Client(
            id: ClientID(rawValue: identifier),
            displayName: dto.displayName,
            taxIdentifier: dto.taxIdentifier,
            billingAddress: domainBillingAddress(from: dto.billingAddress),
            status: try domainStatus(from: dto)
        )
    }

    /// Creates a transport payload from a valid Domain client.
    ///
    /// - Parameter client: The Domain client to encode for a Data boundary.
    /// - Returns: A payload with a canonical UUID string and explicit lifecycle fields.
    static func dto(from client: Client) -> ClientDTO {
        let status: ClientStatusDTO
        let consentReference: String?

        switch client.status {
        case .draft:
            status = .draft
            consentReference = nil
        case .consentPendingUpload:
            status = .consentPendingUpload
            consentReference = nil
        case .active(let reference):
            status = .active
            consentReference = reference.rawValue
        }

        return ClientDTO(
            id: client.id.rawValue.uuidString,
            displayName: client.displayName,
            taxIdentifier: client.taxIdentifier,
            billingAddress: transportBillingAddress(from: client.billingAddress),
            status: status,
            consentReference: consentReference
        )
    }

    private static func domainStatus(from dto: ClientDTO) throws -> ClientStatus {
        switch dto.status {
        case .draft:
            try rejectUnexpectedConsentReference(in: dto)
            return .draft
        case .consentPendingUpload:
            try rejectUnexpectedConsentReference(in: dto)
            return .consentPendingUpload
        case .active:
            guard let rawReference = dto.consentReference else {
                throw ClientMapperError.missingConsentReference
            }

            return .active(
                consentReference: try ClientConsentReference(rawValue: rawReference)
            )
        }
    }

    private static func rejectUnexpectedConsentReference(in dto: ClientDTO) throws {
        guard dto.consentReference == nil else {
            throw ClientMapperError.unexpectedConsentReference(dto.status)
        }
    }

    private static func domainBillingAddress(
        from dto: BillingAddressDTO?
    ) -> BillingAddress? {
        dto.map { address in
            BillingAddress(
                streetLine: address.streetLine,
                postalCode: address.postalCode,
                city: address.city,
                province: address.province
            )
        }
    }

    private static func transportBillingAddress(
        from address: BillingAddress?
    ) -> BillingAddressDTO? {
        address.map { address in
            BillingAddressDTO(
                streetLine: address.streetLine,
                postalCode: address.postalCode,
                city: address.city,
                province: address.province
            )
        }
    }
}
