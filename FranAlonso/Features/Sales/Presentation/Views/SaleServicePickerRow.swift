import SwiftUI

struct SaleServicePickerRow: View {
    let service: Service
    let onSelect: @MainActor () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Text(service.name)
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(service.type == .professional ? .servicesTypeProfessional : .servicesTypeProduct)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(
                    service.price.amount,
                    format: Decimal.FormatStyle.Currency(code: service.price.currency.rawValue, locale: locale)
                )
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("sales.services.add.hint")
    }
}

#Preview("Professional", traits: .modifier(SalesPreviewModifier())) {
    List {
        SaleServicePickerRow(service: ServicePreviewFixtures.standard.professionalService, onSelect: {})
    }
}

#Preview("Product", traits: .modifier(SalesPreviewModifier())) {
    List {
        SaleServicePickerRow(service: ServicePreviewFixtures.standard.productService, onSelect: {})
    }
}
