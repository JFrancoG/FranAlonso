import SwiftUI

struct ServiceRow: View {
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
                if service.status == .inactive {
                    Label {
                        Text(.servicesStatusInactive)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "pause.circle")
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(.servicesListEditHint)
    }
}

#Preview("Inactive", traits: .modifier(AppPreviewModifier())) {
    List {
        ServiceRow(service: ServicePreviewFixtures.standard.inactiveService, onSelect: {})
    }
    .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Professional", traits: .modifier(AppPreviewModifier())) {
    List {
        ServiceRow(service: ServicePreviewFixtures.standard.professionalService, onSelect: {})
    }
    .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Product", traits: .modifier(AppPreviewModifier())) {
    List {
        ServiceRow(service: ServicePreviewFixtures.standard.productService, onSelect: {})
    }
    .environment(\.locale, Locale(identifier: "en"))
}
