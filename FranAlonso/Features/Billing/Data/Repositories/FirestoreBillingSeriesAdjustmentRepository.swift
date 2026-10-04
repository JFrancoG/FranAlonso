import Foundation

/// Checks administrative authority around the atomic seam, without granting privileges or allocating identities.
struct FirestoreBillingSeriesAdjustmentRepository<
    DataSource: BillingSeriesAdjustmentTransactionDataSource,
    Authorizer: BillingSeriesAdministrationAuthorizer
>: BillingSeriesAdjustmentRepository {
    private let transactionDataSource: DataSource
    private let administrationAuthorizer: Authorizer

    /// A revoked or replaced principal cannot publish an acceptance, even when the remote commit already happened.
    /// No implicit retry, device clock, local login or authorization fallback participates in this operation.
    func adjust(_ request: BillingSeriesAdjustmentRequest) async throws -> BillingSeriesAdjustmentReceipt {
        try Task.checkCancellation()
        do {
            let principal = try await administrationAuthorizer.authorize(request)
            try Task.checkCancellation()
            try requireBillingSeriesAdministrationPrincipal(principal)
            let dto = BillingSeriesAdjustmentRequestDTO(request)
            let audit = try await transactionDataSource.transact(request: dto, principalID: principal) { snapshot in
                try BillingSeriesAdjustmentTransactionPlan.plan(for: dto, principalID: principal, against: snapshot)
            }
            try Task.checkCancellation()
            let currentPrincipal = try await administrationAuthorizer.authorize(request)
            try Task.checkCancellation()
            try requireBillingSeriesAdministrationPrincipal(currentPrincipal)
            guard currentPrincipal == principal else { throw BillingSeriesAdjustmentError.permissionDenied }
            let receipt = try audit.toDomain()
            guard receipt.request == request, receipt.principalID == principal else {
                throw BillingSeriesAdjustmentError.invalidResponse
            }
            return receipt
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if let neutral = error as? BillingSeriesAdjustmentError {
                throw neutral
            }
            if error is DecodingError || error is EncodingError {
                throw BillingSeriesAdjustmentError.invalidResponse
            }
            throw BillingSeriesAdjustmentError.unavailable
        }
    }
}

extension FirestoreBillingSeriesAdjustmentRepository {
    init(dataSource: DataSource, authorizer: Authorizer) {
        self.init(transactionDataSource: dataSource, administrationAuthorizer: authorizer)
    }
}
