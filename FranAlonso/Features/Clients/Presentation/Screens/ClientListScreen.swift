import SwiftUI

@MainActor
struct ClientListScreen: View {
    @State private var viewModel: ClientListViewModel

    var body: some View {
        ClientListContent(state: viewModel.state)
            .navigationTitle(Text(.clientsListTitle))
            .task {
                await viewModel.load()
            }
    }
}

extension ClientListScreen {
    init(observeClients: ObserveClientsUseCase) {
        _viewModel = State(
            initialValue: ClientListViewModel(observeClients: observeClients)
        )
    }
}
