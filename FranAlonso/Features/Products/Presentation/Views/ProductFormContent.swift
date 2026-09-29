import SwiftUI

struct ProductFormContent: View {
    @Binding var name: String
    let state: ProductFormViewModel.State
    let mode: ProductFormDestination.Mode
    let isInactive: Bool
    let canEdit: Bool
    let canDeactivate: Bool
    let isRequestPending: Bool
    let validationAttemptID: UUID?
    let onRetry: @MainActor () -> Void
    let onDeactivate: @MainActor () -> Void
    @FocusState private var nameIsFocused: Bool
    @AccessibilityFocusState private var nameIsAccessibilityFocused: Bool

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .productsFormLoading)
        case .failed(.load, let error):
            UnavailableStateView(
                title: .productsFormErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: error.productFormMessage
            ) {
                Button(action: onRetry) {
                    Text(.productsFormRetry)
                        .frame(minHeight: 44)
                }
                .primaryActionStyle()
                .disabled(isRequestPending)
            }
        default:
            Form {
                if isInactive {
                    Section {
                        Label {
                            Text(.productsFormInactive)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "pause.circle")
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.textSecondary)
                    }
                }
                if let error = state.formError, error != .invalidName {
                    Section {
                        Text(error.productFormMessage)
                            .foregroundStyle(.errorInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let progressMessage = state.progressMessage {
                    Section {
                        ProgressView {
                            Text(progressMessage)
                                .foregroundStyle(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                FormFieldSection(.productsFormName, systemImage: "shippingbox") {
                    TextField(
                        .productsFormName,
                        text: $name,
                        prompt: Text(.productsFormNamePlaceholder),
                        axis: .vertical
                    )
                    .accessibilityLabel(.productsFormName)
                    .textInputAutocapitalization(.sentences)
                    .focused($nameIsFocused)
                    .accessibilityFocused($nameIsAccessibilityFocused)
                    .accessibilityHint(.productsFormErrorName, isEnabled: state.formError == .invalidName)
                    .submitLabel(.done)
                    .onSubmit {
                        nameIsFocused = false
                    }
                    .frame(minHeight: 44)
                    .disabled(!canEdit || isRequestPending)
                    if state.formError == .invalidName {
                        Text(.productsFormErrorName)
                            .foregroundStyle(.errorInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if mode == .edit, !isInactive {
                    Section {
                        Button(role: .destructive, action: onDeactivate) {
                            Text(.productsFormDeactivate)
                                .foregroundStyle(.errorInk)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minHeight: 44)
                        }
                        .disabled(!canDeactivate || isRequestPending)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: validationAttemptID) {
                guard state.formError == .invalidName else { return }
                nameIsFocused = true
                nameIsAccessibilityFocused = true
            }
        }
    }
}

#Preview("Invalid name", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var name = ""

    ProductFormContent(
        name: $name,
        state: .failed(.save, .invalidName),
        mode: .create,
        isInactive: false,
        canEdit: true,
        canDeactivate: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetry: {},
        onDeactivate: {}
    )
}

#Preview("Load failure", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var name = ""

    ProductFormContent(
        name: $name,
        state: .failed(.load, .notFound),
        mode: .edit,
        isInactive: false,
        canEdit: false,
        canDeactivate: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetry: {},
        onDeactivate: {}
    )
}

#Preview("Save failure", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var name = ProductPreviewFixtures.standard.primaryProduct.name

    ProductFormContent(
        name: $name,
        state: .failed(.save, .persistenceUnavailable),
        mode: .edit,
        isInactive: false,
        canEdit: true,
        canDeactivate: true,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetry: {},
        onDeactivate: {}
    )
}

#Preview("Saving", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var name = ProductPreviewFixtures.standard.primaryProduct.name

    ProductFormContent(
        name: $name,
        state: .saving,
        mode: .edit,
        isInactive: false,
        canEdit: false,
        canDeactivate: false,
        isRequestPending: true,
        validationAttemptID: nil,
        onRetry: {},
        onDeactivate: {}
    )
}
