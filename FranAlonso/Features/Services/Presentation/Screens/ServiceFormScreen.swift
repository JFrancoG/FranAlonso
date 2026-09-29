import Accessibility
import SwiftData
import SwiftUI

struct ServiceFormScreen: View {
    let destination: ServiceFormDestination
    let makeViewModel: @MainActor @Sendable (ServiceFormDestination, Locale) -> ServiceFormViewModel
    let onFinish: @MainActor (Completion) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: ServiceFormViewModel?
    @State private var request: Request?
    @State private var productObservationRequestID = UUID()
    @State private var showsDiscardChanges = false
    @State private var showsDeactivationConfirmation = false
    @State private var validationAttemptID: UUID?

    enum Completion {
        case cancelled, saved, deactivated
    }

    private struct Request: Equatable {
        let id: UUID
        let operation: ServiceFormViewModel.Operation
    }

    private struct ProductObservationRequest: Equatable {
        let sessionID: UUID?
        let retryID: UUID
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    LoadingStateView(label: .servicesFormLoading)
                }
            }
            .navigationTitle(Text(formTitle))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: requestCancellation) {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "xmark")
                                .frame(minWidth: 44, minHeight: 44)
                        } else {
                            Text(.servicesFormCancel)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.servicesFormCancel)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.servicesFormCancel)
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
                            Text(.servicesFormSave)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.servicesFormSave)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.servicesFormSave)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(viewModel?.canEdit != true || request != nil)
                }
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text(.servicesFormDiscardTitle),
            isPresented: $showsDiscardChanges,
            titleVisibility: .visible
        ) {
            Button(role: .destructive, action: cancelForm) {
                Text(.servicesFormDiscardConfirm)
            }
            Button {
                showsDiscardChanges = false
            } label: {
                Text(.servicesFormDiscardKeepEditing)
            }
        } message: {
            Text(.servicesFormDiscardMessage)
        }
        .confirmationDialog(
            Text(.servicesFormDeactivateTitle),
            isPresented: $showsDeactivationConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                requestOperation(.deactivate)
            } label: {
                Text(.servicesFormDeactivate)
            }
            Button {
                showsDeactivationConfirmation = false
            } label: {
                Text(.servicesFormDiscardKeepEditing)
            }
        } message: {
            Text(.servicesFormDeactivateMessage)
        }
        .task {
            guard !Task.isCancelled else { return }
            if viewModel == nil {
                viewModel = makeViewModel(destination, locale)
                AccessibilityNotification.ScreenChanged().post()
            }
            await viewModel?.load()
            guard !Task.isCancelled else { return }
            if let error = viewModel?.state.formError {
                announce(error.serviceFormMessage)
            }
        }
        .task(id: ProductObservationRequest(
            sessionID: viewModel?.destination.id,
            retryID: productObservationRequestID
        )) {
            await viewModel?.observeProducts()
        }
        .onChange(of: viewModel?.linkableProductsState) { _, state in
            guard state == .failed, viewModel?.draft.type == .product else { return }
            announce(.servicesFormProductsError)
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
                announce(error.serviceFormMessage)
            default:
                break
            }
        }
        .onDisappear {
            viewModel?.close()
        }
    }

    private var formTitle: LocalizedStringResource {
        if dynamicTypeSize.isAccessibilitySize {
            return destination.mode == .create ? .servicesFormCreateTitleCompact : .servicesFormEditTitleCompact
        }
        return destination.mode == .create ? .servicesFormCreateTitle : .servicesFormEditTitle
    }

    private func formContent(_ viewModel: ServiceFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return ServiceFormContent(
            draft: $viewModel.draft,
            state: viewModel.state,
            mode: destination.mode,
            isInactive: viewModel.loadedService?.status == .inactive,
            canEdit: viewModel.canEdit,
            canDeactivate: viewModel.canDeactivate,
            isRequestPending: request != nil,
            validationAttemptID: validationAttemptID,
            linkableProductsState: viewModel.linkableProductsState,
            onChangeType: viewModel.changeType,
            onSelectProduct: viewModel.selectLinkedProduct,
            onRetryProducts: {
                productObservationRequestID = UUID()
            },
            onRetry: {
                requestOperation(.load)
            },
            onDeactivate: {
                showsDeactivationConfirmation = true
            }
        )
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
        viewModel?.close()
        onFinish(.cancelled)
    }

    private func requestOperation(_ operation: ServiceFormViewModel.Operation) {
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

    ServiceFormScreen(
        destination: ServiceFormDestination(
            id: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 1)),
            serviceID: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 4))),
            mode: .create
        ),
        makeViewModel: dependencies.makeServiceForm
    ) { _ in }
}

#Preview("Edit inactive", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    ServiceFormScreen(
        destination: ServiceFormDestination(
            id: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 2)),
            serviceID: ServicePreviewFixtures.standard.inactiveService.id,
            mode: .edit
        ),
        makeViewModel: dependencies.makeServiceForm
    ) { _ in }
}

#Preview("Edit product", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    ServiceFormScreen(
        destination: ServiceFormDestination(
            id: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 3)),
            serviceID: ServicePreviewFixtures.standard.productService.id,
            mode: .edit
        ),
        makeViewModel: dependencies.makeServiceForm
    ) { _ in }
}
