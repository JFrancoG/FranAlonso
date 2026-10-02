import Accessibility
import SwiftUI

struct SaleDetailScreen: View {
    let onClose: @MainActor (UUID) -> Void
    @State private var viewModel: SaleDetailViewModel
    @State private var observationRequestID = UUID()
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            SaleDetailContent(state: viewModel.state, clientName: viewModel.clientName) {
                observationRequestID = UUID()
            }
            .navigationTitle(Text("sales.history.detail"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.close()
                        onClose(viewModel.destination.id)
                    } label: {
                        Text("sales.close").frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
            .task(id: observationRequestID) {
                await viewModel.load()
            }
            .task(id: viewModel.clientID) {
                await viewModel.resolveClientName()
            }
            .onChange(of: viewModel.state) { previous, state in
                if state == .failed || (previous != .unavailable && state == .unavailable) {
                    var message = LocalizedStringResource(
                        state == .failed ? "sales.history.error.title" : "sales.history.unavailable.title"
                    )
                    message.locale = locale
                    AccessibilityNotification.Announcement(String(localized: message)).post()
                }
            }
            .onDisappear {
                viewModel.close()
            }
        }
    }
}

extension SaleDetailScreen {
    init(
        destination: SaleDetailDestination,
        makeViewModel: @MainActor @Sendable (SaleDetailDestination) -> SaleDetailViewModel,
        onClose: @escaping @MainActor (UUID) -> Void
    ) {
        self.onClose = onClose
        _viewModel = State(initialValue: makeViewModel(destination))
    }
}

#Preview("Terminal detail", traits: .modifier(SalesHistoryPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDetailScreen(
        destination: SaleDetailDestination(
            id: UUID(uuid: (11, 9, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1)),
            saleID: SalesPreviewFixtures.history.sales[1].id
        ),
        makeViewModel: dependencies.makeSaleDetail,
        onClose: { _ in }
    )
}
