import SwiftUI

struct SaleDraftContent: View {
    let viewModel: SaleDraftViewModel
    let isWorking: Bool
    let hasActionError: Bool
    let onCreate: @MainActor () -> Void
    let onIncrease: @MainActor (SaleLineID) -> Void
    let onDecrease: @MainActor (SaleLineID) -> Void
    let onRemove: @MainActor (SaleLineID) -> Void
    let onRetry: @MainActor () -> Void
    let onAddService: @MainActor () -> Void
    let addServiceIsFocused: AccessibilityFocusState<Bool>.Binding
    let onEditDiscount: @MainActor (SaleLineID) -> Void
    let discountIsFocused: AccessibilityFocusState<SaleLineID?>.Binding
    let onEditGlobalDiscount: @MainActor () -> Void
    let globalDiscountIsFocused: AccessibilityFocusState<Bool>.Binding
    var onAdvance: @MainActor (SaleProgressAction) -> Void = { _ in }
    var onPayment: @MainActor () -> Void = {}
    var paymentIsFocused: AccessibilityFocusState<Bool>.Binding?

    var body: some View {
        Form {
            errorSection
            if let sale = viewModel.sale {
                clientSection(sale)
                linesSection(sale)
                SaleGlobalDiscountSection(
                    discount: sale.globalDiscount,
                    isReadOnly: viewModel.isReadOnly,
                    canEdit: !isWorking && viewModel.canEditGlobalDiscount,
                    onEdit: onEditGlobalDiscount,
                    isFocused: globalDiscountIsFocused
                )
                if let calculation = viewModel.calculation {
                    SaleTotalsSection(calculation: calculation)
                }
                if let paymentIsFocused {
                    SaleWorkflowSection(
                        viewModel: viewModel,
                        isWorking: isWorking,
                        onAdvance: onAdvance,
                        onPayment: onPayment,
                        paymentIsFocused: paymentIsFocused
                    )
                }
            } else if viewModel.canCreate {
                Section {
                    Text("sales.create.message")
                    Button(action: onCreate) {
                        Text("sales.create.accept")
                            .frame(minHeight: 44)
                    }
                    .disabled(isWorking)
                }
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if hasActionError {
            Section {
                Text("sales.action.error.title")
                    .font(.headline)
                Text("sales.action.error.message")
                Button(action: onRetry) {
                    Text("sales.retry")
                        .frame(minHeight: 44)
                }
                .disabled(isWorking)
            }
        }
    }

    private func clientSection(_ sale: Sale) -> some View {
        Section {
            if let name = viewModel.clientDisplayName {
                Text(name)
            } else {
                Text(sale.clientID == nil ? LocalizedStringResource("sales.client.none") :
                    LocalizedStringResource("sales.client.unavailable"))
            }
            Text(sale.status.localizedTitle)
            Text(sale.createdAt, format: .dateTime.day().month().year().hour().minute())
            if viewModel.destination.mode == .inspect {
                Text("sales.detail.readOnly")
                    .font(.footnote)
            }
        }
    }

    private func linesSection(_ sale: Sale) -> some View {
        Section {
            if sale.lines.isEmpty {
                Text("sales.lines.empty")
            }
            ForEach(sale.lines) { line in
                SaleDraftLineRow(
                    line: line,
                    isReadOnly: viewModel.isReadOnly,
                    stockWarning: viewModel.stockWarning(for: line.id),
                    onIncrease: increaseAction(for: line.id),
                    onDecrease: decreaseAction(for: line.id),
                    onRemove: { onRemove(line.id) },
                    onEditDiscount: { onEditDiscount(line.id) },
                    discountIsFocused: discountIsFocused
                )
                .disabled(isWorking)
            }
            if !viewModel.isReadOnly {
                Button(action: onAddService) {
                    Label("sales.services.add", systemImage: "plus")
                        .frame(minHeight: 44)
                }
                .disabled(isWorking || !viewModel.canAddServices)
                .accessibilityFocused(addServiceIsFocused)
            }
        } header: {
            Text("sales.lines.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func increaseAction(for id: SaleLineID) -> (@MainActor () -> Void)? {
        guard viewModel.canIncrease(for: id) else { return nil }
        return { onIncrease(id) }
    }

    private func decreaseAction(for id: SaleLineID) -> (@MainActor () -> Void)? {
        guard viewModel.canDecrease(for: id) else { return nil }
        return { onDecrease(id) }
    }
}

#Preview("Accepted draft", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    @Previewable @AccessibilityFocusState var addServiceIsFocused: Bool
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    @Previewable @AccessibilityFocusState var globalDiscountIsFocused: Bool
    if let model = models[SalesPreviewFixtures.workday.sales[2].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {},
            onAddService: {},
            addServiceIsFocused: $addServiceIsFocused,
            onEditDiscount: { _ in },
            discountIsFocused: $discountIsFocused,
            onEditGlobalDiscount: {},
            globalDiscountIsFocused: $globalDiscountIsFocused
        )
    }
}

#Preview("In progress content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    @Previewable @AccessibilityFocusState var addServiceIsFocused: Bool
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    @Previewable @AccessibilityFocusState var globalDiscountIsFocused: Bool
    if let model = models[SalesPreviewFixtures.workday.sales[3].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {},
            onAddService: {},
            addServiceIsFocused: $addServiceIsFocused,
            onEditDiscount: { _ in },
            discountIsFocused: $discountIsFocused,
            onEditGlobalDiscount: {},
            globalDiscountIsFocused: $globalDiscountIsFocused
        )
    }
}

#Preview("Awaiting payment content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    @Previewable @AccessibilityFocusState var addServiceIsFocused: Bool
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    @Previewable @AccessibilityFocusState var globalDiscountIsFocused: Bool
    if let model = models[SalesPreviewFixtures.workday.sales[4].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {},
            onAddService: {},
            addServiceIsFocused: $addServiceIsFocused,
            onEditDiscount: { _ in },
            discountIsFocused: $discountIsFocused,
            onEditGlobalDiscount: {},
            globalDiscountIsFocused: $globalDiscountIsFocused
        )
    }
}

#Preview("Awaiting document content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    @Previewable @AccessibilityFocusState var addServiceIsFocused: Bool
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    @Previewable @AccessibilityFocusState var globalDiscountIsFocused: Bool
    if let model = models[SalesPreviewFixtures.workday.sales[5].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {},
            onAddService: {},
            addServiceIsFocused: $addServiceIsFocused,
            onEditDiscount: { _ in },
            discountIsFocused: $discountIsFocused,
            onEditGlobalDiscount: {},
            globalDiscountIsFocused: $globalDiscountIsFocused
        )
    }
}

#Preview("Stock warnings content", traits: .modifier(SaleStockPreviewModifier())) {
    @Previewable @Environment(\.saleStockPreviewModel) var model
    @Previewable @AccessibilityFocusState var addServiceIsFocused: Bool
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    @Previewable @AccessibilityFocusState var globalDiscountIsFocused: Bool
    if let model {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {},
            onAddService: {},
            addServiceIsFocused: $addServiceIsFocused,
            onEditDiscount: { _ in },
            discountIsFocused: $discountIsFocused,
            onEditGlobalDiscount: {},
            globalDiscountIsFocused: $globalDiscountIsFocused
        )
    }
}
