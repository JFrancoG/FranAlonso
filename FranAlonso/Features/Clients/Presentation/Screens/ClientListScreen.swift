import Accessibility
import SwiftUI

@MainActor
struct ClientListScreen: View {
    @State private var hasNotifiedFailureLayout = false
    @State private var viewModel: ClientListViewModel

    var body: some View {
        ClientListContent(state: viewModel.state)
            .navigationTitle(Text(.clientsListTitle))
            .task {
                await viewModel.load()
            }
            .onChange(of: viewModel.state) { _, newState in
                notifyFailureLayoutIfNeeded(newState)
            }
    }

    private func notifyFailureLayoutIfNeeded(_ state: ClientListViewModel.State) {
        guard case .failed = state, !hasNotifiedFailureLayout else { return }
        hasNotifiedFailureLayout = true
        AccessibilityNotification.LayoutChanged().post()
    }
}

extension ClientListScreen {
    init(observeClients: ObserveClientsUseCase) {
        _viewModel = State(
            initialValue: ClientListViewModel(observeClients: observeClients)
        )
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        ClientListScreen(
            observeClients: AppDependencies.preview(
                clients: AppPreviewFixtures.standard.clients
            ).observeClients
        )
    }
}
