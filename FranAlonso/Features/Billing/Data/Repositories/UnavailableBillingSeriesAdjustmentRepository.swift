import Foundation

/// Inactive composition never contacts remote authority or fabricates acceptance.
struct UnavailableBillingSeriesAdjustmentRepository: BillingSeriesAdjustmentRepository {
    func adjust(_ request: BillingSeriesAdjustmentRequest) async throws -> BillingSeriesAdjustmentReceipt {
        try Task.checkCancellation()
        throw BillingSeriesAdjustmentError.unavailable
    }
}
