import Foundation

extension ProductDTO {
    /// Creates a transport payload from a Domain Product snapshot.
    init(_ product: Product) {
        let status: ProductStatusDTO = switch product.status {
        case .active: .active
        case .inactive: .inactive
        }

        self.init(
            id: product.id.rawValue.uuidString,
            name: product.name,
            status: status
        )
    }

    /// Reconstructs a Domain Product while preserving stable identity and availability.
    ///
    /// - Throws: `ProductMappingError.invalidIdentifier` when `id` is not a UUID.
    func toDomain() throws -> Product {
        guard let identifier = UUID(uuidString: id) else {
            throw ProductMappingError.invalidIdentifier(id)
        }
        let domainStatus: ProductStatus = switch status {
        case .active: .active
        case .inactive: .inactive
        }

        return Product(
            id: ProductID(rawValue: identifier),
            name: name,
            status: domainStatus
        )
    }
}
