enum ProductStatus: String, Codable {
    case active
    case inactive
}

struct Product: Identifiable, Codable, Equatable {
    let id: ProductID
    let name: String
    let status: ProductStatus
}
