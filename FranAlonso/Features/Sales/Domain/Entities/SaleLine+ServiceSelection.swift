/// A service cannot supply a new sale intention when it is unavailable in the catalogue.
enum SaleServiceSelectionError: Error, Equatable {
    case unavailable
}

extension SaleLine {
    /// Freezes one active service's commercial terms for later local sale acceptance.
    ///
    /// The optional discount retains absence distinctly from zero. Catalogue changes after capture
    /// cannot update this value; product availability, stock and local sale acceptance remain separate policies.
    /// - Parameters:
    ///   - service: The active offering visible when the person requests selection.
    ///   - id: The stable line identity reused if local acceptance must be retried.
    ///   - quantity: The strictly positive initial quantity; selection normally captures one unit.
    /// - Throws: `SaleServiceSelectionError.unavailable` for an inactive offering,
    ///   or `SaleLineError.invalidQuantity` for a nonpositive quantity.
    static func capturing(service: Service, id: SaleLineID, quantity: Int = 1) throws -> SaleLine {
        guard service.status == .active else { throw SaleServiceSelectionError.unavailable }
        return try upcoming(
            id: id,
            serviceID: service.id,
            serviceName: service.name,
            quantity: quantity,
            unitPrice: service.price,
            taxRate: service.taxRate,
            discount: service.discount,
            linkedProductID: service.linkedProductID
        )
    }
}
