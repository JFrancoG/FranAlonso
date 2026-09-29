import SwiftUI

struct ProductRow: View {
    let product: Product
    let onSelect: @MainActor () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if product.status == .inactive {
                    Label {
                        Text(.productsStatusInactive)
                    } icon: {
                        Image(systemName: "pause.circle")
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
        .accessibilityHint(.productsListEditHint)
    }
}

#Preview("Inactive", traits: .modifier(AppPreviewModifier())) {
    List {
        ProductRow(product: ProductPreviewFixtures.standard.secondaryProduct, onSelect: {})
    }
}

#Preview("Long name", traits: .modifier(AppPreviewModifier())) {
    List {
        ProductRow(product: ProductPreviewFixtures.standard.primaryProduct, onSelect: {})
    }
}
