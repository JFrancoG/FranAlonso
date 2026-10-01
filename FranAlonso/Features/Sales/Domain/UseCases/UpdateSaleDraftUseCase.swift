/// Replaces an expected draft inside the repository's local acceptance boundary.
struct UpdateSaleDraftUseCase {
    private let saleRepository: any SaleRepository

    /// Preserves identity, creation and retained service terms without a get-await-save sequence.
    /// - Throws: `SaleDraftError`, `SaleError` for invalid lines, or cancellation before acceptance.
    func callAsFunction(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        try Task.checkCancellation()
        return try await saleRepository.updateDraft(expected, clientID: clientID, lines: lines)
    }
}

extension UpdateSaleDraftUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
