import Foundation

/// Constructs a validated draft and creates it once through the local acceptance boundary.
struct CreateSaleDraftUseCase {
    private let saleRepository: any SaleRepository

    /// Cancellation before acceptance leaves storage unchanged; success means a local commit.
    /// - Throws: `SaleError` for invalid input, `SaleDraftError` for rejection, or cancellation.
    func callAsFunction(
        id: SaleID,
        clientID: ClientID?,
        createdAt: Date,
        lines: [SaleLine]
    ) async throws -> Sale {
        try Task.checkCancellation()
        let draft = try Sale.draft(
            id: id,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines
        )
        try await saleRepository.createDraft(draft)
        return draft
    }
}

extension CreateSaleDraftUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
