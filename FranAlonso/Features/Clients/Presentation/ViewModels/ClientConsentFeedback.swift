import Foundation

extension ClientConsentStore.Failure {
    var consentMessage: LocalizedStringResource {
        switch self {
        case .catalog: .clientsConsentErrorCatalog
        case .persistence: .clientsConsentErrorPersistence
        case .rendering: .clientsConsentErrorRendering
        case .authorization: .clientsConsentErrorAuthorization
        case .conflict: .clientsConsentErrorConflict
        case .photoDecision: .clientsConsentErrorPhotoDecision
        case .unavailable: .clientsConsentErrorUnavailable
        case .permission: .clientsConsentErrorPermission
        case .activation: .clientsConsentActivationFailed
        }
    }
}

extension ClientConsentStore.Operation {
    var consentMessage: LocalizedStringResource {
        switch self {
        case .information: .clientsConsentLoadingInformation
        case .recover: .clientsConsentRecovering
        case .save: .clientsConsentSavingDraft
        case .signature: .clientsConsentSavingSignature
        case .render: .clientsConsentRendering
        case .upload: .clientsConsentUploading
        case .activate: .clientsConsentActivating
        case .discard: .clientsConsentDiscarding
        }
    }
}

extension ClientDocumentUploadState {
    var isUploaded: Bool {
        if case .uploaded = self {
            return true
        }
        return false
    }

    var consentMessage: LocalizedStringResource {
        switch self {
        case .pending: .clientsConsentPending
        case .failed(.permissionDenied): .clientsConsentErrorPermission
        case .failed: .clientsConsentErrorUnavailable
        case .uploaded: .clientsConsentUploaded
        case .conflict: .clientsConsentErrorConflict
        }
    }
}

extension ClientDocumentContent {
    /// Keeps the document's fixed language attached to native text, independently of the app locale.
    func readerText(_ string: String) -> AttributedString {
        var text = AttributedString(string)
        text.languageIdentifier = fields.language
        return text
    }
}

/// Stable numbered choices distinguish otherwise identical recovered drafts without exposing storage identifiers.
struct ClientConsentDraftChoice: Identifiable {
    let ordinal: Int
    let draft: ClientDocumentDraft
    var id: UUID { draft.id }
}

extension ClientFormViewModel {
    var isClientActivated: Bool {
        if case .active = loadedClient?.status {
            return true
        }
        return consentStore?.isActivated == true
    }

    var hasConsentUploadAction: Bool {
        guard let store = consentStore else { return false }
        let isInitial = store.snapshot?.fields.context.purpose == .initialInformation
        return store.hasUploadAction && !(isInitial && isClientActivated)
    }

    var consentUploadActionTitle: LocalizedStringResource {
        consentStore?.delivery?.state.isUploaded == true ? .clientsConsentFinishActivation : .clientsConsentUpload
    }

    var consentActivationMessage: LocalizedStringResource? {
        guard consentStore?.snapshot?.fields.context.purpose == .initialInformation else { return nil }
        if case .active(let reference) = loadedClient?.status {
            guard case .uploaded(let receipt) = consentStore?.delivery?.state,
                  receipt.reference == reference else { return .clientsConsentActivationUnlinked }
            return .clientsConsentActivated
        }
        if consentStore?.isActivated == true {
            return .clientsConsentActivated
        }
        if consentStore?.delivery?.state.isUploaded == true {
            return .clientsConsentActivationPending
        }
        return nil
    }

    var hasConsentWork: Bool {
        guard let consentStore else { return false }
        return consentStore.draft != nil || consentStore.delivery != nil
            || !consentStore.pendingDrafts.isEmpty || !consentStore.deliveries.isEmpty
    }

    var consentDraftChoices: [ClientConsentDraftChoice] {
        (consentStore?.pendingDrafts ?? []).enumerated().map {
            ClientConsentDraftChoice(ordinal: $0.offset + 1, draft: $0.element)
        }
    }
}
