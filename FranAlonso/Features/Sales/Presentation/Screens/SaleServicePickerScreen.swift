import Accessibility
import SwiftUI

struct SaleServicePickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: SaleServicePickerViewModel

    var body: some View {
        @Bindable var picker = viewModel.picker

        NavigationStack {
            SaleServicePickerContent(
                state: picker.state,
                visibleServices: picker.visibleServices,
                hasNoSearchResults: picker.hasNoSearchResults,
                filter: $picker.filter,
                isBusy: viewModel.isBusy,
                canSelectServices: viewModel.canSelectServices,
                hasSelectionError: viewModel.hasSelectionError,
                isSelectionUnavailable: viewModel.isSelectionUnavailable,
                onSelect: viewModel.requestSelection,
                onRetrySelection: viewModel.retrySelection,
                onReload: viewModel.reloadCatalogue
            )
            .navigationTitle(Text("sales.services.picker.title"))
            .searchable(text: $picker.query, prompt: Text("sales.services.search"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("sales.close") {
                        dismiss()
                    }
                }
            }
        }
        .task(id: viewModel.observationRequestID) {
            guard viewModel.observationRequestID != nil else { return }
            await viewModel.loadCatalogue()
        }
        .task(id: viewModel.selectionRequestID) {
            guard viewModel.selectionRequestID != nil else { return }
            await viewModel.submitSelection()
        }
        .onChange(of: viewModel.hasAcceptedSelection) { _, accepted in
            if accepted {
                announce("sales.services.added")
                dismiss()
            }
        }
        .onChange(of: viewModel.hasSelectionError) { _, failed in
            if failed {
                announce("sales.services.error.title")
            }
        }
        .onChange(of: viewModel.isSelectionUnavailable) { _, unavailable in
            if unavailable {
                announce("sales.services.unavailable.title")
            }
        }
        .onChange(of: viewModel.picker.state) { _, state in
            if state == .failed {
                announce("sales.services.catalogue.error.title")
            }
        }
        .onDisappear {
            viewModel.close()
        }
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension SaleServicePickerScreen {
    init(
        makeViewModel: @MainActor @Sendable () -> SaleServicePickerViewModel
    ) {
        _viewModel = State(initialValue: makeViewModel())
    }
}

#Preview("Service selector", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    @Previewable @Environment(\.salesPreviewModels) var models
    if let draft = models[SalesPreviewFixtures.workday.sales[2].id] {
        SaleServicePickerScreen {
            dependencies.makeSaleServicePicker(for: draft)
        }
    }
}
