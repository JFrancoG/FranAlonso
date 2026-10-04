import Foundation

extension BillingDocumentPersistenceActor {
    /// Retains structurally valid prepared bytes once; retries never reconstruct an accepted PDF.
    func acceptPDF(id: BillingDocumentRequestID, pdf: Data, principalID: String) throws -> BillingDocumentDelivery {
        try mutate(id: id, principalID: principalID) { delivery in
            try delivery.acceptPDF(pdf)
            try BillingPDFUploadValidator.validate(pdf)
        }
    }

    /// Saves the next attempt before network contact; final replay creates no new attempt.
    func beginUpload(id: BillingDocumentRequestID, principalID: String) throws -> BillingDocumentDelivery {
        try mutate(id: id, principalID: principalID) {
            try $0.beginUpload()
        }
    }

    /// Accepts only the correlated durable receipt without replacing a confirmed remote binding.
    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt,
        principalID: String
    ) throws -> BillingDocumentDelivery {
        try mutate(id: id, principalID: principalID) {
            try $0.completeUpload(receipt)
        }
    }

    /// Records neutral current-stage failures; obsolete stages and attempts cannot demote later progress.
    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?,
        principalID: String
    ) throws {
        _ = try mutate(id: id, principalID: principalID) { delivery in
            try delivery.recordFailure(phase: phase, reason: reason, attempt: attempt)
        }
    }
}
