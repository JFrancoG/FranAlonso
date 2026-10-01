/// Discards a local draft while retaining its durable synchronization intent.
struct DiscardSaleDraftUseCase {
    private let saleRepository: any SaleRepository

    /// Repetition and absence do not enqueue a second discard; progressed sales are retained.
    /// - Throws: `SaleDraftError` for local rejection, or cancellation before acceptance.
    func callAsFunction(_ id: SaleID) async throws {
        try Task.checkCancellation()
        try await saleRepository.discardDraft(id)
    }
}

extension DiscardSaleDraftUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
