/// Makes one explicit administrative attempt without allocating new identities or retrying implicitly.
struct AdjustBillingSeriesUseCase<Repository: BillingSeriesAdjustmentRepository> {
    private let adjustmentRepository: Repository

    /// Accepts only a receipt correlated with the complete original command.
    /// - Throws: Neutral adjustment failures or native cancellation before or after repository contact.
    ///   An uncertain result leaves the same command available for an explicit recovery attempt.
    func callAsFunction(_ request: BillingSeriesAdjustmentRequest) async throws -> BillingSeriesAdjustmentReceipt {
        try Task.checkCancellation()
        let receipt: BillingSeriesAdjustmentReceipt
        do {
            receipt = try await adjustmentRepository.adjust(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw error as? BillingSeriesAdjustmentError ?? .unavailable
        }
        try Task.checkCancellation()
        guard receipt.request == request else { throw BillingSeriesAdjustmentError.invalidResponse }
        return receipt
    }
}

extension AdjustBillingSeriesUseCase {
    init(repository: Repository) {
        self.init(adjustmentRepository: repository)
    }
}
