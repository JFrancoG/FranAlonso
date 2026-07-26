/// A Product payload independent of Domain and backend SDK types.
struct ProductDTO: Codable, Equatable {
    let id: String
    let name: String
    let status: ProductStatusDTO
}

/// Stable transport values for Product catalog availability.
enum ProductStatusDTO: String, Codable, Equatable {
    case active
    case inactive
}
