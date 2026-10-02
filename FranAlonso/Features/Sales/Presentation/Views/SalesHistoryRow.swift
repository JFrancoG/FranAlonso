import SwiftUI

struct SalesHistoryRow: View {
    let sale: Sale
    let clientName: String?
    let onSelect: @MainActor () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                if let clientName {
                    Text(clientName).font(.headline)
                } else {
                    Text(sale.clientID == nil ? LocalizedStringResource("sales.client.none") :
                        LocalizedStringResource("sales.client.unavailable"))
                        .font(.headline)
                }
                Label {
                    Text(sale.status.localizedTitle)
                } icon: {
                    Image(systemName: sale.status.historySymbol)
                }
                .font(.subheadline)
                Text(sale.lines.first?.serviceName ?? "").font(.body)
                Text(.salesLinesCount(sale.lines.count)).font(.caption)
                if let date = sale.status.historyClosureDate {
                    Text(date, format: .dateTime.day().month().year().hour().minute()).font(.caption)
                }
            }
            .foregroundStyle(.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("sales.history.openHint"))
    }
}

#Preview("Voided", traits: .modifier(SalesHistoryPreviewModifier())) {
    List {
        SalesHistoryRow(sale: SalesPreviewFixtures.history.sales[1], clientName: "Bruno DEMO", onSelect: {})
    }
}
