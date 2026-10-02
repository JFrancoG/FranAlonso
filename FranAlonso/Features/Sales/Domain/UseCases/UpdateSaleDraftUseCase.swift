/// Replaces an expected draft inside the repository's local acceptance boundary.
struct UpdateSaleDraftUseCase {
    private let saleRepository: any SaleRepository

    /// Preserves identity, creation and retained service terms without a get-await-save sequence.
    /// - Throws: `SaleDraftError`, `SaleError` for invalid lines, or cancellation before acceptance.
    func callAsFunction(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        try await callAsFunction(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: expected.globalDiscount
        )
    }

    /// Accepts the complete draft candidate; an explicit `nil` removes the global term.
    /// - Throws: Rejection or cancellation before the repository accepts the candidate.
    func callAsFunction(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        try Task.checkCancellation()
        return try await saleRepository.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount
        )
    }
}

extension UpdateSaleDraftUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
