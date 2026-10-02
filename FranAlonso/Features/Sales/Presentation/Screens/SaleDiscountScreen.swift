import Accessibility
import SwiftUI

struct SaleDiscountScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: SaleDiscountViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(viewModel.title))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("sales.close") {
                            dismiss()
                        }
                    }
                }
        }
        .task(id: viewModel.requestID) {
            guard viewModel.requestID != nil else { return }
            await viewModel.submit()
        }
        .onChange(of: viewModel.hasAcceptedChange) { _, accepted in
            if accepted {
                announce("sales.discount.accepted")
                dismiss()
            }
        }
        .onChange(of: viewModel.hasInputError) { _, failed in
            if failed {
                announce("sales.discount.error.input")
            }
        }
        .onChange(of: viewModel.hasAcceptanceError) { _, failed in
            if failed {
                announce("sales.discount.error.title")
            }
        }
        .onChange(of: viewModel.isUnavailable) { _, unavailable in
            if unavailable {
                announce("sales.discount.unavailable.title")
            }
        }
        .onDisappear {
            viewModel.close()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isUnavailable {
            UnavailableStateView(
                title: "sales.discount.unavailable.title",
                systemImage: "percent",
                message: "sales.discount.unavailable.message"
            )
        } else {
            SaleDiscountContent(viewModel: viewModel)
        }
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension SaleDiscountScreen {
    init(makeViewModel: @MainActor @Sendable () -> SaleDiscountViewModel) {
        _viewModel = State(initialValue: makeViewModel())
    }
}

#Preview("Discount editor", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.locale) var locale
    SaleDiscountScreen {
        SaleDiscountViewModel(
            target: .line(serviceName: "Tratamiento de hidratación intensiva y peinado para ocasión especial"),
            discount: try? Discount(percentage: 12.5),
            locale: locale,
            canEdit: { true },
            apply: { _ in }
        )
    }
}

#Preview("Global discount editor", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.locale) var locale
    SaleDiscountScreen {
        SaleDiscountViewModel(
            target: .global,
            discount: try? Discount(percentage: 20),
            locale: locale,
            canEdit: { true },
            apply: { _ in }
        )
    }
}
