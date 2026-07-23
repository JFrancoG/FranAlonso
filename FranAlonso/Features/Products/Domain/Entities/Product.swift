/// The catalog availability of a physical product.
enum ProductStatus: String, Codable {
    case active
    case inactive
}

/// A physical inventory item, intentionally separate from commercial pricing.
///
/// Price, tax, and discount belong to the catalog `Service` that sells the product.
struct Product: Identifiable, Codable, Equatable {
    let id: ProductID
    let name: String
    let status: ProductStatus
}
