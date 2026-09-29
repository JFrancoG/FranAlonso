/// The current local quantity relative to an explicit minimum, identified by the observed product.
///
/// Negative quantities remain meaningful. Equality with the minimum is not low stock, and the comparison
/// never subtracts values, so both integer extremes are representable without overflow.
struct LowStockState: Identifiable, Codable, Equatable {
    let productID: ProductID
    let quantity: Int
    let minimum: StockMinimum

    var id: ProductID { productID }
    var isLow: Bool { quantity < minimum.value }
}
