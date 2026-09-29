import Foundation

/// Editable commercial input independent of service identity and availability.
///
/// New commands require a nonblank trimmed name, a nonnegative normalized price,
/// and a product link consistent with the offering type. Historical snapshots remain unchanged.
struct ServiceProfile: Codable, Equatable {
    private let storedName: String
    let type: ServiceType
    private let storedLinkedProductID: ProductID?
    let price: Money
    let taxRate: TaxRate
    let discount: Discount?

    var name: String { storedName }
    var linkedProductID: ProductID? { storedLinkedProductID }

    private enum CodingKeys: String, CodingKey {
        case storedName = "name"
        case type
        case storedLinkedProductID = "linkedProductID"
        case price
        case taxRate
        case discount
    }
}

extension ServiceProfile {
    /// Validates commercial input without looking up the linked physical product.
    /// - Throws: `ServiceError` for blank names, negative prices or inconsistent product linkage.
    init(
        name: String,
        type: ServiceType,
        linkedProductID: ProductID? = nil,
        price: Money,
        taxRate: TaxRate,
        discount: Discount?
    ) throws {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw ServiceError.invalidName }
        guard price.amount >= 0 else { throw ServiceError.invalidPrice }
        try type.validate(linkedProductID: linkedProductID)

        self.init(
            storedName: normalizedName,
            type: type,
            storedLinkedProductID: linkedProductID,
            price: price,
            taxRate: taxRate,
            discount: discount
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: container.decode(String.self, forKey: .storedName),
            type: container.decode(ServiceType.self, forKey: .type),
            linkedProductID: container.decodeIfPresent(ProductID.self, forKey: .storedLinkedProductID),
            price: container.decode(Money.self, forKey: .price),
            taxRate: container.decode(TaxRate.self, forKey: .taxRate),
            discount: container.decodeIfPresent(Discount.self, forKey: .discount)
        )
    }
}
