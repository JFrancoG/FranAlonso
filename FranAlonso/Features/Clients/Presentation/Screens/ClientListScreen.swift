import SwiftUI

@MainActor
struct ClientListScreen: View {
    @State private var viewModel: ClientListViewModel

    init(observeClients: ObserveClientsUseCase) {
        _viewModel = State(
            initialValue: ClientListViewModel(observeClients: observeClients)
        )
    }

    var body: some View {
        ClientListContent(state: viewModel.state)
            .navigationTitle(Text(.clientsListTitle))
            .task {
                await viewModel.load()
            }
    }
}
