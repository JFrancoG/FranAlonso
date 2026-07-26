import Foundation

extension ProductModel {
    /// Creates an unmanaged persistent model from a valid Domain product.
    convenience init(_ product: Product) {
        let dto = ProductDTO(product)

        self.init(
            id: product.id.rawValue,
            name: dto.name,
            statusRawValue: dto.status.rawValue
        )
    }

    /// Reconstructs a validated Domain value detached from this context-confined model.
    ///
    /// - Throws: `ProductMappingError` when the persisted availability value is unsupported.
    func toDomain() throws -> Product {
        guard let status = ProductStatusDTO(rawValue: statusRawValue) else {
            throw ProductMappingError.invalidPersistedStatus(statusRawValue)
        }

        return try ProductDTO(
            id: id.uuidString,
            name: name,
            status: status
        ).toDomain()
    }

    /// Replaces this context-owned model's persisted fields with a Domain snapshot.
    func update(from product: Product) {
        let dto = ProductDTO(product)

        id = product.id.rawValue
        name = dto.name
        statusRawValue = dto.status.rawValue
    }
}
