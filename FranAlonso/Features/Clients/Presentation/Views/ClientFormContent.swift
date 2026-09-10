import SwiftUI

struct ClientFormContent: View {
    @Binding var fields: ClientFormFields
    let state: ClientFormViewModel.State
    let mode: ClientFormDestination.Mode
    let canEdit: Bool
    let isRequestPending: Bool
    let validationAttemptID: UUID?
    let onRetry: @MainActor () -> Void
    let onDeactivate: @MainActor () -> Void

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
        onRetry: {},
        onDeactivate: {}
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
        onRetry: {},
        onDeactivate: {}
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
        onRetry: {},
        onDeactivate: {}
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
        onRetry: {},
        onDeactivate: {}
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
        onRetry: {},
        onDeactivate: {}
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
        onRetry: {},
        onDeactivate: {}
    )
}
