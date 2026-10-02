import SwiftUI

struct SaleDetailContent: View {
    let state: SaleDetailViewModel.State
    let clientName: String?
    let onRetry: @MainActor () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
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
        case .unavailable, .closed:
            UnavailableStateView(
                title: "sales.history.unavailable.title",
                systemImage: "doc.questionmark",
                message: "sales.history.unavailable.message"
            )
        case let .content(sale, calculation):
            Form {
                Section {
                    Label {
                        Text(sale.status.localizedTitle)
                    } icon: {
                        Image(systemName: sale.status.historySymbol)
                    }
                    if let clientName {
                        Text(clientName)
                    } else {
                        Text(sale.clientID == nil ? LocalizedStringResource("sales.client.none") :
                            LocalizedStringResource("sales.client.unavailable"))
                    }
                    if sale.status.isHistoricallyVoided {
                        Text("sales.history.voided.message")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Section {
                    ForEach(sale.lines) { line in
                        SaleHistoryLineRow(line: line)
                    }
                    if let discount = sale.globalDiscount?.discount {
                        Text("sales.discount.global.title")
                        Text(.salesDiscountValue(discount.percentage.formatted(
                            .number.locale(locale).grouping(.never).precision(.significantDigits(1...38))
                        )))
                    }
                } header: {
                    Text("sales.lines.title").accessibilityAddTraits(.isHeader).textCase(nil)
                }
                Section {
                    Text("sales.history.originalAmounts").fixedSize(horizontal: false, vertical: true)
                }
                SaleTotalsSection(calculation: calculation)
                SaleHistoryTraceSection(sale: sale)
            }
        }
    }
}

#Preview("Closed", traits: .modifier(SalesHistoryPreviewModifier())) {
    NavigationStack {
        SaleDetailContent(
            state: .content(
                SalesPreviewFixtures.history.sales[0],
                SalesPreviewFixtures.calculation(for: SalesPreviewFixtures.history.sales[0])
            ),
            clientName: "Alba DEMO",
            onRetry: {}
        )
        .navigationTitle(Text("sales.history.detail"))
    }
}

#Preview("Voided", traits: .modifier(SalesHistoryPreviewModifier())) {
    NavigationStack {
        SaleDetailContent(
            state: .content(
                SalesPreviewFixtures.history.sales[1],
                SalesPreviewFixtures.calculation(for: SalesPreviewFixtures.history.sales[1])
            ),
            clientName: "Bruno DEMO",
            onRetry: {}
        )
        .navigationTitle(Text("sales.history.detail"))
    }
}

#Preview("Unavailable", traits: .modifier(SalesHistoryPreviewModifier())) {
    SaleDetailContent(state: .unavailable, clientName: nil, onRetry: {})
}

#Preview("Error", traits: .modifier(SalesHistoryPreviewModifier())) {
    SaleDetailContent(state: .failed, clientName: nil, onRetry: {})
}

#Preview("Loading", traits: .modifier(SalesHistoryPreviewModifier())) {
    SaleDetailContent(state: .loading, clientName: nil, onRetry: {})
}
