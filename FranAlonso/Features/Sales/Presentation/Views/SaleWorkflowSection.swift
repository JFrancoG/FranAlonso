import SwiftUI

struct SaleWorkflowSection: View {
    let viewModel: SaleDraftViewModel
    let isWorking: Bool
    let onAdvance: @MainActor (SaleProgressAction) -> Void
    let onPayment: @MainActor () -> Void
    let paymentIsFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        if viewModel.showsWorkflow {
            Section {
                ForEach(Array(viewModel.progressActions.enumerated()), id: \.offset) { _, action in
                    Button {
                        onAdvance(action)
                    } label: {
                        Text(viewModel.title(for: action)).frame(minHeight: 44)
                    }
                    .disabled(isWorking)
                }
                if viewModel.showsPayment {
                    Picker("sales.history.paymentMethod", selection: paymentMethod) {
                        Text("sales.payment.chooseMethod").tag(nil as PaymentMethod?)
                        Text("sales.history.cash").tag(PaymentMethod.cash as PaymentMethod?)
                        Text("sales.history.card").tag(PaymentMethod.card as PaymentMethod?)
                    }
                    .disabled(isWorking)
                    Button(action: onPayment) {
                        Text("sales.payment.register").frame(minHeight: 44)
                    }
                    .disabled(isWorking || !viewModel.canRegisterPayment)
                    .accessibilityFocused(paymentIsFocused)
                }
                if viewModel.awaitsDocument {
                    Text("sales.payment.documentPending").fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("sales.workflow.title").textCase(nil).accessibilityAddTraits(.isHeader)
            }
        }
    }

    private var paymentMethod: Binding<PaymentMethod?> {
        Binding { viewModel.selectedPaymentMethod } set: { viewModel.selectPaymentMethod($0) }
    }
}

#Preview("Workflow", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    @Previewable @AccessibilityFocusState var paymentIsFocused: Bool
    if let model = models[SalesPreviewFixtures.workday.sales[4].id] {
        Form {
            SaleWorkflowSection(
                viewModel: model,
                isWorking: false,
                onAdvance: { _ in },
                onPayment: {},
                paymentIsFocused: $paymentIsFocused
            )
        }
    }
}
