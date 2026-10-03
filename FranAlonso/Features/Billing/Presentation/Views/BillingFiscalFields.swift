import SwiftUI

struct BillingFiscalFields<Repository: BillingDocumentReservationRepository>: View {
    let viewModel: BillingViewModel<Repository>
    let focusedField: FocusState<BillingFiscalField?>.Binding
    let accessibleField: AccessibilityFocusState<BillingFiscalField?>.Binding

    var body: some View {
        Section {
            Text("billing.fiscal.instructions")
                .fixedSize(horizontal: false, vertical: true)
            if viewModel.isLoadingRecipient {
                HStack {
                    ProgressView().accessibilityHidden(true)
                    Text("billing.fiscal.loading")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text("billing.fiscal.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
        ForEach(BillingFiscalField.allCases, id: \.self) { field in
            FormFieldSection(field.localizedTitle, systemImage: "pencil") {
                TextField(field.localizedTitle, text: text(for: field), axis: .vertical)
                    .textContentType(field.contentType)
                    .textInputAutocapitalization(field.capitalization)
                    .autocorrectionDisabled()
                    .frame(minHeight: 44)
                    .disabled(!viewModel.isEditing)
                    .focused(focusedField, equals: field)
                    .accessibilityFocused(accessibleField, equals: field)
                    .accessibilityLabel(Text(field.localizedTitle))
                    .accessibilityHint(Text(viewModel.formIssue == .required(field) ?
                        field.requiredMessage : LocalizedStringResource("billing.fiscal.required")))
                if viewModel.formIssue == .required(field) {
                    Text(field.requiredMessage)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func text(for field: BillingFiscalField) -> Binding<String> {
        Binding { viewModel.fieldValue(field) } set: {
            viewModel.updateField(field, value: $0)
        }
    }
}

#Preview("Fiscal fields", traits: .modifier(BillingPreviewModifier())) {
    @Previewable @FocusState var focusedField: BillingFiscalField?
    @Previewable @AccessibilityFocusState var accessibleField: BillingFiscalField?
    Form {
        BillingFiscalFields(
            viewModel: BillingPreviewFixtures.model(kind: .invoice),
            focusedField: $focusedField,
            accessibleField: $accessibleField
        )
    }
}
