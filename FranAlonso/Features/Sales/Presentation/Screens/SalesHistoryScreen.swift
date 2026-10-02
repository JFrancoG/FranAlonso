import Accessibility
import SwiftUI

struct SalesHistoryScreen: View {
    let makeSaleDetail: @MainActor @Sendable (SaleDetailDestination) -> SaleDetailViewModel
    @Environment(\.locale) private var locale
    @State private var viewModel: SalesHistoryViewModel
    @State private var observationRequestID = UUID()
    @State private var returnSaleID: SaleID?
    @AccessibilityFocusState private var focusedSale: SaleID?
    @AccessibilityFocusState private var filterIsFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        SalesHistoryContent(
            state: viewModel.state,
            sales: viewModel.visibleSales,
            clientNames: viewModel.clientDisplayNames,
            filter: $viewModel.filter,
            order: $viewModel.order,
            focusedSale: $focusedSale,
            filterIsFocused: $filterIsFocused,
            onSelect: openSale,
            onRetry: { observationRequestID = UUID() },
            onReset: viewModel.resetFilters
        )
        .navigationTitle(Text("sales.history.title"))
        .searchable(text: $viewModel.query, prompt: Text("sales.history.search"))
        .sheet(item: destination, onDismiss: restoreFocus) { destination in
            SaleDetailScreen(destination: destination, makeViewModel: makeSaleDetail, onClose: viewModel.finishSession)
            .id(destination.id)
        }
        .task(id: observationRequestID) {
            await viewModel.load()
        }
        .task(id: viewModel.clientIDs) {
            await viewModel.resolveClientNames()
        }
        .onChange(of: viewModel.state) { _, state in
            if state == .failed {
                var message = LocalizedStringResource("sales.history.error.title")
                message.locale = locale
                AccessibilityNotification.Announcement(String(localized: message)).post()
            }
        }
    }

    private var destination: Binding<SaleDetailDestination?> {
        let sessionID = viewModel.destination?.id
        return Binding {
            viewModel.destination
        } set: { value in
            guard value == nil, let sessionID else { return }
            viewModel.finishSession(sessionID)
        }
    }

    private func openSale(_ id: SaleID) {
        returnSaleID = id
        focusedSale = nil
        filterIsFocused = false
        viewModel.openSale(id)
    }

    private func restoreFocus() {
        guard viewModel.destination == nil else { return }
        focusedSale = viewModel.restorableSaleID(returnSaleID)
        filterIsFocused = focusedSale == nil
        returnSaleID = nil
    }
}

extension SalesHistoryScreen {
    init(
        makeViewModel: @MainActor @Sendable () -> SalesHistoryViewModel,
        makeSaleDetail: @escaping @MainActor @Sendable (SaleDetailDestination) -> SaleDetailViewModel
    ) {
        self.makeSaleDetail = makeSaleDetail
        _viewModel = State(initialValue: makeViewModel())
    }
}

#Preview("History", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    NavigationStack {
        SalesHistoryScreen(makeViewModel: dependencies.makeSalesHistory, makeSaleDetail: dependencies.makeSaleDetail)
    }
}
