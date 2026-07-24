import Foundation

extension ClientModel {
    /// Creates an unmanaged persistent model from a valid Domain client.
    convenience init(_ client: Client) {
        let dto = ClientDTO(client)

        self.init(
            id: client.id.rawValue,
            displayName: dto.displayName,
            taxIdentifier: dto.taxIdentifier,
            billingStreetLine: dto.billingAddress?.streetLine,
            billingPostalCode: dto.billingAddress?.postalCode,
            billingCity: dto.billingAddress?.city,
            billingProvince: dto.billingAddress?.province,
            statusRawValue: dto.status.rawValue,
            consentReference: dto.consentReference
        )
    }

    /// Reconstructs a validated Domain value detached from this context-confined model.
    ///
    /// - Throws: `ClientMappingError` when persisted lifecycle or address fields are
    ///   inconsistent, or the existing consent-validation error when its reference is invalid.
    func toDomain() throws -> Client {
        guard let status = ClientStatusDTO(rawValue: statusRawValue) else {
            throw ClientMappingError.invalidPersistedStatus(statusRawValue)
        }

        return try ClientDTO(
            id: id.uuidString,
            displayName: displayName,
            taxIdentifier: taxIdentifier,
            billingAddress: try persistedBillingAddress(),
            status: status,
            consentReference: consentReference
        ).toDomain()
    }

    /// Replaces this context-owned model's persisted fields with a Domain snapshot.
    func update(from client: Client) {
        let dto = ClientDTO(client)

        id = client.id.rawValue
        displayName = dto.displayName
        taxIdentifier = dto.taxIdentifier
        billingStreetLine = dto.billingAddress?.streetLine
        billingPostalCode = dto.billingAddress?.postalCode
        billingCity = dto.billingAddress?.city
        billingProvince = dto.billingAddress?.province
        statusRawValue = dto.status.rawValue
        consentReference = dto.consentReference
    }

    private func persistedBillingAddress() throws -> BillingAddressDTO? {
        let fields = [
            billingStreetLine,
            billingPostalCode,
            billingCity,
            billingProvince
        ]

        guard fields.contains(where: { $0 != nil }) else {
            return nil
        }

        guard
            let billingStreetLine,
            let billingPostalCode,
            let billingCity,
            let billingProvince
        else {
            throw ClientMappingError.incompletePersistedBillingAddress
        }

        return BillingAddressDTO(
            streetLine: billingStreetLine,
            postalCode: billingPostalCode,
            city: billingCity,
            province: billingProvince
        )
    }
}
