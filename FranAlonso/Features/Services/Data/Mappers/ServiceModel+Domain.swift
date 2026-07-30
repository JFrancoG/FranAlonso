import Foundation

extension ServiceModel {
    /// Creates an unmanaged persistent model from a valid Domain Service.
    ///
    /// - Throws: `ServiceDecimalDTOError.invalidValue` when a Domain decimal
    ///   cannot be represented by the canonical transport format.
    convenience init(_ service: Service) throws {
        let dto = try ServiceDTO(service)

        self.init(
            id: service.id.rawValue,
            name: dto.name,
            typeRawValue: dto.type.rawValue,
            linkedProductID: service.linkedProductID?.rawValue,
            priceAmountCanonical: dto.price.amount.canonicalString,
            currencyRawValue: dto.price.currency.rawValue,
            taxPercentageCanonical: dto.taxRate.percentage.canonicalString,
            discountPercentageCanonical: dto.discount?.percentage.canonicalString,
            statusRawValue: dto.status.rawValue
        )
    }

    /// Reconstructs a validated Domain value detached from this context-confined model.
    ///
    /// - Throws: `ServiceMappingError` when a persisted representation is unsupported,
    ///   or the Domain validation error raised by the reconstructed snapshot.
    func toDomain() throws -> Service {
        try makeDTO().toDomain()
    }

    /// Replaces this context-owned model's persisted fields with a Domain snapshot.
    ///
    /// All conversions complete before the managed fields are mutated.
    ///
    /// - Throws: `ServiceDecimalDTOError.invalidValue` when a Domain decimal
    ///   cannot be represented by the canonical transport format.
    func update(from service: Service) throws {
        let dto = try ServiceDTO(service)

        id = service.id.rawValue
        name = dto.name
        typeRawValue = dto.type.rawValue
        linkedProductID = service.linkedProductID?.rawValue
        priceAmountCanonical = dto.price.amount.canonicalString
        currencyRawValue = dto.price.currency.rawValue
        taxPercentageCanonical = dto.taxRate.percentage.canonicalString
        discountPercentageCanonical = dto.discount?.percentage.canonicalString
        statusRawValue = dto.status.rawValue
    }

    private func makeDTO() throws -> ServiceDTO {
        guard let type = ServiceTypeDTO(rawValue: typeRawValue) else {
            throw ServiceMappingError.invalidPersistedType(typeRawValue)
        }
        guard let currency = ServiceCurrencyDTO(rawValue: currencyRawValue) else {
            throw ServiceMappingError.invalidPersistedCurrency(currencyRawValue)
        }
        guard let status = ServiceStatusDTO(rawValue: statusRawValue) else {
            throw ServiceMappingError.invalidPersistedStatus(statusRawValue)
        }

        return ServiceDTO(
            id: id.uuidString,
            name: name,
            type: type,
            linkedProductID: linkedProductID?.uuidString,
            price: ServiceMoneyDTO(
                amount: try persistedDecimal(priceAmountCanonical),
                currency: currency
            ),
            taxRate: ServiceTaxRateDTO(
                percentage: try persistedDecimal(taxPercentageCanonical)
            ),
            discount: try discountPercentageCanonical.map { canonical in
                ServiceDiscountDTO(
                    percentage: try persistedDecimal(canonical)
                )
            },
            status: status
        )
    }

    private func persistedDecimal(
        _ canonicalString: String
    ) throws -> ServiceDecimalDTO {
        do {
            return try ServiceDecimalDTO(canonicalString: canonicalString)
        } catch {
            throw ServiceMappingError.invalidPersistedDecimal(canonicalString)
        }
    }
}
