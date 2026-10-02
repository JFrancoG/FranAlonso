import SwiftUI

struct SaleStockWarningView: View {
    let serviceName: String
    let projectedQuantity: Int
    @Environment(\.locale) private var locale

    var body: some View {
        Label {
            Text(.salesStockWarning(projectedQuantity.formatted(.number.locale(locale))))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .font(.subheadline)
        .foregroundStyle(.errorInk)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.salesStockWarningFor(
            serviceName,
            projectedQuantity.formatted(.number.locale(locale))
        )))
    }
}

#Preview("Stock warning", traits: .modifier(SaleStockPreviewModifier())) {
    @Previewable @Environment(\.saleStockPreviewModel) var model
    if let model, let warning = model.stockWarnings.first,
       let line = model.sale?.lines.first(where: { $0.id == warning.id }) {
        Form {
            SaleStockWarningView(serviceName: line.serviceName, projectedQuantity: warning.projectedQuantity)
        }
    }
}
