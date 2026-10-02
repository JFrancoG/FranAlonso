/// The historical order and rounding policy captured with a sale-wide discount.
///
/// V1 applies each line promotion first, then the global percentage to that line's
/// rounded residual, before extracting included tax. Stored policies are never reinterpreted.
enum SaleGlobalDiscountPolicy: String, Codable {
    case lineThenGlobalV1
}

/// An optional commercial term independent of every line's captured promotion.
///
/// `Discount` guarantees an exact validated percentage in `0...100`. Absence is distinct
/// from a stored zero percentage; the policy fixes the historical calculation semantics.
struct SaleGlobalDiscount: Codable, Equatable {
    let discount: Discount
    let policy: SaleGlobalDiscountPolicy
}
