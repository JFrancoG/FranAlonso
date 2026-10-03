import SwiftUI

struct BillingSelectionContent<Repository: BillingDocumentReservationRepository>: View {
    let viewModel: BillingViewModel<Repository>
    let focusedField: FocusState<BillingFiscalField?>.Binding
    let accessibleField: AccessibilityFocusState<BillingFiscalField?>.Binding

    var body: some View {
        Form {
            if let request = viewModel.request {
                BillingPreparedContent(request: request)
            } else {
                Section {
                    Text("billing.selection.instructions")
                        .fixedSize(horizontal: false, vertical: true)
                    Picker("billing.selection.kind", selection: selection) {
                        Text(BillingDocumentKind.ticket.localizedTitle).tag(BillingDocumentKind.ticket)
                        Text(BillingDocumentKind.invoice.localizedTitle).tag(BillingDocumentKind.invoice)
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 44)
                    .disabled(!viewModel.isEditing)
                }
                if viewModel.selectedKind == .invoice {
                    BillingFiscalFields(
                        viewModel: viewModel,
                        focusedField: focusedField,
                        accessibleField: accessibleField
                    )
                } else {
                    Section {
                        Text("billing.selection.ticket.message")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if viewModel.formIssue == .unavailable {
                    Section {
                        Text("billing.selection.unavailable.title")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Text("billing.selection.unavailable.message")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Section {
                    Button {
                        _ = viewModel.prepareSelection()
                    } label: {
                        Text("billing.selection.prepare")
                            .frame(minHeight: 44)
                    }
                    .disabled(!viewModel.isEditing)
                }
            }
        }
    }

    private var selection: Binding<BillingDocumentKind> {
        Binding { viewModel.selectedKind } set: {
            viewModel.selectKind($0)
        }
    }
}

#Preview("Selection", traits: .modifier(BillingPreviewModifier())) {
    @Previewable @FocusState var focusedField: BillingFiscalField?
    @Previewable @AccessibilityFocusState var accessibleField: BillingFiscalField?
    BillingSelectionContent(
        viewModel: BillingPreviewFixtures.model(kind: .ticket),
        focusedField: $focusedField,
        accessibleField: $accessibleField
    )
}
