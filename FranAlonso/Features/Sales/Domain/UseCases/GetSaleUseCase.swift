/// Reads a local sale without granting draft editing capabilities to progressed operations.
struct GetSaleUseCase {
    private let saleRepository: any SaleRepository

    /// Returns the neutral local snapshot or valid absence; cancellation never publishes a completed late read.
    /// - Throws: A local repository read failure or cancellation before or after the read.
    func callAsFunction(id: SaleID) async throws -> Sale? {
        try Task.checkCancellation()
        let sale = try await saleRepository.sale(id: id)
        try Task.checkCancellation()
        return sale
    }
}

extension GetSaleUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
