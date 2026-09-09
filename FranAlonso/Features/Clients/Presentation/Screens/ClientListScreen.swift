import Accessibility
import SwiftUI

struct ClientListScreen: View {
    let makeClientForm: @MainActor @Sendable (ClientFormDestination) -> ClientFormViewModel
    @Environment(\.locale) private var locale
    @AccessibilityFocusState(for: .voiceOver) private var addButtonIsFocused: Bool
    @State private var hasNotifiedFailureLayout = false
    @State private var observationRequestID = UUID()
    @State private var pendingFormCompletion: (
        destination: ClientFormDestination,
        completion: ClientFormScreen.Completion
    )?
    @State private var viewModel: ClientListViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ClientListContent(
            state: viewModel.state,
            visibleClients: viewModel.visibleClients,
            hasNoSearchResults: viewModel.hasNoSearchResults,
            onSelect: viewModel.beginEditingClient
        ) {
            observationRequestID = UUID()
        }
        .navigationTitle(Text(.clientsListTitle))
        .searchable(text: $viewModel.query, prompt: Text(.clientsListSearchPrompt))
        .toolbar {
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.beginCreatingClient) {
                    Label {
                        Text(.clientsListAdd)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .accessibilityFocused($addButtonIsFocused)
            }
        }
        .accessibilityDefaultFocus($addButtonIsFocused, true)
        .sheet(item: formDestination, onDismiss: restoreFormFocus) { destination in
            ClientFormScreen(destination: destination, makeViewModel: makeClientForm) { completion in
                finishForm(destination, completion: completion)
            }
            .id(destination.id)
        }
        .task(id: observationRequestID) {
            hasNotifiedFailureLayout = false
            await viewModel.load()
        }
        .onChange(of: viewModel.state) { _, newState in
            notifyFailureLayoutIfNeeded(newState)
        }
        .onChange(of: viewModel.hasNoSearchResults) { _, hasNoSearchResults in
            if hasNoSearchResults {
                announce(.clientsListSearchEmptyTitle)
            }
        }
    }

    private var formDestination: Binding<ClientFormDestination?> {
        let sessionID = viewModel.formDestination?.id

        return Binding {
            viewModel.formDestination
        } set: { destination in
            guard destination == nil, let sessionID else { return }
            guard viewModel.formDestination?.id == sessionID else { return }
            viewModel.finishFormSession(sessionID)
        }
    }

    private func finishForm(_ destination: ClientFormDestination, completion: ClientFormScreen.Completion) {
        guard viewModel.formDestination?.id == destination.id else { return }
        pendingFormCompletion = (destination, completion)
        addButtonIsFocused = false
        viewModel.finishFormSession(destination.id)
    }

    private func restoreFormFocus() {
        guard let pendingFormCompletion else { return }
        self.pendingFormCompletion = nil
        guard viewModel.formDestination == nil else { return }
        if pendingFormCompletion.destination.mode == .create || pendingFormCompletion.completion == .deactivated {
            addButtonIsFocused = true
        }
        switch pendingFormCompletion.completion {
        case .cancelled:
            break
        case .saved:
            announceFormCompletion(.clientsFormSaved)
        case .deactivated:
            announceFormCompletion(.clientsFormDeactivated)
        }
    }

    private func announceFormCompletion(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        var announcement = AttributedString(String(localized: resource))
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func notifyFailureLayoutIfNeeded(_ state: ClientListViewModel.State) {
        guard case .failed = state, !hasNotifiedFailureLayout else { return }
        hasNotifiedFailureLayout = true
        AccessibilityNotification.LayoutChanged().post()
        announce(.clientsListErrorMessage)
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension ClientListScreen {
    init(
        observeClients: ObserveClientsUseCase,
        makeClientForm: @escaping @MainActor @Sendable (ClientFormDestination) -> ClientFormViewModel
    ) {
        self.makeClientForm = makeClientForm
        _viewModel = State(initialValue: ClientListViewModel(observeClients: observeClients))
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    NavigationStack {
        ClientListScreen(observeClients: dependencies.observeClients, makeClientForm: dependencies.makeClientForm)
    }
}
