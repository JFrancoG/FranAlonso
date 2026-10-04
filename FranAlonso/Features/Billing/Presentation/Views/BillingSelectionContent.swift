import SwiftUI

struct BillingSelectionContent<Repository: BillingDocumentReservationRepository>: View {
    let viewModel: BillingViewModel<Repository>
    let focusedField: FocusState<BillingFiscalField?>.Binding
    let accessibleField: AccessibilityFocusState<BillingFiscalField?>.Binding
    let closureIsFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        Form {
            if viewModel.isDemonstration {
                Section {
                    Text("billing.demo.pdf.mark")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            if let request = viewModel.request {
                BillingPreparedContent(request: request)
                if viewModel.requiresPersistence {
                    BillingDocumentProgressView(viewModel: viewModel, closureIsFocused: closureIsFocused)
                }
            } else {
                if viewModel.isWorking || viewModel.recoveryFailed || viewModel.requiresDocumentSelection {
                    BillingDocumentProgressView(viewModel: viewModel, closureIsFocused: closureIsFocused)
                }
                Section {
                    Text("billing.selection.instructions")
                        .fixedSize(horizontal: false, vertical: true)
                    Picker("billing.selection.kind", selection: selection) {
                        Text(BillingDocumentKind.ticket.localizedTitle).tag(BillingDocumentKind.ticket)
                        Text(BillingDocumentKind.invoice.localizedTitle).tag(BillingDocumentKind.invoice)
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 44)
                    .disabled(!viewModel.canSelectKind)
                }
                if viewModel.requiresDocumentSelection {
                    Section {
                        Button {
                            viewModel.requestSelectedDocumentRecovery()
                        } label: {
                            Text("billing.document.recover.selected")
                                .frame(minHeight: 44)
                        }
                        .disabled(!viewModel.canSelectKind)
                    }
                } else {
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
                            viewModel.requestPreparation()
                        } label: {
                            Text("billing.selection.prepare")
                                .frame(minHeight: 44)
                        }
                        .disabled(!viewModel.isEditing)
                    }
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
    @Previewable @AccessibilityFocusState var closureIsFocused: Bool
    BillingSelectionContent(
        viewModel: BillingPreviewFixtures.model(kind: .ticket),
        focusedField: $focusedField,
        accessibleField: $accessibleField,
        closureIsFocused: $closureIsFocused
    )
}
