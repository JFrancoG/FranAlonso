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
    let linkableProductsState: ServiceFormViewModel.LinkableProductsState
    let onChangeType: @MainActor (ServiceType) -> Void
    let onSelectProduct: @MainActor (ProductID?) -> Void
    let onRetryProducts: @MainActor () -> Void
    let onRetry: @MainActor () -> Void
    let onDeactivate: @MainActor () -> Void
    var assistant: ServiceFormViewModel? = nil
    @FocusState private var focusedField: ServiceFormValidationField?
    @FocusState private var isAssistantInputFocused: Bool
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
                if let assistant, assistant.canUseAssistant {
                    ServiceDraftAssistantSection(
                        input: Binding(get: { assistant.assistantInput }, set: { assistant.assistantInput = $0 }),
                        inputFocus: $isAssistantInputFocused,
                        state: assistant.assistantState,
                        proposalName: assistant.assistantProposalName,
                        proposalPrice: assistant.assistantProposalPrice,
                        proposalTax: assistant.assistantProposalTax,
                        proposalDiscount: assistant.assistantProposalDiscount,
                        canEdit: canEdit && !isRequestPending,
                        canRequest: assistant.canRequestAssistant && !isRequestPending,
                        onRequest: assistant.requestAssistantProposal,
                        onCancel: assistant.cancelAssistant,
                        onApply: assistant.applyAssistantProposal,
                        onReject: assistant.rejectAssistantProposal,
                        onUndo: assistant.undoAssistantApplication
                    )
                }
                nameSection
                typeSection
                if draft.type == .product {
                    ServiceLinkedProductSection(
                        selection: draft.linkedProductID,
                        state: linkableProductsState,
                        error: state.formError?.validationField == .product ? state.formError : nil,
                        canEdit: canEdit && !isRequestPending,
                        validationAttemptID: validationAttemptID,
                        onSelect: onSelectProduct,
                        onRetry: onRetryProducts
                    )
                }
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
                        isAssistantInputFocused = false
                    } label: {
                        Text(.servicesFormKeyboardDone)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
            .onChange(of: validationAttemptID) {
                guard let field = state.formError?.validationField, field != .product else { return }
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
        if let error = state.formError,
           error.validationField == nil || (error.validationField == .product && draft.type == .professional) {
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
            Picker(selection: Binding(get: { draft.type }, set: onChangeType)) {
                Text(.servicesTypeProfessional).tag(ServiceType.professional)
                Text(.servicesTypeProduct).tag(ServiceType.product)
            } label: {
                Text(.servicesFormType)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityLabel(.servicesFormType)
            .frame(minHeight: 44)
            .disabled(!canEdit || isRequestPending)
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
        linkableProductsState: .loaded([]),
        onChangeType: { _ in },
        onSelectProduct: { _ in },
        onRetryProducts: {},
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
        linkableProductsState: .loaded([]),
        onChangeType: { _ in },
        onSelectProduct: { _ in },
        onRetryProducts: {},
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
        linkableProductsState: .loaded([]),
        onChangeType: { _ in },
        onSelectProduct: { _ in },
        onRetryProducts: {},
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
        linkableProductsState: .loaded([]),
        onChangeType: { _ in },
        onSelectProduct: { _ in },
        onRetryProducts: {},
        onRetry: {},
        onDeactivate: {}
    )
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Product form EN", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var draft = ServiceFormDraft(
        service: ServicePreviewFixtures.standard.productService,
        locale: Locale(identifier: "en")
    )

    NavigationStack {
        ServiceFormContent(
            draft: $draft,
            state: .editing,
            mode: .edit,
            isInactive: false,
            canEdit: true,
            canDeactivate: true,
            isRequestPending: false,
            validationAttemptID: nil,
            linkableProductsState: .loaded([ProductPreviewFixtures.standard.primaryProduct]),
            onChangeType: { _ in },
            onSelectProduct: { _ in },
            onRetryProducts: {},
            onRetry: {},
            onDeactivate: {}
        )
    }
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Assistant create ES", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var viewModel = ServicePreviewFixtures.makeAssistantForm(
        destination: ServicePreviewFixtures.assistantDestination,
        locale: Locale(identifier: "es")
    )

    NavigationStack {
        ServiceFormContent(
            draft: Binding(get: { viewModel.draft }, set: { viewModel.draft = $0 }),
            state: .editing,
            mode: .create,
            isInactive: false,
            canEdit: true,
            canDeactivate: false,
            isRequestPending: false,
            validationAttemptID: nil,
            linkableProductsState: .loaded([]),
            onChangeType: viewModel.changeType,
            onSelectProduct: viewModel.selectLinkedProduct,
            onRetryProducts: {},
            onRetry: {},
            onDeactivate: {},
            assistant: viewModel
        )
        .navigationTitle(Text(.servicesFormCreateTitle))
        .task(id: viewModel.assistantRequestID) {
            guard let requestID = viewModel.assistantRequestID else { return }
            await viewModel.generateAssistantProposal(for: requestID)
        }
    }
    .environment(\.locale, Locale(identifier: "es"))
}
