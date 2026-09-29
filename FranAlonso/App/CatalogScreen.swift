import SwiftUI

struct CatalogScreen: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel = CatalogViewModel()
    let requestSignOut: @MainActor () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.path) {
            List {
                NavigationLink(value: CatalogViewModel.Destination.services) {
                    entry(.catalogServicesTitle, message: .catalogServicesMessage, systemImage: "tag")
                }
                NavigationLink(value: CatalogViewModel.Destination.products) {
                    entry(.catalogProductsTitle, message: .catalogProductsMessage, systemImage: "shippingbox")
                }
            }
            .navigationTitle(Text(.appShellTabCatalog))
            .navigationDestination(for: CatalogViewModel.Destination.self) { destination in
                switch destination {
                case .services:
                    ServiceListScreen(
                        observeServices: dependencies.observeServices,
                        makeServiceForm: dependencies.makeServiceForm
                    )
                case .products:
                    ProductListScreen(
                        observeProducts: dependencies.observeProducts,
                        makeProductForm: dependencies.makeProductForm,
                        makeStockAdjustment: dependencies.makeStockAdjustment
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive, action: requestSignOut) {
                        Label {
                            Text(.authenticationRootSignOut)
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
        }
    }

    private func entry(
        _ title: LocalizedStringResource,
        message: LocalizedStringResource,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Catalogue", traits: .modifier(AppPreviewModifier())) {
    CatalogScreen(requestSignOut: {})
}
