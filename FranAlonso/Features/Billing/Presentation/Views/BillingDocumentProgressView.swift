import SwiftUI

struct BillingDocumentProgressView<Repository: BillingDocumentReservationRepository>: View {
    let viewModel: BillingViewModel<Repository>
    let closureIsFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        Section {
            if viewModel.isWorking {
                ProgressView { Text(viewModel.progressMessage) }
            } else {
                Text(viewModel.progressMessage)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let document = viewModel.document {
                LabeledContent("billing.document.number") {
                    Text(document.number.value, format: .number.grouping(.never))
                        .fontWeight(.semibold)
                }
                .accessibilityElement(children: .combine)
            }
            if viewModel.operationFailed || viewModel.closureFailure != nil {
                Text("billing.document.error.title")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("billing.document.error.message")
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewModel.recoveryFailed, !viewModel.requiresDocumentSelection {
                Button {
                    viewModel.requestLoad()
                } label: {
                    Text("billing.document.recover.retry")
                        .frame(minHeight: 44)
                }
                .disabled(viewModel.isWorking)
            } else if viewModel.delivery != nil, viewModel.closedSale == nil {
                Button {
                    viewModel.requestGeneration()
                } label: {
                    Text(viewModel.generationActionTitle)
                        .frame(minHeight: 44)
                }
                .disabled(!viewModel.canGenerate)
                Button {
                    viewModel.requestSaleClosure()
                } label: {
                    Text("billing.closure.action")
                        .frame(minHeight: 44)
                }
                .disabled(!viewModel.canCloseSale || viewModel.isWorking)
                .accessibilityFocused(closureIsFocused)
                Text("billing.closure.instructions")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("billing.document.progress.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

#Preview("PDF ready for closure", traits: .modifier(BillingProgressPreviewModifier(stage: .closable))) {
    @Previewable @AccessibilityFocusState var closureIsFocused: Bool
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        Form { BillingDocumentProgressView(viewModel: model, closureIsFocused: $closureIsFocused) }
    }
}

#Preview("Pending number error", traits: .modifier(BillingProgressPreviewModifier(stage: .pending))) {
    @Previewable @AccessibilityFocusState var closureIsFocused: Bool
    @Previewable @Environment(\.billingProgressPreviewModel) var model
    if let model {
        Form { BillingDocumentProgressView(viewModel: model, closureIsFocused: $closureIsFocused) }
    }
}
