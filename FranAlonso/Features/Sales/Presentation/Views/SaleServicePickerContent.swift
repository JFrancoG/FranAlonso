import SwiftUI

struct SaleServicePickerContent: View {
    let state: ServicePickerViewModel.State
    let visibleServices: [Service]
    let hasNoSearchResults: Bool
    @Binding var filter: FilterSelectableServicesUseCase.Filter
    let isBusy: Bool
    let canSelectServices: Bool
    let hasSelectionError: Bool
    let isSelectionUnavailable: Bool
    let onSelect: @MainActor (ServiceID) -> Void
    let onRetrySelection: @MainActor () -> Void
    let onReload: @MainActor () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            Menu {
                Picker("sales.services.filter", selection: $filter) {
                    Text("sales.services.filter.all").tag(FilterSelectableServicesUseCase.Filter.all)
                    Text(.servicesTypeProfessional).tag(FilterSelectableServicesUseCase.Filter.professional)
                    Text(.servicesTypeProduct).tag(FilterSelectableServicesUseCase.Filter.product)
                }
                .pickerStyle(.inline)
            } label: {
                filterLabel
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(.interaction, Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("sales.services.filter"))
            .accessibilityValue(Text(filterTitle))
            .disabled(isBusy)
            .padding(.horizontal)
            .padding(.vertical, 8)
            List {
                Section {
                    Text("sales.services.instruction")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if isBusy {
                    Section {
                        HStack {
                            ProgressView()
                                .accessibilityHidden(true)
                            Text("sales.services.adding")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                selectionError
                catalogue
            }
        }
    }

    private var filterTitle: LocalizedStringResource {
        switch filter {
        case .all: "sales.services.filter.all"
        case .professional: .servicesTypeProfessional
        case .product: .servicesTypeProduct
        }
    }

    @ViewBuilder
    private var filterLabel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text("sales.services.filter")
                    .fixedSize(horizontal: false, vertical: true)
                selectedFilterLabel
            }
        } else {
            HStack {
                Text("sales.services.filter")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                selectedFilterLabel
            }
        }
    }

    private var selectedFilterLabel: some View {
        HStack {
            Text(filterTitle)
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.up.chevron.down")
                .accessibilityHidden(true)
        }
        .foregroundStyle(.tint)
    }

    @ViewBuilder
    private var selectionError: some View {
        if hasSelectionError {
            Section {
                Text("sales.services.error.title")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("sales.services.error.message")
                Button(action: onRetrySelection) {
                    Text("sales.services.retry.add")
                        .frame(minHeight: 44)
                }
                .disabled(isBusy)
            }
        } else if isSelectionUnavailable {
            Section {
                Text("sales.services.unavailable.title")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("sales.services.unavailable.message")
                Button(action: onReload) {
                    Text("sales.services.reload")
                        .frame(minHeight: 44)
                }
                .disabled(isBusy)
            }
        }
    }

    @ViewBuilder
    private var catalogue: some View {
        switch state {
        case .idle, .loading:
            Section {
                ProgressView("sales.services.loading")
            }
        case .empty:
            Section {
                Text("sales.services.empty.title")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("sales.services.empty.message")
            }
        case .content:
            if hasNoSearchResults {
                Section {
                    Text(.servicesListSearchEmptyTitle)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(.servicesListSearchEmptyMessage)
                }
            } else {
                Section {
                    ForEach(visibleServices) { service in
                        SaleServicePickerRow(service: service) {
                            onSelect(service.id)
                        }
                        .disabled(!canSelectServices)
                    }
                } header: {
                    Text("sales.lines.title")
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        case .failed:
            Section {
                Text("sales.services.catalogue.error.title")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("sales.services.catalogue.error.message")
                Button(action: onReload) {
                    Text("sales.services.reload")
                        .frame(minHeight: 44)
                }
                .disabled(isBusy)
            }
        }
    }
}

#Preview("Selectable catalogue", traits: .modifier(SalesPreviewModifier())) {
    NavigationStack {
        SaleServicePickerContent(
            state: .content(ServicePreviewFixtures.standard.services),
            visibleServices: [
                ServicePreviewFixtures.standard.professionalService,
                ServicePreviewFixtures.standard.productService
            ],
            hasNoSearchResults: false,
            filter: .constant(.all),
            isBusy: false,
            canSelectServices: true,
            hasSelectionError: false,
            isSelectionUnavailable: false,
            onSelect: { _ in },
            onRetrySelection: {},
            onReload: {}
        )
        .navigationTitle(Text("sales.services.picker.title"))
    }
}

#Preview("Empty catalogue", traits: .modifier(SalesPreviewModifier())) {
    NavigationStack {
        SaleServicePickerContent(
            state: .empty,
            visibleServices: [],
            hasNoSearchResults: false,
            filter: .constant(.all),
            isBusy: false,
            canSelectServices: false,
            hasSelectionError: false,
            isSelectionUnavailable: false,
            onSelect: { _ in },
            onRetrySelection: {},
            onReload: {}
        )
        .navigationTitle(Text("sales.services.picker.title"))
    }
}

#Preview("Catalogue error", traits: .modifier(SalesPreviewModifier())) {
    NavigationStack {
        SaleServicePickerContent(
            state: .failed,
            visibleServices: [],
            hasNoSearchResults: false,
            filter: .constant(.all),
            isBusy: false,
            canSelectServices: false,
            hasSelectionError: false,
            isSelectionUnavailable: false,
            onSelect: { _ in },
            onRetrySelection: {},
            onReload: {}
        )
        .navigationTitle(Text("sales.services.picker.title"))
    }
}

#Preview("Addition error", traits: .modifier(SalesPreviewModifier())) {
    NavigationStack {
        SaleServicePickerContent(
            state: .content([ServicePreviewFixtures.standard.professionalService]),
            visibleServices: [ServicePreviewFixtures.standard.professionalService],
            hasNoSearchResults: false,
            filter: .constant(.professional),
            isBusy: false,
            canSelectServices: true,
            hasSelectionError: true,
            isSelectionUnavailable: false,
            onSelect: { _ in },
            onRetrySelection: {},
            onReload: {}
        )
        .navigationTitle(Text("sales.services.picker.title"))
    }
}

#Preview("No matches", traits: .modifier(SalesPreviewModifier())) {
    NavigationStack {
        SaleServicePickerContent(
            state: .content(ServicePreviewFixtures.standard.services),
            visibleServices: [],
            hasNoSearchResults: true,
            filter: .constant(.all),
            isBusy: false,
            canSelectServices: true,
            hasSelectionError: false,
            isSelectionUnavailable: false,
            onSelect: { _ in },
            onRetrySelection: {},
            onReload: {}
        )
        .navigationTitle(Text("sales.services.picker.title"))
    }
}
