/// Turns typed editable fields into validated input without identity or availability.
struct PrepareServiceProfileUseCase {
    /// Preserves exact monetary values and optional discount semantics while validating commercial input.
    /// Localized numeric text parsing belongs to the form boundary.
    func callAsFunction(
        name: String,
        type: ServiceType,
        linkedProductID: ProductID? = nil,
        price: Money,
        taxRate: TaxRate,
        discount: Discount?
    ) throws -> ServiceProfile {
        try ServiceProfile(
            name: name,
            type: type,
            linkedProductID: linkedProductID,
            price: price,
            taxRate: taxRate,
            discount: discount
        )
    }
}
