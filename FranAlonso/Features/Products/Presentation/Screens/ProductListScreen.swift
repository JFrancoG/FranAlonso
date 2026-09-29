import Accessibility
import SwiftUI

struct ProductListScreen: View {
    let makeProductForm: @MainActor @Sendable (ProductFormDestination) -> ProductFormViewModel
    let makeStockAdjustment: @MainActor @Sendable (StockAdjustmentDestination) -> StockAdjustmentViewModel
    @Environment(\.locale) private var locale
    @AccessibilityFocusState(for: .voiceOver) private var addButtonIsFocused: Bool
    @State private var hasNotifiedFailureLayout = false
    @State private var observationRequestID = UUID()
    @State private var pendingFormCompletion: (
        destination: ProductFormDestination,
        completion: ProductFormScreen.Completion
    )?
    @State private var viewModel: ProductListViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ProductListContent(
            state: viewModel.state,
            visibleProducts: viewModel.visibleProducts,
            hasNoSearchResults: viewModel.hasNoSearchResults,
            onSelect: viewModel.beginEditingProduct
        ) {
            observationRequestID = UUID()
        }
        .navigationTitle(Text(.productsListTitle))
        .searchable(text: $viewModel.query, prompt: Text(.productsListSearchPrompt))
        .toolbar {
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.beginCreatingProduct) {
                    Label {
                        Text(.productsListAdd)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .accessibilityFocused($addButtonIsFocused)
            }
        }
        .accessibilityDefaultFocus($addButtonIsFocused, true)
        .sheet(item: formDestination, onDismiss: restoreFormFocus) { destination in
            ProductFormScreen(
                destination: destination,
                makeViewModel: makeProductForm,
                makeStockAdjustment: makeStockAdjustment
            ) { completion in
                finishForm(destination, completion: completion)
            }
            .id(destination.id)
        }
        .task(id: observationRequestID) {
            hasNotifiedFailureLayout = false
            await viewModel.load()
        }
        .onChange(of: viewModel.state) { _, newState in
            notifyFailureLayoutIfNeeded(newState)
        }
        .onChange(of: viewModel.hasNoSearchResults) { _, hasNoSearchResults in
            if hasNoSearchResults {
                announce(.productsListSearchEmptyTitle)
            }
        }
    }

    private var formDestination: Binding<ProductFormDestination?> {
        let sessionID = viewModel.formDestination?.id

        return Binding {
            viewModel.formDestination
        } set: { destination in
            guard destination == nil, let sessionID else { return }
            guard viewModel.formDestination?.id == sessionID else { return }
            viewModel.finishFormSession(sessionID)
        }
    }

    private func finishForm(_ destination: ProductFormDestination, completion: ProductFormScreen.Completion) {
        guard viewModel.formDestination?.id == destination.id else { return }
        pendingFormCompletion = (destination, completion)
        addButtonIsFocused = false
        viewModel.finishFormSession(destination.id)
    }

    private func restoreFormFocus() {
        guard let pendingFormCompletion else { return }
        self.pendingFormCompletion = nil
        guard viewModel.formDestination == nil else { return }
        if pendingFormCompletion.destination.mode == .create || pendingFormCompletion.completion == .deactivated {
            addButtonIsFocused = true
        }
        switch pendingFormCompletion.completion {
        case .cancelled:
            break
        case .saved:
            announceFormCompletion(.productsFormSaved)
        case .deactivated:
            announceFormCompletion(.productsFormDeactivated)
        }
    }

    private func announceFormCompletion(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        var announcement = AttributedString(String(localized: resource))
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func notifyFailureLayoutIfNeeded(_ state: ProductListViewModel.State) {
        guard case .failed = state, !hasNotifiedFailureLayout else { return }
        hasNotifiedFailureLayout = true
        AccessibilityNotification.LayoutChanged().post()
        announce(.productsListErrorMessage)
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension ProductListScreen {
    init(
        observeProducts: ObserveProductsUseCase,
        makeProductForm: @escaping @MainActor @Sendable (ProductFormDestination) -> ProductFormViewModel,
        makeStockAdjustment: @escaping @MainActor @Sendable (StockAdjustmentDestination) -> StockAdjustmentViewModel
    ) {
        self.makeProductForm = makeProductForm
        self.makeStockAdjustment = makeStockAdjustment
        _viewModel = State(initialValue: ProductListViewModel(observeProducts: observeProducts))
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    NavigationStack {
        ProductListScreen(
            observeProducts: dependencies.observeProducts,
            makeProductForm: dependencies.makeProductForm,
            makeStockAdjustment: dependencies.makeStockAdjustment
        )
    }
}
