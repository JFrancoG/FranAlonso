import SwiftUI

struct SaleDraftLineRow: View {
    let line: SaleLine
    let isReadOnly: Bool
    let stockWarning: StockImpact?
    let onIncrease: (@MainActor () -> Void)?
    let onDecrease: (@MainActor () -> Void)?
    let onRemove: @MainActor () -> Void
    let onEditDiscount: @MainActor () -> Void
    let discountIsFocused: AccessibilityFocusState<SaleLineID?>.Binding
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
                if let discount = line.discount {
                    Text(.salesDiscountValue(discount.percentage.formatted(
                        .number.locale(locale).grouping(.never).precision(.significantDigits(1...38))
                    )))
                } else {
                    Text("sales.discount.none")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)

            if let stockWarning {
                SaleStockWarningView(serviceName: line.serviceName, projectedQuantity: stockWarning.projectedQuantity)
            }

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

                Button(action: onEditDiscount) {
                    Text("sales.discount.edit")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text(.salesDiscountEdit(line.serviceName)))
                .accessibilityFocused(discountIsFocused, equals: line.id)

                Button(role: .destructive, action: onRemove) {
                    Text("sales.line.remove")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text(.salesLineRemove(line.serviceName)))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Editable line", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    Form {
        SaleDraftLineRow(
            line: SalesPreviewFixtures.workday.sales[2].lines[0],
            isReadOnly: false,
            stockWarning: nil,
            onIncrease: {},
            onDecrease: nil,
            onRemove: {},
            onEditDiscount: {},
            discountIsFocused: $discountIsFocused
        )
    }
}

#Preview("Stock warning line", traits: .modifier(SaleStockPreviewModifier())) {
    @Previewable @Environment(\.saleStockPreviewModel) var model
    @Previewable @AccessibilityFocusState var discountIsFocused: SaleLineID?
    if let model, let warning = model.stockWarnings.first,
       let line = model.sale?.lines.first(where: { $0.id == warning.id }) {
        Form {
            SaleDraftLineRow(
                line: line,
                isReadOnly: false,
                stockWarning: warning,
                onIncrease: {},
                onDecrease: {},
                onRemove: {},
                onEditDiscount: {},
                discountIsFocused: $discountIsFocused
            )
        }
    }
}
