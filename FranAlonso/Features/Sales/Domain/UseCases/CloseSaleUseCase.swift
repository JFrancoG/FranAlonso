import Foundation

/// Requests durable local closure under the captured authorized shell capability.
struct CloseSaleUseCase {
    private let saleRepository: any SaleRepository
    private let access: BillingAssetAccess

    /// Authorization is rechecked before publishing a result or neutralizing a repository failure.
    /// Acceptance does not reserve, render, upload, send mail or mutate stock.
    func callAsFunction(_ request: SaleClosureRequest) async throws -> Sale {
        try await authorize()
        do {
            let accepted = try await saleRepository.closeSale(request, principalID: access.principalID)
            try await authorize()
            return accepted
        } catch {
            try await authorize()
            throw normalized(error)
        }
    }
}

private extension CloseSaleUseCase {
    func authorize() async throws {
        do {
            try await access.validate()
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw CancellationError()
            }
            throw SaleClosureError.unauthorized
        }
    }

    func normalized(_ error: any Error) -> any Error {
        switch error {
        case is CancellationError:
            CancellationError()
        case let error as SaleClosureError:
            error
        case BillingAssetError.unauthorized, BillingDocumentPersistenceError.unauthorized:
            SaleClosureError.unauthorized
        default:
            SaleClosureError.persistenceUnavailable
        }
    }
}

extension CloseSaleUseCase {
    init(repository: any SaleRepository, access: BillingAssetAccess) {
        self.init(saleRepository: repository, access: access)
    }
}
