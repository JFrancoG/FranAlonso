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

    var body: some View {
        Form {
            errorSection
            if let sale = viewModel.sale {
                clientSection(sale)
                linesSection(sale)
                if let calculation = viewModel.calculation {
                    SaleTotalsSection(calculation: calculation)
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
            if viewModel.isReadOnly {
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
                    onIncrease: increaseAction(for: line.id),
                    onDecrease: decreaseAction(for: line.id),
                    onRemove: { onRemove(line.id) }
                )
                .disabled(isWorking)
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
    if let model = models[SalesPreviewFixtures.workday.sales[2].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {}
        )
    }
}

#Preview("In progress content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    if let model = models[SalesPreviewFixtures.workday.sales[3].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {}
        )
    }
}

#Preview("Awaiting payment content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    if let model = models[SalesPreviewFixtures.workday.sales[4].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {}
        )
    }
}

#Preview("Awaiting document content", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.salesPreviewModels) var models
    if let model = models[SalesPreviewFixtures.workday.sales[5].id] {
        SaleDraftContent(
            viewModel: model,
            isWorking: false,
            hasActionError: false,
            onCreate: {},
            onIncrease: { _ in },
            onDecrease: { _ in },
            onRemove: { _ in },
            onRetry: {}
        )
    }
}
