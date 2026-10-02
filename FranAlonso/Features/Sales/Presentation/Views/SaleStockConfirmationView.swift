import SwiftUI

struct SaleStockConfirmationView: View {
    let confirmation: SaleStockConfirmation
    let onContinue: @MainActor () -> Void
    let onCancel: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(confirmation.stockUnavailable ? LocalizedStringResource("sales.stock.confirm.unknown") :
                        LocalizedStringResource("sales.stock.confirm.message"))
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(confirmation.warnings) { warning in
                        Text(warning.serviceName).font(.headline).fixedSize(horizontal: false, vertical: true)
                        SaleStockWarningView(
                            serviceName: warning.serviceName,
                            projectedQuantity: warning.projectedQuantity
                        )
                    }
                    Button(action: onContinue) {
                        Text("sales.stock.confirm.continue").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .primaryActionStyle()
                    Button(action: onCancel) {
                        Text("sales.stock.confirm.cancel").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle(Text("sales.stock.confirm.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Text("sales.stock.confirm.cancel").frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
        }
    }
}

#Preview("Stock confirmation", traits: .modifier(SaleStockPreviewModifier())) {
    @Previewable @Environment(\.saleStockPreviewModel) var model
    SaleStockConfirmationView(
        confirmation: SaleStockConfirmation(
            id: UUID(uuid: (12, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1)),
            warnings: model?.confirmationWarnings ?? [],
            stockUnavailable: false
        ),
        onContinue: {},
        onCancel: {}
    )
}

#Preview("Stock unavailable", traits: .modifier(AppPreviewModifier())) {
    SaleStockConfirmationView(
        confirmation: SaleStockConfirmation(
            id: UUID(uuid: (12, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 2)),
            warnings: [],
            stockUnavailable: true
        ),
        onContinue: {},
        onCancel: {}
    )
}
