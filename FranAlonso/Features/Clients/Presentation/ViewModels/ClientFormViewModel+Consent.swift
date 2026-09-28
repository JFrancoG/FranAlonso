import Foundation

extension ClientFormViewModel {
    /// Semantic intentions from the document reader; task lifetime remains owned by the screen.
    enum ConsentAction: Equatable {
        case information, review, recover, useCurrentProfile, currentContent
        case selectDraft(UUID), selectDelivery(UUID)
        case authorizePhoto, declinePhoto, removePhoto
        case captured(ClientSignatureCaptureViewModel.Completion, UUID)
        case accept, upload, discard, backToForm
    }

    var canReviewConsent: Bool {
        guard canEdit, consentStore != nil, !consentUnavailable else { return false }
        if case .active = loadedClient?.status {
            return false
        }
        return true
    }

    var hasUnsavedChanges: Bool { fields != savedFields }

    func beginConsentCapture() -> UUID? {
        guard canEdit else { return nil }
        return consentStore?.startCapture()
    }

    /// Creates the reusable capture model for one correlated document presentation.
    func makeConsentCapture(
        onFinish: @escaping @MainActor (ClientSignatureCaptureViewModel.Completion, UUID) -> Void
    ) -> ClientSignatureCaptureViewModel? {
        guard let id = beginConsentCapture() else { return nil }
        return ClientSignatureCaptureViewModel { result in
            onFinish(result, id)
        }
    }
}
