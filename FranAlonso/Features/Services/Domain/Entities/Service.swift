enum ServiceType: String, Codable {
    case professional
    case product
}

enum ServiceStatus: String, Codable {
    case active
    case inactive
}

enum ServiceError: Error, Equatable {
    case linkedProductRequired
    case linkedProductNotAllowed
}

struct Service: Identifiable, Codable, Equatable {
    let id: ServiceID
    let name: String
    let type: ServiceType
    private let storedLinkedProductID: ProductID?
    let price: Money
    let taxRate: TaxRate
    let discount: Discount?
    let status: ServiceStatus

    var linkedProductID: ProductID? {
        storedLinkedProductID
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case linkedProductID
        case price
        case taxRate
        case discount
        case status
    }
}

extension Service {
    init(
        id: ServiceID,
        name: String,
        type: ServiceType,
        linkedProductID: ProductID? = nil,
        price: Money,
        taxRate: TaxRate,
        discount: Discount?,
        status: ServiceStatus
    ) throws {
        switch (type, linkedProductID) {
        case (.product, nil):
            throw ServiceError.linkedProductRequired
        case (.professional, .some):
            throw ServiceError.linkedProductNotAllowed
        case (.product, .some), (.professional, nil):
            break
        }

        self.init(
            id: id,
            name: name,
            type: type,
            storedLinkedProductID: linkedProductID,
            price: price,
            taxRate: taxRate,
            discount: discount,
            status: status
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(ServiceID.self, forKey: .id),
            name: container.decode(String.self, forKey: .name),
            type: container.decode(ServiceType.self, forKey: .type),
            linkedProductID: container.decodeIfPresent(ProductID.self, forKey: .linkedProductID),
            price: container.decode(Money.self, forKey: .price),
            taxRate: container.decode(TaxRate.self, forKey: .taxRate),
            discount: container.decodeIfPresent(Discount.self, forKey: .discount),
            status: container.decode(ServiceStatus.self, forKey: .status)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(linkedProductID, forKey: .linkedProductID)
        try container.encode(price, forKey: .price)
        try container.encode(taxRate, forKey: .taxRate)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encode(status, forKey: .status)
    }
}
