import SwiftUI

struct ServiceDraftAssistantSection: View {
    @Binding var input: String
    let inputFocus: FocusState<Bool>.Binding
    let state: ServiceDraftAssistantState
    let proposalName: String?
    let proposalPrice: String?
    let proposalTax: String?
    let proposalDiscount: String?
    let canEdit: Bool
    let canRequest: Bool
    let onRequest: @MainActor () -> Void
    let onCancel: @MainActor () -> Void
    let onApply: @MainActor () -> Void
    let onReject: @MainActor () -> Void
    let onUndo: @MainActor () -> Void

    var body: some View {
        Section {
            inputField
            feedback
            actions
        } header: {
            Text(.servicesAssistantTitle)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.servicesAssistantInput)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            TextField(
                .servicesAssistantInput,
                text: $input,
                prompt: Text(.servicesAssistantInputPlaceholder),
                axis: .vertical
            )
            .textInputAutocapitalization(.sentences)
            .accessibilityLabel(.servicesAssistantInput)
            .accessibilityHint(state.message ?? .servicesAssistantInputHint)
            .focused(inputFocus)
            .submitLabel(.done)
            .onSubmit {
                inputFocus.wrappedValue = false
            }
            .frame(minHeight: 44)
            .disabled(!canEdit)
            Text(.servicesAssistantInputHint)
                .font(.footnote)
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var feedback: some View {
        switch state {
        case .idle:
            EmptyView()
        case .generating:
            ProgressView {
                Text(.servicesAssistantGenerating)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .proposed:
            if let message = state.message {
                Text(message)
                    .fixedSize(horizontal: false, vertical: true)
            }
            proposalField(.servicesFormName, value: proposalName)
            proposalField(.servicesFormPrice, value: proposalPrice)
            proposalField(.servicesFormTax, value: proposalTax)
            proposalField(.servicesFormDiscount, value: proposalDiscount)
        case .applied, .unavailable:
            if let message = state.message {
                Text(message)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .failed:
            if let message = state.message {
                Text(message)
                    .foregroundStyle(.errorInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .generating:
            action(.servicesAssistantCancel, enabled: canEdit, perform: onCancel)
        case .proposed:
            action(.servicesAssistantApply, enabled: canEdit, perform: onApply)
            action(.servicesAssistantReject, enabled: canEdit, perform: onReject)
        case .applied:
            action(.servicesAssistantUndo, enabled: canEdit, perform: onUndo)
            action(.servicesAssistantGenerate, enabled: canRequest, perform: onRequest)
        case .idle, .failed, .unavailable:
            action(.servicesAssistantGenerate, enabled: canRequest, perform: onRequest)
        }
    }

    @ViewBuilder
    private func proposalField(_ title: LocalizedStringResource, value: String?) -> some View {
        if let value {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Text(value)
                    .foregroundStyle(.textPrimary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
        }
    }

    private func action(
        _ title: LocalizedStringResource,
        enabled: Bool,
        perform: @escaping @MainActor () -> Void
    ) -> some View {
        Button {
            inputFocus.wrappedValue = false
            perform()
        } label: {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
        }
        .disabled(!enabled)
    }
}

private extension ServiceDraftAssistantSection {
    static let previewProposal: ServiceDraftProposal = {
        do {
            return try ServiceDraftProposal(
                name: "Corte y peinado con tratamiento de hidratación",
                price: Money(amount: 35, currency: .eur)
            )
        } catch {
            preconditionFailure("The fixed assistant preview must satisfy proposal invariants")
        }
    }()

    static func preview(state: ServiceDraftAssistantState, inputFocus: FocusState<Bool>.Binding) -> some View {
        Form {
            ServiceDraftAssistantSection(
                input: .constant("Servicio profesional de corte y peinado, precio 35 euros"),
                inputFocus: inputFocus,
                state: state,
                proposalName: previewProposal.name,
                proposalPrice: "35,00 €",
                proposalTax: nil,
                proposalDiscount: nil,
                canEdit: true,
                canRequest: true,
                onRequest: {},
                onCancel: {},
                onApply: {},
                onReject: {},
                onUndo: {}
            )
        }
    }
}

#Preview("Assistant idle ES Large", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .idle, inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "es"))
        .dynamicTypeSize(.large)
}

#Preview("Assistant review ES AX 5", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .proposed(ServiceDraftAssistantSection.previewProposal), inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "es"))
        .dynamicTypeSize(.accessibility5)
}

#Preview("Assistant error EN XXX Large", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .failed(.clarification), inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "en"))
        .dynamicTypeSize(.xxxLarge)
        .preferredColorScheme(.dark)
}

#Preview("Assistant generating ES", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .generating, inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Assistant unavailable EN", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .unavailable(.intelligenceDisabled), inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Assistant applied ES", traits: .modifier(AppPreviewModifier())) {
    @Previewable @FocusState var inputIsFocused: Bool
    ServiceDraftAssistantSection.preview(state: .applied, inputFocus: $inputIsFocused)
        .environment(\.locale, Locale(identifier: "es"))
}
