/// A violation of a sale line's quantity or lifecycle rules.
enum SaleLineError: Error, Equatable {
    /// The quantity is not strictly positive.
    case invalidQuantity

    /// The requested operation does not follow the upcoming, in-progress, completed order.
    case invalidTransition
}

/// A sale-owned snapshot of a service's commercial terms and execution state.
///
/// Later catalog changes do not alter the captured identity, name, quantity,
/// price, tax, discount, or product link.
struct SaleLine: Identifiable, Codable, Equatable {
    let id: SaleLineID
    let serviceID: ServiceID
    let serviceName: String
    private let storedQuantity: Int
    let unitPrice: Money
    let taxRate: TaxRate
    let discount: Discount?
    let linkedProductID: ProductID?
    private var storedStatus: SaleLineStatus

    var quantity: Int {
        storedQuantity
    }

    var status: SaleLineStatus {
        storedStatus
    }

    /// Moves the line from upcoming to in progress.
    ///
    /// - Throws: `SaleLineError.invalidTransition` if the line is not upcoming.
    mutating func start() throws {
        guard status == .upcoming else {
            throw SaleLineError.invalidTransition
        }

        storedStatus = .inProgress
    }

    /// Moves the line from in progress to completed.
    ///
    /// - Throws: `SaleLineError.invalidTransition` if the line is not in progress.
    mutating func complete() throws {
        guard status == .inProgress else {
            throw SaleLineError.invalidTransition
        }

        storedStatus = .completed
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case serviceID
        case serviceName
        case quantity
        case unitPrice
        case taxRate
        case discount
        case linkedProductID
        case status
    }
}

extension SaleLine {
    /// Captures service data in a new upcoming sale line.
    ///
    /// - Parameters:
    ///   - id: The line's stable identifier.
    ///   - serviceID: The identifier of the source service.
    ///   - serviceName: The service name captured for historical display.
    ///   - quantity: The strictly positive number of service units.
    ///   - unitPrice: The per-unit price captured in its explicit currency.
    ///   - taxRate: The tax percentage captured for the line.
    ///   - discount: The optional percentage discount captured for the line.
    ///   - linkedProductID: The optional product link captured from the source service.
    /// - Returns: A sale line whose status is `SaleLineStatus.upcoming`.
    /// - Throws: `SaleLineError.invalidQuantity` if `quantity` is zero or negative.
    static func upcoming(
        id: SaleLineID,
        serviceID: ServiceID,
        serviceName: String,
        quantity: Int,
        unitPrice: Money,
        taxRate: TaxRate,
        discount: Discount?,
        linkedProductID: ProductID?
    ) throws -> SaleLine {
        try SaleLine(
            id: id,
            serviceID: serviceID,
            serviceName: serviceName,
            quantity: quantity,
            unitPrice: unitPrice,
            taxRate: taxRate,
            discount: discount,
            linkedProductID: linkedProductID,
            status: .upcoming
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(SaleLineID.self, forKey: .id),
            serviceID: container.decode(ServiceID.self, forKey: .serviceID),
            serviceName: container.decode(String.self, forKey: .serviceName),
            quantity: container.decode(Int.self, forKey: .quantity),
            unitPrice: container.decode(Money.self, forKey: .unitPrice),
            taxRate: container.decode(TaxRate.self, forKey: .taxRate),
            discount: container.decodeIfPresent(Discount.self, forKey: .discount),
            linkedProductID: container.decodeIfPresent(ProductID.self, forKey: .linkedProductID),
            status: container.decode(SaleLineStatus.self, forKey: .status)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(serviceID, forKey: .serviceID)
        try container.encode(serviceName, forKey: .serviceName)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(taxRate, forKey: .taxRate)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encodeIfPresent(linkedProductID, forKey: .linkedProductID)
        try container.encode(status, forKey: .status)
    }

    private init(
        id: SaleLineID,
        serviceID: ServiceID,
        serviceName: String,
        quantity: Int,
        unitPrice: Money,
        taxRate: TaxRate,
        discount: Discount?,
        linkedProductID: ProductID?,
        status: SaleLineStatus
    ) throws {
        guard quantity > 0 else {
            throw SaleLineError.invalidQuantity
        }

        self.init(
            id: id,
            serviceID: serviceID,
            serviceName: serviceName,
            storedQuantity: quantity,
            unitPrice: unitPrice,
            taxRate: taxRate,
            discount: discount,
            linkedProductID: linkedProductID,
            storedStatus: status
        )
    }
}
