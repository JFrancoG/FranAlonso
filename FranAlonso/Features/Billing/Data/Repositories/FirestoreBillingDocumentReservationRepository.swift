import Foundation

/// Maps the paid Domain contract to a replaceable atomic transaction boundary, without local allocation.
struct FirestoreBillingDocumentReservationRepository<DataSource: BillingTransactionDataSource>:
    BillingDocumentReservationRepository {
    private let transactionDataSource: DataSource

    /// Preserves complete request identity and exposes only neutral errors to Domain.
    ///
    /// Cancellation or failure after commit leaves the allocation recoverable by the identical request.
    /// No automatic retry, local state mutation, sale closure or numbering occurs outside the transaction.
    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        try Task.checkCancellation()
        do {
            let dto = try BillingDocumentRequestDTO(request)
            let record = try await transactionDataSource.transact(request: dto) { snapshot in
                try BillingTransactionPlan.plan(for: dto, against: snapshot)
            }
            try Task.checkCancellation()
            let document = try record.toDomain()
            guard document.request == request else { throw BillingDocumentReservationError.invalidResponse }
            return document
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            if let neutral = error as? BillingDocumentReservationError {
                throw neutral
            }
            if error is DecodingError || error is EncodingError {
                throw BillingDocumentReservationError.invalidResponse
            }
            throw BillingDocumentReservationError.unavailable
        }
    }
}

extension FirestoreBillingDocumentReservationRepository {
    init(dataSource: DataSource) { self.init(transactionDataSource: dataSource) }
}
