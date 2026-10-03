import Foundation

/// Accepts one principal's complete confirmed document and exact prepared PDF bytes atomically.
///
/// The principal and document ID are the stable identity. An identical replay returns the original
/// receipt; any different document binding or PDF conflicts without overwriting the accepted value.
/// Cancellation or a lost response does not prove that remote acceptance did not occur.
protocol BillingDocumentPDFStorageRepository: Sendable {
    func upload(
        _ document: BillingDocument,
        pdf: Data,
        access: BillingAssetAccess
    ) async throws -> BillingPDFUploadReceipt
}

/// Provider-independent storage failures without document contents or infrastructure details.
enum BillingPDFStorageError: String, Error, Codable {
    case unavailable, permissionDenied, conflict, invalidPDF, invalidReceipt
}
