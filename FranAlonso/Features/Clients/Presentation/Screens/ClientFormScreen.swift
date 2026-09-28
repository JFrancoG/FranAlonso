import Accessibility
import SwiftData
import SwiftUI

struct ClientFormScreen: View {
    let destination: ClientFormDestination
    let makeViewModel: @MainActor @Sendable (ClientFormDestination) -> ClientFormViewModel
    let onFinish: @MainActor (Completion) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: ClientFormViewModel?
    @State private var request: Request?
    @State private var consentRequest: ConsentRequest?
    @State private var showsDeactivationConfirmation = false
    @State private var showsDiscardChanges = false
    @State private var validationAttemptID: UUID?
    @State private var consentOrigin: ClientFormContent.ConsentControl?
    @State private var consentFocusReturn: ClientFormContent.ConsentFocusReturn?

    enum Completion {
        case cancelled
        case saved
        case deactivated
    }

    private struct Request: Equatable {
        let id: UUID
        let operation: ClientFormViewModel.Operation
    }

    private struct ConsentRequest: Equatable {
        let id: UUID
        let action: ClientFormViewModel.ConsentAction
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    LoadingStateView(label: .clientsFormLoading)
                }
            }
            .navigationTitle(Text(destination.mode == .create ? .clientsFormCreateTitle : .clientsFormEditTitle))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: requestCancellation) {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "xmark")
                                .frame(minWidth: 44, minHeight: 44)
                        } else {
                            Text(.clientsFormCancel)
                        }
                    }
                    .accessibilityLabel(.clientsFormCancel)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.clientsFormCancel)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                    .disabled(
                        request?.operation == .save || request?.operation == .deactivate
                            || viewModel?.state.progressMessage != nil
                    )
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        requestOperation(.save)
                    } label: {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "checkmark")
                                .frame(minWidth: 44, minHeight: 44)
                        } else {
                            Text(.clientsFormSave)
                        }
                    }
                    .accessibilityLabel(.clientsFormSave)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.clientsFormSave)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(viewModel?.canEdit != true || request != nil || consentRequest != nil)
                }
            }
        }
        .interactiveDismissDisabled()
        .sheet(isPresented: $showsDeactivationConfirmation) {
            ClientDeactivationConfirmationView {
                requestOperation(.deactivate)
            }
        }
        .sheet(isPresented: consentPresentation, onDismiss: restoreConsentFocus) {
            if let viewModel {
                ClientConsentScreen(viewModel: viewModel)
            }
        }
        .confirmationDialog(
            Text(.clientsConsentUnsavedTitle),
            isPresented: $showsDiscardChanges,
            titleVisibility: .visible
        ) {
            Button(role: .destructive, action: cancelForm) {
                Text(.clientsConsentUnsavedDiscard)
            }
            Button(role: .cancel) {} label: {
                Text(.clientsFormCancel)
            }
        } message: {
            Text(.clientsConsentUnsavedMessage)
        }
        .task {
            guard !Task.isCancelled else { return }
            if viewModel == nil {
                viewModel = makeViewModel(destination)
                AccessibilityNotification.ScreenChanged().post()
            }
            await viewModel?.load()
            guard !Task.isCancelled else { return }
            if let error = viewModel?.state.formError {
                announce(error.clientFormMessage)
            }
        }
        .task(id: request) {
            guard let request, let viewModel else { return }
            switch request.operation {
            case .load:
                await viewModel.load()
            case .save:
                await viewModel.save(in: modelContext)
            case .deactivate:
                await viewModel.deactivate(in: modelContext)
            }
            guard self.request?.id == request.id else { return }
            self.request = nil
            switch viewModel.state {
            case .saved:
                onFinish(.saved)
            case .deactivated:
                onFinish(.deactivated)
            case .failed(_, let error):
                validationAttemptID = request.id
                announce(error.clientFormMessage)
            default:
                break
            }
        }
        .task(id: consentRequest) {
            guard let consentRequest, let viewModel else { return }
            await viewModel.performConsent(consentRequest.action)
            guard self.consentRequest?.id == consentRequest.id, !Task.isCancelled else { return }
            self.consentRequest = nil
            guard viewModel.consentStore?.isPresented != true else { return }
            if let error = viewModel.state.formError {
                validationAttemptID = consentRequest.id
                announce(error.clientFormMessage)
            } else if let failure = viewModel.consentStore?.failure {
                announce(failure.consentMessage)
            }
        }
        .onDisappear {
            viewModel?.close()
        }
    }

    private func formContent(_ viewModel: ClientFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return ClientFormContent(
            fields: $viewModel.fields,
            state: viewModel.state,
            mode: destination.mode,
            canEdit: viewModel.canEdit,
            isRequestPending: request != nil || consentRequest != nil,
            validationAttemptID: validationAttemptID,
            consentAvailable: viewModel.consentStore != nil,
            consentUnavailable: viewModel.consentUnavailable,
            canReviewConsent: viewModel.canReviewConsent,
            hasConsentWork: viewModel.hasConsentWork,
            consentFocusReturn: consentFocusReturn,
            onRetry: {
                requestOperation(.load)
            },
            onDeactivate: {
                showsDeactivationConfirmation = true
            },
            onInformation: {
                requestConsent(.information)
            },
            onReviewConsent: {
                requestConsent(.review)
            },
            onResumeConsent: {
                requestConsent(.recover)
            }
        )
    }

    private var consentPresentation: Binding<Bool> {
        Binding {
            viewModel?.consentStore?.isPresented == true
        } set: { isPresented in
            guard !isPresented else { return }
            consentRequest = nil
            viewModel?.dismissConsentPresentation()
        }
    }

    private func requestConsent(_ action: ClientFormViewModel.ConsentAction) {
        guard request == nil, consentRequest == nil else { return }
        switch action {
        case .information:
            consentOrigin = .information
        case .review:
            consentOrigin = .review
        case .recover:
            consentOrigin = .recovery
        default:
            break
        }
        consentRequest = ConsentRequest(id: UUID(), action: action)
    }

    private func restoreConsentFocus() {
        guard let consentOrigin, viewModel?.state != .closed else { return }
        consentFocusReturn = .init(id: UUID(), control: consentOrigin)
    }

    private func requestCancellation() {
        if viewModel?.hasUnsavedChanges == true {
            showsDiscardChanges = true
        } else {
            cancelForm()
        }
    }

    private func cancelForm() {
        request = nil
        consentRequest = nil
        viewModel?.close()
        onFinish(.cancelled)
    }

    private func requestOperation(_ operation: ClientFormViewModel.Operation) {
        guard request == nil else { return }
        request = Request(id: UUID(), operation: operation)
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

#Preview("Create", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    ClientFormScreen(
        destination: ClientFormPreviewFixtures.standard.creating,
        makeViewModel: dependencies.makeClientForm
    ) { _ in }
}

#Preview("Edit", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    ClientFormScreen(
        destination: ClientFormPreviewFixtures.standard.editing,
        makeViewModel: dependencies.makeClientForm
    ) { _ in }
}
