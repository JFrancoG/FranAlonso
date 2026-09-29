import SwiftUI

struct StockAdjustmentContent: View {
    @Binding var direction: StockAdjustmentDirection
    @Binding var unitsText: String
    @Binding var reason: String
    let state: StockAdjustmentViewModel.State
    let balanceState: StockAdjustmentViewModel.BalanceState
    let productName: String
    let quantity: Int?
    let canEdit: Bool
    let isRequestPending: Bool
    let validationAttemptID: UUID?
    let onRetryLoad: @MainActor () -> Void
    let onRefresh: @MainActor () -> Void
    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var accessibleField: Field?

    private enum Field: Hashable {
        case units, reason
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .stockAdjustmentLoading)
        case .failed(.load, let error):
            UnavailableStateView(
                title: .stockAdjustmentErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: error.stockAdjustmentMessage
            ) {
                Button(action: onRetryLoad) {
                    Text(.stockAdjustmentRetry)
                        .frame(minHeight: 44)
                }
                .primaryActionStyle()
                .disabled(isRequestPending)
            }
        default:
            Form {
                Section {
                    Text(productName)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    balance
                } header: {
                    Text(.stockAdjustmentProduct)
                }
                if state == .saved {
                    savedStatus
                } else {
                    editableFields
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: validationAttemptID) {
                switch state {
                case .failed(.validation, .invalidQuantity), .failed(.validation, .invalidDelta):
                    focusedField = .units
                    accessibleField = .units
                case .failed(.validation, .invalidReason):
                    focusedField = .reason
                    accessibleField = .reason
                default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var balance: some View {
        if state != .saved || balanceState.isLoaded {
            if let quantity {
                LabeledContent {
                    Text(quantity, format: .number)
                } label: {
                    Text(.stockAdjustmentBalance)
                }
                if quantity < 0 {
                    Text(.stockAdjustmentNegative)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var savedStatus: some View {
        Section {
            Label {
                Text(.stockAdjustmentSaved)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.circle")
                    .accessibilityHidden(true)
            }
            .accessibilityAddTraits(.isHeader)
            switch balanceState {
            case .idle, .loading:
                ProgressView {
                    Text(.stockAdjustmentRefreshing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .failed:
                Text(.stockAdjustmentRefreshError)
                    .foregroundStyle(.errorInk)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: onRefresh) {
                    Text(.stockAdjustmentRefresh)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                }
                .disabled(isRequestPending)
            case .loaded:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var editableFields: some View {
        if let error = state.stockError {
            Section {
                Text(error.stockAdjustmentMessage)
                    .foregroundStyle(.errorInk)
                    .fixedSize(horizontal: false, vertical: true)
                if case .failed(.save, _) = state {
                    Text(.stockAdjustmentFrozen)
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        if state == .saving {
            Section {
                ProgressView {
                    Text(.stockAdjustmentSaving)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        Section {
            Picker(selection: $direction) {
                Text(.stockAdjustmentEntry).tag(StockAdjustmentDirection.entry)
                Text(.stockAdjustmentWithdrawal).tag(StockAdjustmentDirection.withdrawal)
            } label: {
                Text(.stockAdjustmentDirection)
            }
            .pickerStyle(.menu)
            .frame(minHeight: 44)
            .disabled(!canEdit || isRequestPending)
        }
        FormFieldSection(.stockAdjustmentUnits, systemImage: "number") {
            TextField(.stockAdjustmentUnits, text: $unitsText, prompt: Text(.stockAdjustmentUnits))
                .keyboardType(.numberPad)
                .accessibilityLabel(.stockAdjustmentUnits)
                .accessibilityHint(.stockAdjustmentErrorQuantity, isEnabled: state.stockError == .invalidQuantity)
                .focused($focusedField, equals: .units)
                .accessibilityFocused($accessibleField, equals: .units)
                .frame(minHeight: 44)
                .disabled(!canEdit || isRequestPending)
        }
        FormFieldSection(.stockAdjustmentReason, systemImage: "text.alignleft") {
            TextField(
                .stockAdjustmentReason,
                text: $reason,
                prompt: Text(.stockAdjustmentReasonPlaceholder),
                axis: .vertical
            )
            .accessibilityLabel(.stockAdjustmentReason)
            .accessibilityHint(.stockAdjustmentErrorReason, isEnabled: state.stockError == .invalidReason)
            .focused($focusedField, equals: .reason)
            .accessibilityFocused($accessibleField, equals: .reason)
            .textInputAutocapitalization(.sentences)
            .frame(minHeight: 44)
            .disabled(!canEdit || isRequestPending)
        }
    }
}

#Preview("Editing", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.withdrawal),
        unitsText: .constant("3"),
        reason: .constant("Recuento de inventario"),
        state: .editing,
        balanceState: .idle,
        productName: ProductPreviewFixtures.standard.primaryProduct.name,
        quantity: 8,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Invalid units", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.entry),
        unitsText: .constant("0"),
        reason: .constant("Inventario"),
        state: .failed(.validation, .invalidQuantity),
        balanceState: .idle,
        productName: ProductPreviewFixtures.standard.primaryProduct.name,
        quantity: 8,
        canEdit: true,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Saved negative", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.withdrawal),
        unitsText: .constant("10"),
        reason: .constant("Recuento"),
        state: .saved,
        balanceState: .loaded(-2),
        productName: ProductPreviewFixtures.standard.primaryProduct.name,
        quantity: -2,
        canEdit: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Accepted refresh failed", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.entry),
        unitsText: .constant("3"),
        reason: .constant("Inventario"),
        state: .saved,
        balanceState: .failed(.storageFailure),
        productName: ProductPreviewFixtures.standard.primaryProduct.name,
        quantity: 8,
        canEdit: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Saving", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.entry),
        unitsText: .constant("3"),
        reason: .constant("Inventario"),
        state: .saving,
        balanceState: .idle,
        productName: ProductPreviewFixtures.standard.primaryProduct.name,
        quantity: 8,
        canEdit: false,
        isRequestPending: true,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Load failure", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.entry),
        unitsText: .constant(""),
        reason: .constant(""),
        state: .failed(.load, .productNotFound),
        balanceState: .idle,
        productName: "",
        quantity: nil,
        canEdit: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    StockAdjustmentContent(
        direction: .constant(.entry),
        unitsText: .constant(""),
        reason: .constant(""),
        state: .loading,
        balanceState: .idle,
        productName: "",
        quantity: nil,
        canEdit: false,
        isRequestPending: false,
        validationAttemptID: nil,
        onRetryLoad: {},
        onRefresh: {}
    )
}
