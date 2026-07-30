import Foundation

extension ServiceDTO {
    /// Creates a transport payload from a validated Domain Service snapshot.
    ///
    /// - Parameter service: The Domain snapshot whose exact decimal values are preserved.
    /// - Throws: `ServiceDecimalDTOError.invalidValue` if a Domain decimal is not transportable.
    init(_ service: Service) throws {
        let type: ServiceTypeDTO = switch service.type {
        case .professional: .professional
        case .product: .product
        }
        let currency: ServiceCurrencyDTO = switch service.price.currency {
        case .eur: .eur
        case .usd: .usd
        }
        let status: ServiceStatusDTO = switch service.status {
        case .active: .active
        case .inactive: .inactive
        }
        let discount = try service.discount.map {
            ServiceDiscountDTO(
                percentage: try ServiceDecimalDTO($0.percentage)
            )
        }

        self.init(
            id: service.id.rawValue.uuidString,
            name: service.name,
            type: type,
            linkedProductID: service.linkedProductID?.rawValue.uuidString,
            price: ServiceMoneyDTO(
                amount: try ServiceDecimalDTO(service.price.amount),
                currency: currency
            ),
            taxRate: ServiceTaxRateDTO(
                percentage: try ServiceDecimalDTO(service.taxRate.percentage)
            ),
            discount: discount,
            status: status
        )
    }

    /// Reconstructs a Domain Service while revalidating all value and link invariants.
    ///
    /// - Returns: A Service with the same identity and business values as this payload.
    /// - Throws: `ServiceMappingError` when an identifier is invalid or monetary
    ///   normalization would alter the remote snapshot. Domain value and Service
    ///   validation errors are propagated unchanged.
    func toDomain() throws -> Service {
        guard let identifier = UUID(uuidString: id) else {
            throw ServiceMappingError.invalidIdentifier(id)
        }

        let linkedIdentifier: UUID?
        if let linkedProductID {
            guard let parsedIdentifier = UUID(uuidString: linkedProductID) else {
                throw ServiceMappingError.invalidLinkedProductIdentifier(
                    linkedProductID
                )
            }
            linkedIdentifier = parsedIdentifier
        } else {
            linkedIdentifier = nil
        }

        let domainCurrency: Currency = switch price.currency {
        case .eur: .eur
        case .usd: .usd
        }
        let domainPrice = try Money(
            amount: price.amount.decimal,
            currency: domainCurrency
        )
        guard domainPrice.amount == price.amount.decimal else {
            throw ServiceMappingError.moneyNormalizationChanged(
                original: price.amount.decimal,
                normalized: domainPrice.amount
            )
        }

        let domainType: ServiceType = switch type {
        case .professional: .professional
        case .product: .product
        }
        let domainStatus: ServiceStatus = switch status {
        case .active: .active
        case .inactive: .inactive
        }
        let domainDiscount = try discount.map {
            try Discount(percentage: $0.percentage.decimal)
        }

        return try Service(
            id: ServiceID(rawValue: identifier),
            name: name,
            type: domainType,
            linkedProductID: linkedIdentifier.map(ProductID.init(rawValue:)),
            price: domainPrice,
            taxRate: TaxRate(percentage: taxRate.percentage.decimal),
            discount: domainDiscount,
            status: domainStatus
        )
    }
}
