import SwiftUI

struct SaleDiscountContent: View {
    let viewModel: SaleDiscountViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            Section {
                if let serviceName = viewModel.serviceName {
                    Text(serviceName)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("sales.discount.field")
                    .font(.subheadline)
                TextField("sales.discount.field", text: $viewModel.discountText)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(minHeight: 44)
                    .disabled(!viewModel.canEdit)
                    .accessibilityHint(Text(viewModel.hasInputError ?
                        LocalizedStringResource("sales.discount.error.input") :
                        viewModel.instructions))
                Text(viewModel.instructions)
                    .font(.footnote)
                if viewModel.hasInputError {
                    Text("sales.discount.error.input")
                        .font(.headline)
                }
            }
            if viewModel.hasAcceptanceError {
                Section {
                    Text("sales.discount.error.title")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text("sales.discount.error.message")
                    Button(action: viewModel.retry) {
                        Text("sales.retry")
                            .frame(minHeight: 44)
                    }
                    .disabled(!viewModel.canEdit)
                }
            }
            if viewModel.isBusy {
                Section {
                    HStack {
                        ProgressView()
                            .accessibilityHidden(true)
                        Text("sales.discount.applying")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Section {
                Button(action: viewModel.requestApply) {
                    Text("sales.discount.apply")
                        .frame(minHeight: 44)
                }
                .disabled(!viewModel.canEdit)
                if viewModel.canRemove {
                    Button(role: .destructive, action: viewModel.requestRemoval) {
                        Text("sales.discount.remove")
                            .frame(minHeight: 44)
                    }
                }
            }
        }
    }
}

#Preview("Line discount", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.locale) var locale
    SaleDiscountContent(viewModel: lineDiscountPreview(locale: locale, invalid: false))
}

#Preview("Invalid percentage", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.locale) var locale
    SaleDiscountContent(viewModel: lineDiscountPreview(locale: locale, invalid: true))
}

#Preview("Invalid global percentage", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.locale) var locale
    let model = SaleDiscountViewModel(
        target: .global,
        discount: try? Discount(percentage: 20),
        locale: locale,
        canEdit: { true },
        apply: { _ in }
    )
    model.discountText = "101"
    model.requestApply()
    return SaleDiscountContent(viewModel: model)
}

@MainActor
private func lineDiscountPreview(locale: Locale, invalid: Bool) -> SaleDiscountViewModel {
    let model = SaleDiscountViewModel(
        target: .line(serviceName: "Tratamiento de hidratación intensiva y peinado para ocasión especial"),
        discount: try? Discount(percentage: 12.5),
        locale: locale,
        canEdit: { true },
        apply: { _ in }
    )
    if invalid {
        model.discountText = "101"
        model.requestApply()
    }
    return model
}
