import Accessibility
import SwiftData
import SwiftUI

struct ProductFormScreen: View {
    let destination: ProductFormDestination
    let makeViewModel: @MainActor @Sendable (ProductFormDestination) -> ProductFormViewModel
    let onFinish: @MainActor (Completion) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: ProductFormViewModel?
    @State private var request: Request?
    @State private var showsDiscardChanges = false
    @State private var showsDeactivationConfirmation = false
    @State private var validationAttemptID: UUID?

    enum Completion {
        case cancelled, saved, deactivated
    }

    private struct Request: Equatable {
        let id: UUID
        let operation: ProductFormViewModel.Operation
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    LoadingStateView(label: .productsFormLoading)
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
                            Text(.productsFormCancel)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.productsFormCancel)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.productsFormCancel)
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
                            Text(.productsFormSave)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.productsFormSave)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.productsFormSave)
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
            Text(.productsFormDiscardTitle),
            isPresented: $showsDiscardChanges,
            titleVisibility: .visible
        ) {
            Button(role: .destructive, action: cancelForm) {
                Text(.productsFormDiscardConfirm)
            }
            Button {
                showsDiscardChanges = false
            } label: {
                Text(.productsFormDiscardKeepEditing)
            }
        } message: {
            Text(.productsFormDiscardMessage)
        }
        .confirmationDialog(
            Text(.productsFormDeactivateTitle),
            isPresented: $showsDeactivationConfirmation,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                requestOperation(.deactivate)
            } label: {
                Text(.productsFormDeactivate)
            }
            Button {
                showsDeactivationConfirmation = false
            } label: {
                Text(.productsFormDiscardKeepEditing)
            }
        } message: {
            Text(.productsFormDeactivateMessage)
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
                announce(error.productFormMessage)
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
                announce(error.productFormMessage)
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
            return destination.mode == .create ? .productsFormCreateTitleCompact : .productsFormEditTitleCompact
        }
        return destination.mode == .create ? .productsFormCreateTitle : .productsFormEditTitle
    }

    private func formContent(_ viewModel: ProductFormViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return ProductFormContent(
            name: $viewModel.name,
            state: viewModel.state,
            mode: destination.mode,
            isInactive: viewModel.loadedProduct?.status == .inactive,
            canEdit: viewModel.canEdit,
            canDeactivate: viewModel.canDeactivate,
            isRequestPending: request != nil,
            validationAttemptID: validationAttemptID,
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

    private func requestOperation(_ operation: ProductFormViewModel.Operation) {
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

    ProductFormScreen(
        destination: ProductFormDestination(
            id: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 1)),
            productID: ProductID(rawValue: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 3))),
            mode: .create
        ),
        makeViewModel: dependencies.makeProductForm
    ) { _ in }
}

#Preview("Edit inactive", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    ProductFormScreen(
        destination: ProductFormDestination(
            id: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 2)),
            productID: ProductPreviewFixtures.standard.secondaryProduct.id,
            mode: .edit
        ),
        makeViewModel: dependencies.makeProductForm
    ) { _ in }
}
