import Foundation
import SwiftUI

struct ServiceListContent: View {
    let state: ServiceListViewModel.State
    let visibleServices: [Service]
    let hasNoSearchResults: Bool
    let onSelect: @MainActor (ServiceID) -> Void
    let onRetry: @MainActor () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingStateView(label: .servicesListLoading)
        case .empty:
            UnavailableStateView(
                title: .servicesListEmptyTitle,
                systemImage: "list.bullet.rectangle",
                message: .servicesListEmptyMessage
            )
        case .content:
            if hasNoSearchResults {
                UnavailableStateView(
                    title: .servicesListSearchEmptyTitle,
                    systemImage: "magnifyingglass",
                    message: .servicesListSearchEmptyMessage
                )
            } else {
                List(visibleServices) { service in
                    ServiceRow(service: service) {
                        onSelect(service.id)
                    }
                }
            }
        case .failed:
            UnavailableStateView(
                title: .servicesListErrorTitle,
                systemImage: "exclamationmark.triangle",
                message: .servicesListErrorMessage
            ) {
                Button(action: onRetry) {
                    Text(.servicesListRetry)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .loading,
        visibleServices: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("0 services", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .empty,
        visibleServices: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("1 service", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .content([ServicePreviewFixtures.standard.professionalService]),
        visibleServices: [ServicePreviewFixtures.standard.professionalService],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("250 services", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .content(ServicePreviewFixtures.list250),
        visibleServices: ServicePreviewFixtures.list250,
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("No matches", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .content(ServicePreviewFixtures.standard.services),
        visibleServices: [],
        hasNoSearchResults: true,
        onSelect: { _ in },
        onRetry: {}
    )
}

#Preview("Error", traits: .modifier(AppPreviewModifier())) {
    ServiceListContent(
        state: .failed,
        visibleServices: [],
        hasNoSearchResults: false,
        onSelect: { _ in },
        onRetry: {}
    )
}
