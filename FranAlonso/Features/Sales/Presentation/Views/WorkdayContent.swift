import SwiftUI

struct WorkdayContent: View {
    let state: WorkdayViewModel.State
    let clientNames: [ClientID: String]
    let focusedSale: AccessibilityFocusState<SaleID?>.Binding
    let onSelect: @MainActor (SaleID) -> Void
    let onRetry: @MainActor () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: "sales.workday.loading")
        case .empty, .closed:
            UnavailableStateView(
                title: "sales.workday.empty.title",
                systemImage: "calendar",
                message: "sales.workday.empty.message"
            )
        case let .content(board):
            List {
                saleSection("sales.workday.upcoming", sales: board.upcoming)
                saleSection("sales.workday.inProgress", sales: board.inProgress)
                saleSection("sales.workday.awaitingClosure", sales: board.awaitingClosure)
            }
        case .failed:
            UnavailableStateView(
                title: "sales.workday.error.title",
                systemImage: "exclamationmark.triangle",
                message: "sales.workday.error.message"
            ) {
                Button(action: onRetry) {
                    Text("sales.retry")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func saleSection(_ title: LocalizedStringResource, sales: [Sale]) -> some View {
        Section {
            if sales.isEmpty {
                Text("sales.workday.section.empty")
                    .foregroundStyle(.textSecondary)
            }
            ForEach(sales) { sale in
                WorkdaySaleRow(sale: sale, clientName: sale.clientID.flatMap { clientNames[$0] }) {
                    onSelect(sale.id)
                }
                .accessibilityFocused(focusedSale, equals: sale.id)
            }
        } header: {
            Text(title)
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

#Preview("Empty", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focus: SaleID?
    WorkdayContent(state: .empty, clientNames: [:], focusedSale: $focus, onSelect: { _ in }, onRetry: {})
}

#Preview("Several clients", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focus: SaleID?
    WorkdayContent(
        state: .content(WorkdaySalesPolicy()(SalesPreviewFixtures.workday.sales)),
        clientNames: [SalesPreviewFixtures.albaID: "Alba DEMO", SalesPreviewFixtures.brunoID: "Bruno DEMO"],
        focusedSale: $focus,
        onSelect: { _ in },
        onRetry: {}
    )
}
