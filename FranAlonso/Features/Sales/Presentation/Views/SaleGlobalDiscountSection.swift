import SwiftUI

struct SaleGlobalDiscountSection: View {
    let discount: SaleGlobalDiscount?
    let isReadOnly: Bool
    let canEdit: Bool
    let onEdit: @MainActor () -> Void
    let isFocused: AccessibilityFocusState<Bool>.Binding
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            if let discount {
                Text(.salesDiscountValue(discount.discount.percentage.formatted(
                    .number.locale(locale).grouping(.never).precision(.significantDigits(1...38))
                )))
            } else {
                Text("sales.discount.global.none")
            }
            Text("sales.discount.global.scope")
                .font(.footnote)
            if !isReadOnly {
                Button(action: onEdit) {
                    Text("sales.discount.global.edit")
                        .frame(minHeight: 44)
                }
                .disabled(!canEdit)
                .accessibilityFocused(isFocused)
            }
        } header: {
            Text("sales.discount.global.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Global term", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @AccessibilityFocusState var isFocused: Bool
    Form {
        SaleGlobalDiscountSection(
            discount: SalesPreviewFixtures.workday.sales[2].globalDiscount,
            isReadOnly: false,
            canEdit: true,
            onEdit: {},
            isFocused: $isFocused
        )
    }
}
