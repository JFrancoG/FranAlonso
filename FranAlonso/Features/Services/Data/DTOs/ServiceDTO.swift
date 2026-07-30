/// A Service snapshot independent of Domain and backend SDK types.
///
/// Decimal business values use nested canonical-string payloads so their base-ten
/// representation survives transport without passing through a floating-point value.
struct ServiceDTO: Codable, Equatable {
    let id: String
    let name: String
    let type: ServiceTypeDTO
    let linkedProductID: String?
    let price: ServiceMoneyDTO
    let taxRate: ServiceTaxRateDTO
    let discount: ServiceDiscountDTO?
    let status: ServiceStatusDTO
}

/// The monetary portion of a Service transport snapshot.
struct ServiceMoneyDTO: Codable, Equatable {
    let amount: ServiceDecimalDTO
    let currency: ServiceCurrencyDTO
}

/// The tax-rate portion of a Service transport snapshot.
struct ServiceTaxRateDTO: Codable, Equatable {
    let percentage: ServiceDecimalDTO
}

/// The optional discount portion of a Service transport snapshot.
struct ServiceDiscountDTO: Codable, Equatable {
    let percentage: ServiceDecimalDTO
}

/// Stable transport values for the kind of catalog offering.
enum ServiceTypeDTO: String, Codable, Equatable {
    case professional
    case product
}

/// Stable ISO currency values supported by Service transport payloads.
enum ServiceCurrencyDTO: String, Codable, Equatable {
    case eur = "EUR"
    case usd = "USD"
}

/// Stable transport values for Service catalog availability.
enum ServiceStatusDTO: String, Codable, Equatable {
    case active
    case inactive
}
