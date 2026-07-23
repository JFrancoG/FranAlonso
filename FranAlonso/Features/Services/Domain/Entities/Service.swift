/// The kind of catalog offering, which determines whether physical inventory must be linked.
enum ServiceType: String, Codable {
    /// A performed service that must not reference a physical product.
    case professional

    /// An offering backed by a required physical inventory item.
    case product
}

/// The catalog availability of a service.
enum ServiceStatus: String, Codable {
    case active
    case inactive
}

/// Errors raised when a service type and its physical product link are inconsistent.
enum ServiceError: Error, Equatable {
    /// A product offering was created without a physical product reference.
    case linkedProductRequired

    /// A professional offering was created with a physical product reference.
    case linkedProductNotAllowed
}

/// A catalog offering that owns its tax-inclusive price, tax rate, and optional discount.
///
/// Product offerings require a physical inventory link; professional offerings
/// prohibit one. Both direct construction and decoding enforce this relationship.
struct Service: Identifiable, Codable, Equatable {
    let id: ServiceID
    let name: String
    let type: ServiceType
    private let storedLinkedProductID: ProductID?
    let price: Money
    let taxRate: TaxRate
    let discount: Discount?
    let status: ServiceStatus

    /// The physical inventory item backing a product offering, or `nil` for a professional one.
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
    /// Creates a service while enforcing the product-link rule for its type.
    ///
    /// - Throws: `ServiceError.linkedProductRequired` when a product offering has
    ///   no product link, or `ServiceError.linkedProductNotAllowed` when a
    ///   professional offering has one.
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
