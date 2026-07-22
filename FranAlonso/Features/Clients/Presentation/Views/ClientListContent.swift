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

#Preview("Loading") {
    ClientListContent(state: .loading)
}

#Preview("Empty") {
    ClientListContent(state: .empty)
}

#Preview("Content") {
    ClientListContent(
        state: .content([
            Client(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                displayName: "Ana Alonso"
            ),
            Client(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                displayName: "María de los Ángeles Fernández"
            )
        ])
    )
}

#Preview("Error") {
    ClientListContent(state: .failed)
}
