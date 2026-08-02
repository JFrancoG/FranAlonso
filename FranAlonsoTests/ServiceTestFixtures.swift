import Foundation
@testable import FranAlonso

func makeService(
    id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000510")!,
    name: String = "Corte y peinado",
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    priceAmount: Decimal = 29.95,
    currency: Currency = .eur,
    taxPercentage: Decimal = 21,
    discountPercentage: Decimal? = 10,
    status: ServiceStatus = .active
) throws -> Service {
    try Service(
        id: ServiceID(rawValue: id),
        name: name,
        type: type,
        linkedProductID: linkedProductID.map(ProductID.init(rawValue:)),
        price: Money(amount: priceAmount, currency: currency),
        taxRate: TaxRate(percentage: taxPercentage),
        discount: try discountPercentage.map(Discount.init(percentage:)),
        status: status
    )
}

func makeServiceDTO(
    id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000510")!,
    name: String = "Corte y peinado",
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    priceAmount: Decimal = 29.95,
    currency: Currency = .eur,
    taxPercentage: Decimal = 21,
    discountPercentage: Decimal? = 10,
    status: ServiceStatus = .active
) throws -> ServiceDTO {
    try ServiceDTO(
        makeService(
            id: id,
            name: name,
            type: type,
            linkedProductID: linkedProductID,
            priceAmount: priceAmount,
            currency: currency,
            taxPercentage: taxPercentage,
            discountPercentage: discountPercentage,
            status: status
        )
    )
}
