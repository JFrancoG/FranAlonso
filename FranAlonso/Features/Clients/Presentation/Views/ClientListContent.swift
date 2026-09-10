import Foundation
import SwiftUI

struct ClientListContent: View {
    let state: ClientListViewModel.State
    let visibleClients: [Client]
    let hasNoSearchResults: Bool
    let onSelect: @MainActor (ClientID) -> Void
    let onRetry: @MainActor () -> Void

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
        case .content:
            if hasNoSearchResults {
                UnavailableStateView(
                    title: .clientsListSearchEmptyTitle,
                    systemImage: "magnifyingglass",
                    message: .clientsListSearchEmptyMessage
                )
            } else {
                List(visibleClients) { client in
                    ClientRow(client: client) {
                        onSelect(client.id)
                    }
                }
            }
        case .failed:
            UnavailableStateView(
                title: .clientsListErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: .clientsListErrorMessage
            ) {
                Button(action: onRetry) {
                    Text(.clientsListRetry)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .loading,
        visibleClients: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("0 clients", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .empty,
        visibleClients: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("1 client", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .content([AppPreviewFixtures.clientListLongName]),
        visibleClients: [AppPreviewFixtures.clientListLongName],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("80 clients", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .content(AppPreviewFixtures.clientListEighty),
        visibleClients: AppPreviewFixtures.clientListEighty,
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("No matches", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .content(AppPreviewFixtures.standard.clients),
        visibleClients: [],
        hasNoSearchResults: true,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("Error", traits: .modifier(AppPreviewModifier())) {
    ClientListContent(
        state: .failed,
        visibleClients: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}
