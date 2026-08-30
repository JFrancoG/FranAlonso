import SwiftUI

@MainActor
struct AppShellScreen: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel = AppShellViewModel()
    let requestSignOut: @MainActor () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        TabView(selection: $viewModel.selectedSection) {
            Tab(
                .appShellTabWorkday,
                systemImage: "calendar",
                value: AppSection.workday
            ) {
                unavailableSection(
                    title: .appShellTabWorkday,
                    systemImage: "calendar"
                )
            }

            Tab(
                .appShellTabHistory,
                systemImage: "clock.arrow.circlepath",
                value: AppSection.history
            ) {
                unavailableSection(
                    title: .appShellTabHistory,
                    systemImage: "clock.arrow.circlepath"
                )
            }

            Tab(
                .appShellTabClients,
                systemImage: "person.2",
                value: AppSection.clients
            ) {
                NavigationStack {
                    ClientListScreen(observeClients: dependencies.observeClients)
                        .toolbar {
                            signOutToolbar
                        }
                }
            }

            Tab(
                .appShellTabCatalog,
                systemImage: "square.grid.2x2",
                value: AppSection.catalog
            ) {
                unavailableSection(
                    title: .appShellTabCatalog,
                    systemImage: "square.grid.2x2"
                )
            }

            Tab(
                .appShellTabReports,
                systemImage: "chart.bar.xaxis",
                value: AppSection.reports
            ) {
                unavailableSection(
                    title: .appShellTabReports,
                    systemImage: "chart.bar.xaxis"
                )
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    private func unavailableSection(
        title: LocalizedStringResource,
        systemImage: String
    ) -> some View {
        NavigationStack {
            UnavailableStateView(
                title: title,
                systemImage: systemImage,
                message: .appShellUnavailableMessage
            )
            .navigationTitle(Text(title))
            .toolbar {
                signOutToolbar
            }
        }
    }

    @ToolbarContentBuilder
    private var signOutToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(role: .destructive) {
                requestSignOut()
            } label: {
                Label {
                    Text(.authenticationRootSignOut)
                } icon: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }
}

#Preview("Workday", traits: .modifier(AppPreviewModifier())) {
    AppShellScreen(requestSignOut: {})
}

#Preview("RTL", traits: .modifier(AppPreviewModifier())) {
    AppShellScreen(requestSignOut: {})
        .environment(\.layoutDirection, .rightToLeft)
}
