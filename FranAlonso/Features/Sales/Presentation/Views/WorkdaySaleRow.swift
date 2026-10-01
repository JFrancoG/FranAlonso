import SwiftUI

struct WorkdaySaleRow: View {
    let sale: Sale
    let clientName: String?
    let onSelect: @MainActor () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                if let clientName {
                    Text(clientName)
                        .font(.headline)
                } else {
                    Text(sale.clientID == nil ? LocalizedStringResource("sales.client.none") :
                        LocalizedStringResource("sales.client.unavailable"))
                        .font(.headline)
                }
                Text(sale.status.localizedTitle)
                    .font(.subheadline)
                if let line = sale.lines.first {
                    Text(line.serviceName)
                        .font(.body)
                } else {
                    Text("sales.lines.empty")
                }
                Text(.salesLinesCount(sale.lines.count))
                    .font(.caption)
                Text(sale.createdAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
            }
            .foregroundStyle(.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("sales.workday.openHint"))
    }
}

#Preview("Draft", traits: .modifier(SalesPreviewModifier())) {
    List {
        WorkdaySaleRow(sale: SalesPreviewFixtures.workday.sales[2], clientName: "Bruno DEMO", onSelect: {})
    }
}
