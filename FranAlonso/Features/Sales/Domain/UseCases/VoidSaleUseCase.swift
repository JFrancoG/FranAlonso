import Foundation

/// Accepts a stable compensating command through the local Sales repository.
struct VoidSaleUseCase {
    private let saleRepository: any SaleRepository

    /// Caller retains reversal identity and effective date across failure, cancellation and replay.
    /// Success means local void and inverse stock events were accepted together; financial settlement is separate.
    /// - Throws: Reversal or lifecycle rejection, or cancellation before acceptance.
    func callAsFunction(_ expected: Sale, reversalID: SaleReversalID, voidedAt: Date) async throws -> Sale {
        try Task.checkCancellation()
        return try await saleRepository.voidSale(expected, reversalID: reversalID, voidedAt: voidedAt)
    }
}

extension VoidSaleUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
