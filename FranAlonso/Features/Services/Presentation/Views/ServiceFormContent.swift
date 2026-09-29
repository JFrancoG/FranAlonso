import SwiftUI

struct ServiceFormContent: View {
    @Binding var draft: ServiceFormDraft
    let state: ServiceFormViewModel.State
    let mode: ServiceFormDestination.Mode
    let isInactive: Bool
    let canEdit: Bool
    let canDeactivate: Bool
    let isRequestPending: Bool
    let validationAttemptID: UUID?
    let onRetry: @MainActor () -> Void
    let onDeactivate: @MainActor () -> Void
    @FocusState private var focusedField: ServiceFormValidationField?
    @AccessibilityFocusState private var accessibleField: ServiceFormValidationField?

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .servicesFormLoading)
        case .failed(.load, let error):
            UnavailableStateView(
                title: .servicesFormErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: error.serviceFormMessage
            ) {
                Button(action: onRetry) {
                    Text(.servicesFormRetry)
                        .frame(minHeight: 44)
                }
                .primaryActionStyle()
                .disabled(isRequestPending)
            }
        default:
            Form {
                feedback
                nameSection
                typeSection
                decimalSection(
                    .servicesFormPrice,
                    systemImage: "banknote",
                    text: $draft.priceText,
                    field: .price,
                    hint: .servicesFormPriceHint
                )
                currencySection
                decimalSection(
                    .servicesFormTax,
                    systemImage: "percent",
                    text: $draft.taxText,
                    field: .tax,
                    hint: .servicesFormTaxHint
                )
                decimalSection(
                    .servicesFormDiscount,
                    systemImage: "tag",
                    text: $draft.discountText,
                    field: .discount,
                    hint: .servicesFormDiscountHint
                )
                if mode == .edit, !isInactive {
                    Section {
                        Button(role: .destructive, action: onDeactivate) {
                            Text(.servicesFormDeactivate)
                                .foregroundStyle(.errorInk)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minHeight: 44)
                        }
                        .disabled(!canDeactivate || isRequestPending)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Text(.servicesFormKeyboardDone)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
            .onChange(of: validationAttemptID) {
                guard let field = state.formError?.validationField else { return }
                focusedField = field
                accessibleField = field
            }
        }
    }

    @ViewBuilder
    private var feedback: some View {
        if isInactive {
            Section {
                Label {
                    Text(.servicesFormInactive)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "pause.circle")
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.textSecondary)
            }
        }
        if let error = state.formError, error.validationField == nil {
            Section {
                Text(error.serviceFormMessage)
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
    }

    private var nameSection: some View {
        FormFieldSection(.servicesFormName, systemImage: "text.alignleft") {
            TextField(
                .servicesFormName,
                text: $draft.name,
                prompt: Text(.servicesFormNamePlaceholder),
                axis: .vertical
            )
            .accessibilityLabel(.servicesFormName)
            .textInputAutocapitalization(.sentences)
            .focused($focusedField, equals: .name)
            .accessibilityFocused($accessibleField, equals: .name)
            .accessibilityHint(.servicesFormErrorName, isEnabled: state.formError?.validationField == .name)
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
            .frame(minHeight: 44)
            .disabled(!canEdit || isRequestPending)
            fieldError(.name)
        }
    }

    private var typeSection: some View {
        FormFieldSection(.servicesFormType, systemImage: "square.stack") {
            Text(draft.type == .professional ? .servicesTypeProfessional : .servicesTypeProduct)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(.servicesFormType)
                .accessibilityValue(draft.type == .professional ? .servicesTypeProfessional : .servicesTypeProduct)
            if draft.type == .product {
                Text(.servicesFormLinkedProductPreserved)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var currencySection: some View {
        FormFieldSection(.servicesFormCurrency, systemImage: "dollarsign.circle") {
            Picker(selection: $draft.currency) {
                Text(.servicesFormCurrencyEur).tag(Currency.eur)
                Text(.servicesFormCurrencyUsd).tag(Currency.usd)
            } label: {
                Text(.servicesFormCurrency)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityLabel(.servicesFormCurrency)
            .frame(minHeight: 44)
            .disabled(!canEdit || isRequestPending)
        }
    }

    private func decimalSection(
        _ label: LocalizedStringResource,
        systemImage: String,
        text: Binding<String>,
        field: ServiceFormValidationField,
        hint: LocalizedStringResource
    ) -> some View {
        FormFieldSection(label, systemImage: systemImage) {
            TextField(label, text: text)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled()
                .accessibilityLabel(label)
                .accessibilityHint(fieldHint(field, fallback: hint))
                .focused($focusedField, equals: field)
                .accessibilityFocused($accessibleField, equals: field)
                .frame(minHeight: 44)
                .disabled(!canEdit || isRequestPending)
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            fieldError(field)
        }
    }

    private func fieldHint(
        _ field: ServiceFormValidationField,
        fallback: LocalizedStringResource
    ) -> LocalizedStringResource {
        guard let error = state.formError, error.validationField == field else { return fallback }
        return error.serviceFormMessage
    }

    @ViewBuilder
    private func fieldError(_ field: ServiceFormValidationField) -> some View {
        if let error = state.formError, error.validationField == field {
            Text(error.serviceFormMessage)
                .foregroundStyle(.errorInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Invalid price", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var draft = ServiceFormDraft()

    ServiceFormContent(
        draft: $draft,
        state: .failed(.save, .invalidPriceInput),
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
    @Previewable @State var draft = ServiceFormDraft()

    ServiceFormContent(
        draft: $draft,
        state: .failed(.load, .service(.notFound)),
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

#Preview("Linked product unavailable", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var draft = ServiceFormDraft(
        service: ServicePreviewFixtures.standard.productService,
        locale: Locale(identifier: "es")
    )

    ServiceFormContent(
        draft: $draft,
        state: .failed(.save, .service(.linkedProductUnavailable)),
        mode: .edit,
        isInactive: false,
        canEdit: true,
        canDeactivate: true,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetry: {},
        onDeactivate: {}
    )
    .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Saving", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var draft = ServiceFormDraft(
        service: ServicePreviewFixtures.standard.professionalService,
        locale: Locale(identifier: "en")
    )

    ServiceFormContent(
        draft: $draft,
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
    .environment(\.locale, Locale(identifier: "en"))
}
