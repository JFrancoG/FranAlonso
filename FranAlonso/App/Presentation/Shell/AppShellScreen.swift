import SwiftUI

struct AppShellScreen: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel = AppShellViewModel()
    let requestSignOut: @MainActor () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        TabView(selection: $viewModel.selectedSection) {
            Tab(.appShellTabWorkday, systemImage: "calendar", value: AppSection.workday) {
                NavigationStack {
                    WorkdayScreen(
                        makeViewModel: dependencies.makeWorkday,
                        makeSaleDraft: dependencies.makeSaleDraft,
                        makeServicePicker: dependencies.makeSaleServicePicker,
                        makeDiscount: dependencies.makeSaleDiscount,
                        makeBilling: dependencies.makeBilling
                    )
                        .toolbar {
                            signOutToolbar
                        }
                }
            }

            Tab(.appShellTabHistory, systemImage: "clock.arrow.circlepath", value: AppSection.history) {
                NavigationStack {
                    SalesHistoryScreen(
                        makeViewModel: dependencies.makeSalesHistory,
                        makeSaleDetail: dependencies.makeSaleDetail
                    )
                    .toolbar { signOutToolbar }
                }
            }

            Tab(.appShellTabClients, systemImage: "person.2", value: AppSection.clients) {
                NavigationStack {
                    ClientListScreen(
                        observeClients: dependencies.observeClients,
                        makeClientForm: dependencies.makeClientForm
                    )
                        .toolbar {
                            signOutToolbar
                        }
                }
            }

            Tab(.appShellTabCatalog, systemImage: "square.grid.2x2", value: AppSection.catalog) {
                CatalogScreen(requestSignOut: requestSignOut)
            }

            Tab(.appShellTabReports, systemImage: "chart.bar.xaxis", value: AppSection.reports) {
                unavailableSection(title: .appShellTabReports, systemImage: "chart.bar.xaxis")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    private func unavailableSection(title: LocalizedStringResource, systemImage: String) -> some View {
        NavigationStack {
            UnavailableStateView(title: title, systemImage: systemImage, message: .appShellUnavailableMessage)
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
