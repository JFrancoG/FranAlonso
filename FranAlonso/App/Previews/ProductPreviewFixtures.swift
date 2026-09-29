import Foundation
import SwiftData

/// Fixed product snapshots and an idempotent seed for interactive previews.
struct ProductPreviewFixtures {
    let primaryProduct: Product
    let secondaryProduct: Product

    var products: [Product] { [primaryProduct, secondaryProduct] }

    /// Inserts missing sample identities without overwriting edits in the shared preview context.
    func seed(in context: ModelContext) throws {
        let source = ProductLocalDataSource()
        for product in products {
            if try source.product(id: product.id, in: context) == nil {
                try source.upsert(product, in: context)
            }
        }
    }
}

extension ProductPreviewFixtures {
    static let standard = ProductPreviewFixtures(
        primaryProduct: Product(
            id: ProductID(rawValue: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1))),
            name: "Champú profesional de hidratación y cuidado del cabello teñido",
            status: .active
        ),
        secondaryProduct: Product(
            id: ProductID(rawValue: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 2))),
            name: "Mascarilla nutritiva",
            status: .inactive
        )
    )

    static let list250: [Product] = (1...250).map { index in
        Product(
            id: ProductID(rawValue: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, UInt8(index)))),
            name: "Producto de ejemplo \(index)",
            status: index.isMultiple(of: 5) ? .inactive : .active
        )
    }
}
