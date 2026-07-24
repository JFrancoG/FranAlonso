import Foundation

extension ClientDTO {
    /// Creates a transport payload from a valid Domain client.
    ///
    /// - Parameter client: The Domain client to encode for a Data boundary.
    init(_ client: Client) {
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

        self.init(
            id: client.id.rawValue.uuidString,
            displayName: client.displayName,
            taxIdentifier: client.taxIdentifier,
            billingAddress: client.billingAddress.map(BillingAddressDTO.init),
            status: status,
            consentReference: consentReference
        )
    }

    /// Reconstructs a validated Domain client from this transport representation.
    ///
    /// - Returns: A Domain client preserving the payload's stable identity and lifecycle state.
    /// - Throws: `ClientMappingError` when identity or consent metadata is inconsistent, or
    ///   `ClientConsentReferenceError` when the supplied consent reference is invalid.
    func toDomain() throws -> Client {
        guard let identifier = UUID(uuidString: id) else {
            throw ClientMappingError.invalidIdentifier(id)
        }

        return Client(
            id: ClientID(rawValue: identifier),
            displayName: displayName,
            taxIdentifier: taxIdentifier,
            billingAddress: billingAddress.map { $0.toDomain() },
            status: try domainStatus()
        )
    }

    private func domainStatus() throws -> ClientStatus {
        switch status {
        case .draft:
            try rejectUnexpectedConsentReference()
            return .draft
        case .consentPendingUpload:
            try rejectUnexpectedConsentReference()
            return .consentPendingUpload
        case .active:
            guard let consentReference else {
                throw ClientMappingError.missingConsentReference
            }

            return .active(
                consentReference: try ClientConsentReference(rawValue: consentReference)
            )
        }
    }

    private func rejectUnexpectedConsentReference() throws {
        guard consentReference == nil else {
            throw ClientMappingError.unexpectedConsentReference(status)
        }
    }
}

private extension BillingAddressDTO {
    init(_ address: BillingAddress) {
        self.init(
            streetLine: address.streetLine,
            postalCode: address.postalCode,
            city: address.city,
            province: address.province
        )
    }

    func toDomain() -> BillingAddress {
        BillingAddress(
            streetLine: streetLine,
            postalCode: postalCode,
            city: city,
            province: province
        )
    }
}
