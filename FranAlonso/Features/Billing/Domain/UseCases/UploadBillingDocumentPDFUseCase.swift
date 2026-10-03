import Foundation

/// Makes one authorized upload attempt using the caller's already prepared immutable bytes.
///
/// This operation never reserves a number, re-renders, closes a sale or persists upload state.
/// The caller retains the exact bytes for retry. A revoked capability or late cancellation cannot
/// publish success, even if the remote already accepted the document.
struct UploadBillingDocumentPDFUseCase {
    private let storageRepository: any BillingDocumentPDFStorageRepository

    /// Correlates a remote acknowledgement only while the captured shell capability remains authorized.
    /// - Throws: Neutral storage failures or cancellation, which prevails over late provider errors.
    func callAsFunction(
        _ document: BillingDocument,
        pdf: Data,
        access: BillingAssetAccess
    ) async throws -> BillingPDFUploadReceipt {
        do {
            try Task.checkCancellation()
            try await validateAccess(access)
            guard !pdf.isEmpty else { throw BillingPDFStorageError.invalidPDF }
            let receipt = try await storageRepository.upload(document, pdf: pdf, access: access)
            try Task.checkCancellation()
            try await validateAccess(access)
            guard receipt.matches(documentID: document.id, principalID: access.principalID) else {
                throw BillingPDFStorageError.invalidReceipt
            }
            return receipt
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw error
            }
            try await validateAccess(access)
            if let neutral = error as? BillingPDFStorageError {
                throw neutral
            }
            if error as? BillingAssetError == .unauthorized {
                throw BillingPDFStorageError.permissionDenied
            }
            throw BillingPDFStorageError.unavailable
        }
    }
}

extension UploadBillingDocumentPDFUseCase {
    init(repository: any BillingDocumentPDFStorageRepository) {
        self.init(storageRepository: repository)
    }
}

private extension UploadBillingDocumentPDFUseCase {
    func validateAccess(_ access: BillingAssetAccess) async throws {
        do {
            try await access.validate()
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw error
            }
            throw BillingPDFStorageError.permissionDenied
        }
    }
}
