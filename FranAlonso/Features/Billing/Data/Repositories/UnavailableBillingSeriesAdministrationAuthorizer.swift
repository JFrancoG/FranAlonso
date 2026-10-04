import Foundation

/// Default administrative authority grants no privileges; live provisioning needs its separate operational gate.
struct UnavailableBillingSeriesAdministrationAuthorizer: BillingSeriesAdministrationAuthorizer {
    func authorize(_ request: BillingSeriesAdjustmentRequest) async throws -> String {
        try Task.checkCancellation()
        throw BillingSeriesAdjustmentError.unavailable
    }
}
