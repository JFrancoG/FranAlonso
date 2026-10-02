import Foundation

/// Accepts a stable payment command through the local repository boundary.
struct RegisterSalePaymentUseCase {
    private let saleRepository: any SaleRepository

    /// Caller retains the same identity and timestamp across cancellation, failure and replay.
    /// Success means atomic local payment and captured stock consumption, without remote convergence.
    /// - Throws: `SalePaymentError`, `SaleError`, or cancellation before acceptance.
    func callAsFunction(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod?,
        paidAt: Date
    ) async throws -> Sale {
        try Task.checkCancellation()
        guard let method else { throw SalePaymentError.methodRequired }
        return try await saleRepository.registerPayment(
            expected,
            id: paymentID,
            method: method,
            paidAt: paidAt
        )
    }
}

extension RegisterSalePaymentUseCase {
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
