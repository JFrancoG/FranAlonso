import SwiftUI

struct ServiceLinkedProductSection: View {
    let selection: ProductID?
    let state: ServiceFormViewModel.LinkableProductsState
    let error: ServiceFormError?
    let canEdit: Bool
    let validationAttemptID: UUID?
    let onSelect: @MainActor (ProductID?) -> Void
    let onRetry: @MainActor () -> Void
    @AccessibilityFocusState private var isPickerFocused: Bool

    var body: some View {
        Section {
            Picker(selection: Binding(get: { selection }, set: onSelect)) {
                Text(.servicesFormProductChoose)
                    .frame(minHeight: 44)
                    .tag(ProductID?.none)
                if let selection, !products.contains(where: { $0.id == selection }) {
                    Text(unlistedSelectionLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                        .tag(Optional(selection))
                }
                ForEach(products) { product in
                    Text(product.name)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                        .tag(Optional(product.id))
                }
            } label: {
                Text(.servicesFormLinkedProduct)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .pickerStyle(.navigationLink)
            .accessibilityLabel(.servicesFormLinkedProduct)
            .accessibilityHint(error?.serviceFormMessage ?? .servicesFormProductHint)
            .accessibilityFocused($isPickerFocused)
            .frame(minHeight: 44)
            .disabled(!canEdit || !hasSnapshot)
            statusFeedback
            if let error {
                Text(error.serviceFormMessage)
                    .foregroundStyle(.errorInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onChange(of: validationAttemptID) {
            guard error != nil else { return }
            isPickerFocused = true
        }
    }

    private var products: [Product] {
        guard case .loaded(let products) = state else { return [] }
        return products
    }

    private var hasSnapshot: Bool {
        if case .loaded = state { return true }
        return false
    }

    private var unlistedSelectionLabel: LocalizedStringResource {
        hasSnapshot ? .servicesFormProductUnavailable : .servicesFormProductUnknown
    }

    @ViewBuilder
    private var statusFeedback: some View {
        switch state {
        case .idle, .loading:
            ProgressView {
                Text(.servicesFormProductsLoading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .failed:
            Text(.servicesFormProductsError)
                .foregroundStyle(.errorInk)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onRetry) {
                Text(.servicesFormProductsRetry)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44)
            }
            .disabled(!canEdit)
        case .loaded(let products):
            if products.isEmpty {
                Text(.servicesFormProductsEmpty)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let selection, !products.contains(where: { $0.id == selection }), error == nil {
                Text(.servicesFormProductUnavailableHint)
                    .foregroundStyle(.errorInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Selected product ES", traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        Form {
            ServiceLinkedProductSection(
                selection: ProductPreviewFixtures.standard.primaryProduct.id,
                state: .loaded([ProductPreviewFixtures.standard.primaryProduct]),
                error: nil,
                canEdit: true,
                validationAttemptID: nil,
                onSelect: { _ in },
                onRetry: {}
            )
        }
    }
    .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Unavailable product ES", traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        Form {
            ServiceLinkedProductSection(
                selection: ProductPreviewFixtures.standard.primaryProduct.id,
                state: .loaded([]),
                error: .service(.linkedProductUnavailable),
                canEdit: true,
                validationAttemptID: nil,
                onSelect: { _ in },
                onRetry: {}
            )
        }
    }
    .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Read failure EN", traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        Form {
            ServiceLinkedProductSection(
                selection: ProductPreviewFixtures.standard.primaryProduct.id,
                state: .failed,
                error: nil,
                canEdit: true,
                validationAttemptID: nil,
                onSelect: { _ in },
                onRetry: {}
            )
        }
    }
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Empty catalogue EN", traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        Form {
            ServiceLinkedProductSection(
                selection: nil,
                state: .loaded([]),
                error: nil,
                canEdit: true,
                validationAttemptID: nil,
                onSelect: { _ in },
                onRetry: {}
            )
        }
    }
    .environment(\.locale, Locale(identifier: "en"))
}
