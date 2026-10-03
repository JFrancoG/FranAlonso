import Foundation

/// Fails closed until an explicitly authorized Storage implementation is injected.
struct UnavailableBillingDocumentPDFStorageRepository: BillingDocumentPDFStorageRepository {
    func upload(
        _ document: BillingDocument,
        pdf: Data,
        access: BillingAssetAccess
    ) async throws -> BillingPDFUploadReceipt {
        try Task.checkCancellation()
        throw BillingPDFStorageError.unavailable
    }
}
