/// Recovers a locally stored draft without making progressed sales editable.
struct GetSaleDraftUseCase {
    private let saleRepository: any SaleRepository

    /// Absence or discard returns nil; progressed snapshots require their own operational flow.
    /// - Throws: `SaleDraftError` for rejection or a local read failure, or cancellation.
    func callAsFunction(id: SaleID) async throws -> Sale? {
        try Task.checkCancellation()
        guard let sale = try await saleRepository.sale(id: id) else { return nil }
        guard sale.status == .draft else { throw SaleDraftError.requiresDraft }
        return sale
    }
}

extension GetSaleDraftUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
