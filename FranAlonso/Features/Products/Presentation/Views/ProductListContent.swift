import Foundation
import SwiftUI

struct ProductListContent: View {
    let state: ProductListViewModel.State
    let visibleProducts: [Product]
    let hasNoSearchResults: Bool
    let onSelect: @MainActor (ProductID) -> Void
    let onRetry: @MainActor () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .productsListLoading)
        case .empty:
            UnavailableStateView(
                title: .productsListEmptyTitle,
                systemImage: "shippingbox",
                message: .productsListEmptyMessage
            )
        case .content:
            if hasNoSearchResults {
                UnavailableStateView(
                    title: .productsListSearchEmptyTitle,
                    systemImage: "magnifyingglass",
                    message: .productsListSearchEmptyMessage
                )
            } else {
                List(visibleProducts) { product in
                    ProductRow(product: product) {
                        onSelect(product.id)
                    }
                }
            }
        case .failed:
            UnavailableStateView(
                title: .productsListErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: .productsListErrorMessage
            ) {
                Button(action: onRetry) {
                    Text(.productsListRetry)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .loading,
        visibleProducts: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("0 products", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .empty,
        visibleProducts: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("1 product", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .content([ProductPreviewFixtures.standard.primaryProduct]),
        visibleProducts: [ProductPreviewFixtures.standard.primaryProduct],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("250 products", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .content(ProductPreviewFixtures.list250),
        visibleProducts: ProductPreviewFixtures.list250,
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("No matches", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .content(ProductPreviewFixtures.standard.products),
        visibleProducts: [],
        hasNoSearchResults: true,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("Error", traits: .modifier(AppPreviewModifier())) {
    ProductListContent(
        state: .failed,
        visibleProducts: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}
