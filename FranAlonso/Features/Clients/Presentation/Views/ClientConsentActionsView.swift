import SwiftUI

struct ClientConsentActionsView: View {
    let viewModel: ClientFormViewModel
    let isRequestPending: Bool
    let accessibilityFocus: AccessibilityFocusState<ClientConsentScreen.FocusTarget?>.Binding
    let onAction: @MainActor (ClientFormViewModel.ConsentAction) -> Void
    let onCapture: @MainActor () -> Void
    @State private var showsDiscardConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let store = viewModel.consentStore {
                if let operation = store.operation {
                    ProgressView {
                        Text(operation.consentMessage)
                    }
                }
                if let failure = store.failure {
                    Label {
                        Text(failure.consentMessage)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                    .foregroundStyle(.errorInk)
                    .accessibilityFocused(accessibilityFocus, equals: .feedback)
                }
                if store.phase == .information || store.phase == .idle || store.presentationIsStale {
                    if viewModel.canReviewConsent {
                        Button {
                            onAction(.review)
                        } label: {
                            Text(.clientsConsentReview).frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .consentPrimaryActionStyle()
                    }
                }
                if store.phase == .review || store.phase == .capture, !store.presentationIsStale {
                    Text(.clientsConsentReviewInstruction)
                    if store.snapshot?.fields.context.photoDecision == .undecided {
                        Text(.clientsConsentPhotoOptional)
                        Button {
                            onAction(.authorizePhoto)
                        } label: {
                            Text(.clientsConsentPhotoAuthorize).frame(minHeight: 44)
                        }
                        Button {
                            onAction(.declinePhoto)
                        } label: {
                            Text(.clientsConsentPhotoDecline).frame(minHeight: 44)
                        }
                    }
                    Button(action: onCapture) {
                        Text(.clientsConsentCapture).frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .consentPrimaryActionStyle()
                    .accessibilityFocused(accessibilityFocus, equals: .capture)
                    .disabled(!store.canCapture)
                }
                if store.phase == .signatureReview {
                    Text(.clientsConsentSignatureSaved)
                    Button {
                        onAction(.accept)
                    } label: {
                        Text(.clientsConsentAccept).frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .consentPrimaryActionStyle()
                    .accessibilityFocused(accessibilityFocus, equals: .accept)
                    .disabled(!store.canAccept)
                }
                if store.snapshot?.fields.context.photoDecision == .authorized, store.delivery == nil {
                    Label {
                        Text(.clientsConsentPhotoAuthorized)
                    } icon: {
                        Image(systemName: "checkmark.circle")
                    }
                    Button {
                        onAction(.removePhoto)
                    } label: {
                        Text(.clientsConsentPhotoRemove).frame(minHeight: 44)
                    }
                }
                if let delivery = store.delivery {
                    Text(.clientsConsentRetained).font(.headline).accessibilityAddTraits(.isHeader)
                        .accessibilityFocused(accessibilityFocus, equals: .retained)
                    Text(delivery.state.consentMessage)
                    if let message = viewModel.consentActivationMessage {
                        Text(message)
                    }
                    if viewModel.hasConsentUploadAction {
                        Button {
                            onAction(.upload)
                        } label: {
                            Text(viewModel.consentUploadActionTitle).frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .consentPrimaryActionStyle()
                        .accessibilityFocused(accessibilityFocus, equals: .upload)
                        .disabled(!store.canUpload)
                    }
                }
                if store.requiresReconciliation {
                    Button {
                        onAction(.recover)
                    } label: {
                        Text(.clientsConsentResume).frame(minHeight: 44)
                    }
                }
                if store.failure == .catalog, store.content == nil {
                    Button {
                        onAction(.information)
                    } label: {
                        Text(.clientsConsentRetry).frame(minHeight: 44)
                    }
                }
                if store.hasPendingDraft, !store.requiresReconciliation {
                    if store.phase == .review || store.phase == .capture || store.phase == .signatureReview {
                        Button {
                            onAction(.currentContent)
                        } label: {
                            Text(.clientsConsentCurrentContent).frame(minHeight: 44)
                        }
                        .disabled(store.phase == .capture)
                    }
                    Button(role: .destructive) {
                        showsDiscardConfirmation = true
                    } label: {
                        Text(.clientsConsentDiscard).frame(minHeight: 44)
                    }
                    .tint(.errorInk)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .buttonStyle(.bordered)
        .tint(.brandPrimaryInk)
        .disabled(isRequestPending || viewModel.consentStore?.isBusy == true)
        .confirmationDialog(
            Text(.clientsConsentDiscardTitle),
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                onAction(.discard)
            } label: {
                Text(.clientsConsentDiscard)
            }
            Button(role: .cancel) {} label: {
                Text(.clientsFormCancel)
            }
        } message: {
            Text(.clientsConsentDiscardMessage)
        }
    }
}

#Preview("Review actions", traits: .modifier(ClientConsentPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedElement: ClientConsentScreen.FocusTarget?

    ClientConsentPreviewHost(scenario: .review) { model in
        ClientConsentActionsView(
            viewModel: model,
            isRequestPending: false,
            accessibilityFocus: $focusedElement,
            onAction: { _ in },
            onCapture: {}
        )
        .padding()
    }
}

#Preview("Finish activation", traits: .modifier(ClientConsentPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedElement: ClientConsentScreen.FocusTarget?

    ClientConsentPreviewHost(scenario: .activationPending) { model in
        ScrollView {
            ClientConsentActionsView(
                viewModel: model,
                isRequestPending: false,
                accessibilityFocus: $focusedElement,
                onAction: { _ in },
                onCapture: {}
            )
            .padding()
            .frame(maxWidth: 760)
        }
    }
}

#Preview("Active client", traits: .modifier(ClientConsentPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedElement: ClientConsentScreen.FocusTarget?

    ClientConsentPreviewHost(scenario: .activated) { model in
        ScrollView {
            ClientConsentActionsView(
                viewModel: model,
                isRequestPending: false,
                accessibilityFocus: $focusedElement,
                onAction: { _ in },
                onCapture: {}
            )
            .padding()
            .frame(maxWidth: 760)
        }
    }
}

#Preview("Retry activation", traits: .modifier(ClientConsentPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedElement: ClientConsentScreen.FocusTarget?

    ClientConsentPreviewHost(scenario: .activationFailure) { model in
        ScrollView {
            ClientConsentActionsView(
                viewModel: model,
                isRequestPending: false,
                accessibilityFocus: $focusedElement,
                onAction: { _ in },
                onCapture: {}
            )
            .padding()
            .frame(maxWidth: 760)
        }
    }
}

private extension View {
    func consentPrimaryActionStyle() -> some View {
        buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .fontWeight(.semibold)
            .tint(.brandPrimaryInk)
    }
}
