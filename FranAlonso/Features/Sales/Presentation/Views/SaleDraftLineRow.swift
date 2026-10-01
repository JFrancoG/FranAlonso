import SwiftUI

struct SaleDraftLineRow: View {
    let line: SaleLine
    let isReadOnly: Bool
    let onIncrease: (@MainActor () -> Void)?
    let onDecrease: (@MainActor () -> Void)?
    let onRemove: @MainActor () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(line.serviceName)
                    .font(.headline)
                Text(line.status.localizedTitle)
                    .font(.subheadline)
                Text(line.unitPrice.amount, format: .currency(code: line.unitPrice.currency.rawValue).locale(locale))
                Text(.salesLineTax(line.taxRate.percentage.formatted(.number.locale(locale))))
                    .font(.caption)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)

            if isReadOnly {
                Text(.salesQuantity(line.quantity))
            } else {
                Stepper(onIncrement: onIncrease, onDecrement: onDecrease) {
                    Text(.salesQuantity(line.quantity))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 44)
                .accessibilityLabel(Text(.salesQuantityFor(line.serviceName)))
                .accessibilityValue(Text(line.quantity, format: .number))

                Button(role: .destructive, action: onRemove) {
                    Text("sales.line.remove")
                        .frame(minHeight: 44)
                }
                .accessibilityLabel(Text(.salesLineRemove(line.serviceName)))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Editable line", traits: .modifier(SalesPreviewModifier())) {
    Form {
        SaleDraftLineRow(
            line: SalesPreviewFixtures.workday.sales[2].lines[0],
            isReadOnly: false,
            onIncrease: {},
            onDecrease: nil,
            onRemove: {}
        )
    }
}
