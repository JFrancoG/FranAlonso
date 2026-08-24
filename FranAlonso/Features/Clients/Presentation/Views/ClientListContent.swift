import Foundation
import SwiftUI

@MainActor
struct ClientListContent: View {
    let state: ClientListViewModel.State

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .clientsListLoading)
        case .empty:
            UnavailableStateView(
                title: .clientsListEmptyTitle,
                systemImage: "person.2",
                message: .clientsListEmptyMessage
            )
        case let .content(clients):
            List(clients) { client in
                ClientRow(client: client)
            }
        case .failed:
            UnavailableStateView(
                title: .clientsListErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: .clientsListErrorMessage
            )
        }
    }
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(state: .loading)
}

#Preview("Empty", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(state: .empty)
}

#Preview("Content", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .content(AppPreviewFixtures.standard.clients)
    )
}

#Preview("Error", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(state: .failed)
}
