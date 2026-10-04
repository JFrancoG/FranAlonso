import Accessibility
import SwiftData
import SwiftUI

struct BillingScreen<Repository: BillingDocumentReservationRepository>: View {
    private let runsOperations: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BillingViewModel<Repository>
    @FocusState private var focusedField: BillingFiscalField?
    @AccessibilityFocusState private var accessibleField: BillingFiscalField?
    @AccessibilityFocusState private var closureIsFocused: Bool

    var body: some View {
        let operationRequest = viewModel.operationRequest
        return NavigationStack {
            BillingSelectionContent(
                viewModel: viewModel,
                focusedField: $focusedField,
                accessibleField: $accessibleField,
                closureIsFocused: $closureIsFocused
            )
            .navigationTitle(Text("billing.selection.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.request == nil ? LocalizedStringResource("billing.selection.cancel") :
                        LocalizedStringResource("billing.selection.close")) {
                        viewModel.close()
                        dismiss()
                    }
                }
            }
        }
        .task(id: operationRequest) {
            if runsOperations {
                await viewModel.performRequestedOperation(operationRequest, in: modelContext)
            }
        }
        .task(id: viewModel.selectedKind) {
            if viewModel.selectedKind == .invoice {
                await viewModel.loadRecipient()
            }
        }
        .onChange(of: viewModel.validationID) {
            switch viewModel.formIssue {
            case let .required(field):
                focusedField = field
                accessibleField = field
                announce(field.requiredMessage)
            case .unavailable:
                announce("billing.selection.unavailable.message")
            case nil:
                break
            }
        }
        .onChange(of: viewModel.request?.id) { _, id in
            if id != nil {
                focusedField = nil
                accessibleField = nil
                announce("billing.prepared.message")
            }
        }
        .onChange(of: viewModel.operationAnnouncementID) {
            announce(viewModel.operationAnnouncement)
            if viewModel.canCloseSale, !viewModel.operationFailed {
                closureIsFocused = true
            }
            if viewModel.closedSale != nil {
                dismiss()
            }
        }
        .onDisappear {
            viewModel.close()
        }
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension BillingScreen {
    init(makeViewModel: @MainActor @Sendable () -> BillingViewModel<Repository>) {
        _viewModel = State(initialValue: makeViewModel())
        runsOperations = true
    }

    fileprivate init(previewModel: BillingViewModel<Repository>) {
        _viewModel = State(initialValue: previewModel)
        runsOperations = false
    }
}

#Preview("Ticket selection", traits: .modifier(BillingPreviewModifier())) {
    BillingScreen { BillingPreviewFixtures.model(kind: .ticket) }
}

#Preview("Invoice form", traits: .modifier(BillingPreviewModifier())) {
    BillingScreen { BillingPreviewFixtures.model(kind: .invoice) }
}

#Preview("Invoice error", traits: .modifier(BillingPreviewModifier())) {
    BillingScreen { BillingPreviewFixtures.model(kind: .invoice, invalid: true) }
}

#Preview("Prepared invoice", traits: .modifier(BillingPreviewModifier())) {
    BillingScreen { BillingPreviewFixtures.model(kind: .invoice, prepared: true) }
}

#Preview("Invoice form English", traits: .modifier(BillingPreviewModifier())) {
    BillingScreen { BillingPreviewFixtures.model(kind: .invoice) }
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Recovery error", traits: .modifier(BillingProgressPreviewModifier(stage: .recovery))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
    }
}

#Preview("Pending numbering", traits: .modifier(BillingProgressPreviewModifier(stage: .pending))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
    }
}

#Preview("Generating PDF", traits: .modifier(BillingProgressPreviewModifier(stage: .generating))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
    }
}

#Preview("PDF closure available", traits: .modifier(BillingProgressPreviewModifier(stage: .closable))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
    }
}

#Preview("Accepted closure English", traits: .modifier(BillingProgressPreviewModifier(stage: .accepted))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
            .environment(\.locale, Locale(identifier: "en"))
    }
}

#Preview("Saved document family choice", traits: .modifier(BillingProgressPreviewModifier(stage: .choosingFamily))) {
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        BillingScreen(previewModel: model)
    }
}
