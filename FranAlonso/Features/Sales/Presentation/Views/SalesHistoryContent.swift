import SwiftUI

struct SalesHistoryContent: View {
    let state: SalesHistoryViewModel.State
    let sales: [Sale]
    let clientNames: [ClientID: String]
    @Binding var filter: SalesHistoryFilter
    @Binding var order: SalesHistoryOrder
    let focusedSale: AccessibilityFocusState<SaleID?>.Binding
    let filterIsFocused: AccessibilityFocusState<Bool>.Binding
    let onSelect: @MainActor (SaleID) -> Void
    let onRetry: @MainActor () -> Void
    let onReset: @MainActor () -> Void

    var body: some View {
        List {
            Section {
                SalesHistoryFilters(filter: $filter, order: $order, filterIsFocused: filterIsFocused)
            }

            switch state {
            case .idle, .loading:
                LoadingStateView(label: "sales.history.loading")
            case .failed:
                UnavailableStateView(
                    title: "sales.history.error.title",
                    systemImage: "exclamationmark.triangle",
                    message: "sales.history.error.message"
                ) {
                    Button(action: onRetry) {
                        Text("sales.retry").frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
            case .content, .closed:
                if sales.isEmpty {
                    UnavailableStateView(
                        title: "sales.history.empty.title",
                        systemImage: "clock.arrow.circlepath",
                        message: "sales.history.empty.message"
                    ) {
                        Button(action: onReset) {
                            Text("sales.history.reset").frame(minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Section {
                        ForEach(sales) { sale in
                            SalesHistoryRow(sale: sale, clientName: sale.clientID.flatMap { clientNames[$0] }) {
                                onSelect(sale.id)
                            }
                            .accessibilityFocused(focusedSale, equals: sale.id)
                        }
                    } header: {
                        Text("sales.history.operations")
                            .textCase(nil)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
        }
    }
}

#Preview("Empty", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedSale: SaleID?
    @Previewable @AccessibilityFocusState var filterIsFocused: Bool
    SalesHistoryContent(
        state: .content([]),
        sales: [],
        clientNames: [:],
        filter: .constant(.all),
        order: .constant(.newestFirst),
        focusedSale: $focusedSale,
        filterIsFocused: $filterIsFocused,
        onSelect: { _ in },
        onRetry: {},
        onReset: {}
    )
}

#Preview("Error", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedSale: SaleID?
    @Previewable @AccessibilityFocusState var filterIsFocused: Bool
    SalesHistoryContent(
        state: .failed,
        sales: [],
        clientNames: [:],
        filter: .constant(.all),
        order: .constant(.newestFirst),
        focusedSale: $focusedSale,
        filterIsFocused: $filterIsFocused,
        onSelect: { _ in },
        onRetry: {},
        onReset: {}
    )
}

#Preview("Loading", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedSale: SaleID?
    @Previewable @AccessibilityFocusState var filterIsFocused: Bool
    SalesHistoryContent(
        state: .loading,
        sales: [],
        clientNames: [:],
        filter: .constant(.all),
        order: .constant(.newestFirst),
        focusedSale: $focusedSale,
        filterIsFocused: $filterIsFocused,
        onSelect: { _ in },
        onRetry: {},
        onReset: {}
    )
}

#Preview("Several clients", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @AccessibilityFocusState var focusedSale: SaleID?
    @Previewable @AccessibilityFocusState var filterIsFocused: Bool
    SalesHistoryContent(
        state: .content(SalesPreviewFixtures.history.sales),
        sales: SalesHistoryPolicy()(SalesPreviewFixtures.history.sales),
        clientNames: [SalesPreviewFixtures.albaID: "Alba DEMO", SalesPreviewFixtures.brunoID: "Bruno DEMO"],
        filter: .constant(.all),
        order: .constant(.newestFirst),
        focusedSale: $focusedSale,
        filterIsFocused: $filterIsFocused,
        onSelect: { _ in },
        onRetry: {},
        onReset: {}
    )
}
