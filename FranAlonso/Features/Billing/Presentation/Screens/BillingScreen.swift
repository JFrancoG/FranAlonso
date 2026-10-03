import Accessibility
import SwiftUI

struct BillingScreen<Repository: BillingDocumentReservationRepository>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: BillingViewModel<Repository>
    @FocusState private var focusedField: BillingFiscalField?
    @AccessibilityFocusState private var accessibleField: BillingFiscalField?

    var body: some View {
        NavigationStack {
            BillingSelectionContent(
                viewModel: viewModel,
                focusedField: $focusedField,
                accessibleField: $accessibleField
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
