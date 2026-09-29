import Accessibility
import SwiftUI

struct ServiceListScreen: View {
    let makeServiceForm: @MainActor @Sendable (ServiceFormDestination, Locale) -> ServiceFormViewModel
    @Environment(\.locale) private var locale
    @AccessibilityFocusState(for: .voiceOver) private var addButtonIsFocused: Bool
    @State private var hasNotifiedFailureLayout = false
    @State private var observationRequestID = UUID()
    @State private var pendingFormCompletion: (
        destination: ServiceFormDestination,
        completion: ServiceFormScreen.Completion
    )?
    @State private var viewModel: ServiceListViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ServiceListContent(
            state: viewModel.state,
            visibleServices: viewModel.visibleServices,
            hasNoSearchResults: viewModel.hasNoSearchResults,
            onSelect: viewModel.beginEditingService
        ) {
            observationRequestID = UUID()
        }
        .navigationTitle(Text(.servicesListTitle))
        .searchable(text: $viewModel.query, prompt: Text(.servicesListSearchPrompt))
        .toolbar {
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.beginCreatingService) {
                    Label {
                        Text(.servicesListAdd)
                    } icon: {
                        Image(systemName: "plus")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityFocused($addButtonIsFocused)
            }
        }
        .accessibilityDefaultFocus($addButtonIsFocused, true)
        .sheet(item: formDestination, onDismiss: restoreFormFocus) { destination in
            ServiceFormScreen(
                destination: destination,
                makeViewModel: makeServiceForm
            ) { completion in
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
                announce(.servicesListSearchEmptyTitle)
            }
        }
    }

    private var formDestination: Binding<ServiceFormDestination?> {
        let sessionID = viewModel.formDestination?.id

        return Binding {
            viewModel.formDestination
        } set: { destination in
            guard destination == nil, let sessionID else { return }
            guard viewModel.formDestination?.id == sessionID else { return }
            viewModel.finishFormSession(sessionID)
        }
    }

    private func finishForm(_ destination: ServiceFormDestination, completion: ServiceFormScreen.Completion) {
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
            announceFormCompletion(.servicesFormSaved)
        case .deactivated:
            announceFormCompletion(.servicesFormDeactivated)
        }
    }

    private func announceFormCompletion(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        var announcement = AttributedString(String(localized: resource))
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func notifyFailureLayoutIfNeeded(_ state: ServiceListViewModel.State) {
        guard case .failed = state, !hasNotifiedFailureLayout else { return }
        hasNotifiedFailureLayout = true
        AccessibilityNotification.LayoutChanged().post()
        announce(.servicesListErrorMessage)
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension ServiceListScreen {
    init(
        observeServices: ObserveServicesUseCase,
        makeServiceForm: @escaping @MainActor @Sendable (ServiceFormDestination, Locale) -> ServiceFormViewModel
    ) {
        self.makeServiceForm = makeServiceForm
        _viewModel = State(initialValue: ServiceListViewModel(observeServices: observeServices))
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    NavigationStack {
        ServiceListScreen(observeServices: dependencies.observeServices, makeServiceForm: dependencies.makeServiceForm)
    }
}
