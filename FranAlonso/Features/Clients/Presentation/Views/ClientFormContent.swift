import SwiftUI

struct ClientFormContent: View {
    enum ConsentControl: Hashable {
        case information, review, recovery
    }

    struct ConsentFocusReturn: Equatable {
        let id: UUID
        let control: ConsentControl
    }

    @Binding var fields: ClientFormFields
    let state: ClientFormViewModel.State
    let mode: ClientFormDestination.Mode
    let canEdit: Bool
    let isRequestPending: Bool
    let validationAttemptID: UUID?
    let consentAvailable: Bool
    let consentUnavailable: Bool
    let canReviewConsent: Bool
    let hasConsentWork: Bool
    let consentFocusReturn: ConsentFocusReturn?
    let onRetry: @MainActor () -> Void
    let onDeactivate: @MainActor () -> Void
    let onInformation: @MainActor () -> Void
    let onReviewConsent: @MainActor () -> Void
    let onResumeConsent: @MainActor () -> Void
    @AccessibilityFocusState private var focusedConsentControl: ConsentControl?

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .clientsFormLoading)
        case .failed(.load, let error):
            UnavailableStateView(
                title: .clientsFormErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: error.clientFormMessage
            ) {
                Button(action: onRetry) {
                    Text(.clientsFormRetry)
                        .frame(minHeight: 44)
                }
                .primaryActionStyle()
                .disabled(isRequestPending)
            }
        default:
            Form {
                if mode == .create {
                    Section {
                        Text(.clientsFormDraftMessage)
                            .foregroundStyle(.textSecondary)
                    }
                }
                if let error = state.formError, error != .invalidDisplayName {
                    Section {
                        Text(error.clientFormMessage)
                            .foregroundStyle(.errorInk)
                    }
                }
                if let progressMessage = state.progressMessage {
                    Section {
                        ProgressView {
                            Text(progressMessage)
                                .foregroundStyle(.textPrimary)
                        }
                    }
                }
                ClientFormFieldsContent(
                    fields: $fields,
                    nameError: state.formError == .invalidDisplayName ? .clientsFormErrorName : nil,
                    validationAttemptID: validationAttemptID
                )
                .disabled(!canEdit || isRequestPending)

                if consentAvailable || consentUnavailable {
                    Section {
                        if consentUnavailable {
                            Text(.clientsConsentErrorAuthorization).foregroundStyle(.errorInk)
                        } else {
                            Button(action: onInformation) {
                                Text(.clientsConsentInformation).frame(minHeight: 44)
                            }
                            .accessibilityFocused($focusedConsentControl, equals: .information)
                            .disabled(isRequestPending)
                            if canReviewConsent {
                                Button(action: onReviewConsent) {
                                    Text(.clientsConsentReview).frame(minHeight: 44)
                                }
                                .accessibilityFocused($focusedConsentControl, equals: .review)
                                .disabled(!canEdit || isRequestPending)
                            }
                            if hasConsentWork {
                                Button(action: onResumeConsent) {
                                    Text(.clientsConsentResume).frame(minHeight: 44)
                                }
                                .accessibilityFocused($focusedConsentControl, equals: .recovery)
                                .disabled(!canEdit || isRequestPending)
                            }
                        }
                    } header: {
                        Text(.clientsConsentSection)
                    }
                }

                if mode == .edit {
                    Section {
                        Button(role: .destructive, action: onDeactivate) {
                            Text(.clientsFormDeactivate)
                                .foregroundStyle(.errorInk)
                                .frame(minHeight: 44)
                        }
                        .disabled(!canEdit || isRequestPending)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: consentFocusReturn) { _, request in
                guard let request else { return }
                switch request.control {
                case .information:
                    focusedConsentControl = .information
                case .review:
                    focusedConsentControl = canReviewConsent ? .review : .information
                case .recovery:
                    focusedConsentControl = hasConsentWork ? .recovery : .information
                }
            }
        }
    }
}

#Preview("Create", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields()

    ClientFormContent(
        fields: $fields,
        state: .editing,
        mode: .create,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: false,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}

#Preview("Edit long profile", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields.longPreview

    ClientFormContent(
        fields: $fields,
        state: .editing,
        mode: .edit,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: true,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}

#Preview("Invalid name", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields()

    ClientFormContent(
        fields: $fields,
        state: .failed(.save, .invalidDisplayName),
        mode: .create,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: false,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}

#Preview("Load failure", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields()

    ClientFormContent(
        fields: $fields,
        state: .failed(.load, .notFound),
        mode: .edit,
        canEdit: false,
        isRequestPending: false,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: false,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}

#Preview("Save failure", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields.longPreview

    ClientFormContent(
        fields: $fields,
        state: .failed(.save, .persistenceUnavailable),
        mode: .edit,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: false,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}

#Preview("Saving", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var fields = ClientFormFields.longPreview

    ClientFormContent(
        fields: $fields,
        state: .saving,
        mode: .edit,
        canEdit: false,
        isRequestPending: true,
        validationAttemptID: nil,
        consentAvailable: true,
        consentUnavailable: false,
        canReviewConsent: true,
        hasConsentWork: false,
        consentFocusReturn: nil,
        onRetry: {},
        onDeactivate: {},
        onInformation: {},
        onReviewConsent: {},
        onResumeConsent: {}
    )
}
