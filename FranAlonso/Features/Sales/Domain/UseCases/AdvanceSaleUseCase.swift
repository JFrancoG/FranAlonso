import Foundation

/// Accepts one work transition through the local repository without using unrestricted snapshot replacement.
struct AdvanceSaleUseCase {
    let repository: any SaleRepository

    /// Cancellation before delegation is rejected; local acceptance remains success after delegation.
    /// - Throws: Local progress rejection, aggregate validation or preacceptance cancellation.
    func callAsFunction(_ expected: Sale, action: SaleProgressAction) async throws -> Sale {
        try Task.checkCancellation()
        return try await repository.advanceSale(expected, action: action)
    }
}
