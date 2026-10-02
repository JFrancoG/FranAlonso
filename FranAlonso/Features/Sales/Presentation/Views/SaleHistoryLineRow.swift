import SwiftUI

struct SaleHistoryLineRow: View {
    let line: SaleLine
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(line.serviceName).font(.headline)
            Text(.salesQuantity(line.quantity))
            Text(line.unitPrice.amount, format: .currency(code: line.unitPrice.currency.rawValue).locale(locale))
            Text(.salesLineTax(line.taxRate.percentage.formatted(.number.locale(locale))))
            if let discount = line.discount {
                Text(.salesDiscountValue(discount.percentage.formatted(
                    .number.locale(locale).grouping(.never).precision(.significantDigits(1...38))
                )))
            } else {
                Text("sales.discount.none")
            }
        }
        .foregroundStyle(.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .padding(.vertical, 4)
    }
}

#Preview("Captured service", traits: .modifier(SalesHistoryPreviewModifier())) {
    Form {
        SaleHistoryLineRow(line: SalesPreviewFixtures.history.sales[1].lines[0])
    }
}
