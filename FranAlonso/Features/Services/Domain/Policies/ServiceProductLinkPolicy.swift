/// Determines whether a current physical product can back a commercial offering.
struct ServiceProductLinkPolicy {
    /// Requires a matching active product; absence and unavailability share one neutral failure.
    func requireProduct(_ product: Product?, id: ProductID) throws -> Product {
        guard let product, product.id == id, product.status == .active else {
            throw ServiceError.linkedProductUnavailable
        }
        return product
    }

    /// Validates commercial input against the current product snapshot without reserving it.
    func validate(_ profile: ServiceProfile, product: Product?) throws {
        guard let id = profile.linkedProductID else { return }
        _ = try requireProduct(product, id: id)
    }
}
