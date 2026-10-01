import SwiftUI

struct SaleTotalsSection: View {
    let calculation: SaleCalculation
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            amountRow("sales.totals.subtotal", value: calculation.subtotal)
            amountRow("sales.totals.discount", value: calculation.discountAmount)
            amountRow("sales.totals.base", value: calculation.taxableBase)
            amountRow("sales.totals.tax", value: calculation.taxAmount)
            amountRow("sales.totals.total", value: calculation.total)
                .font(.headline)
        } header: {
            Text("sales.totals.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func amountRow(_ title: LocalizedStringResource, value: Money) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(value.amount, format: .currency(code: value.currency.rawValue).locale(locale))
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Amounts", traits: .modifier(SalesPreviewModifier())) {
    Form {
        SaleTotalsSection(calculation: SalesPreviewFixtures.calculation(for: SalesPreviewFixtures.workday.sales[0]))
    }
}
