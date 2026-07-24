import Foundation
import SwiftUI

@MainActor
struct ClientListContent: View {
    let state: ClientListViewModel.State

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView {
                Text(.clientsListLoading)
            }
        case .empty:
            ContentUnavailableView {
                Label {
                    Text(.clientsListEmptyTitle)
                } icon: {
                    Image(systemName: "person.2")
                }
            } description: {
                Text(.clientsListEmptyMessage)
            }
        case let .content(clients):
            List(clients) { client in
                ClientRow(client: client)
            }
        case .failed:
            ContentUnavailableView {
                Label {
                    Text(.clientsListErrorTitle)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } description: {
                Text(.clientsListErrorMessage)
            }
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
