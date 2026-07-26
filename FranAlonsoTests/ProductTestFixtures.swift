@testable import FranAlonso

extension Product {
    static func testSnapshot(
        id: ProductID,
        name: String,
        status: ProductStatus = .active
    ) -> Product {
        Product(id: id, name: name, status: status)
    }
}
