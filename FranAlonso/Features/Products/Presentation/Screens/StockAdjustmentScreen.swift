import Accessibility
import SwiftData
import SwiftUI

struct StockAdjustmentScreen: View {
    let destination: StockAdjustmentDestination
    let makeViewModel: @MainActor @Sendable (StockAdjustmentDestination) -> StockAdjustmentViewModel
    let onFinish: @MainActor () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: StockAdjustmentViewModel?
    @State private var request: Request?
    @State private var showsDiscardChanges = false
    @State private var validationAttemptID: UUID?

    private enum Operation: Equatable {
        case load, save, refresh
    }

    private struct Request: Equatable {
        let id: UUID
        let operation: Operation
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    formContent(viewModel)
                } else {
                    LoadingStateView(label: .stockAdjustmentLoading)
                }
            }
            .navigationTitle(Text(formTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel?.isAccepted != true {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: requestCancellation) {
                            toolbarLabel(.stockAdjustmentCancel, systemImage: "xmark")
                        }
                        .accessibilityLabel(.stockAdjustmentCancel)
                        .accessibilityShowsLargeContentViewer {
                            Text(.stockAdjustmentCancel)
                        }
                        .disabled(viewModel?.canClose == false || request?.operation == .save)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel?.isAccepted == true {
                        Button(action: finish) {
                            toolbarLabel(.stockAdjustmentDone, systemImage: "checkmark")
                        }
                        .accessibilityLabel(.stockAdjustmentDone)
                        .accessibilityShowsLargeContentViewer {
                            Text(.stockAdjustmentDone)
                        }
                    } else {
                        Button {
                            requestOperation(.save)
                        } label: {
                            toolbarLabel(saveLabel, systemImage: "checkmark")
                        }
                        .accessibilityLabel(Text(saveLabel))
                        .accessibilityShowsLargeContentViewer {
                            Text(saveLabel)
                        }
                        .disabled(viewModel?.canSubmit != true || request != nil)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text(.stockAdjustmentDiscardTitle),
            isPresented: $showsDiscardChanges,
            titleVisibility: .visible
        ) {
            Button(role: .destructive, action: finish) {
                Text(.stockAdjustmentDiscard)
            }
            Button {
                showsDiscardChanges = false
            } label: {
                Text(.stockAdjustmentKeepEditing)
            }
        } message: {
            Text(.stockAdjustmentDiscardMessage)
        }
        .task {
            guard !Task.isCancelled else { return }
            if viewModel == nil {
                viewModel = makeViewModel(destination)
                AccessibilityNotification.ScreenChanged().post()
            }
            await viewModel?.load()
            guard !Task.isCancelled else { return }
            if let error = viewModel?.state.stockError {
                announce(error.stockAdjustmentMessage)
            }
        }
        .task(id: request) {
            guard let request, let viewModel else { return }
            switch request.operation {
            case .load:
                await viewModel.load()
            case .save:
                await viewModel.save(in: modelContext)
            case .refresh:
                await viewModel.refreshQuantity()
            }
            guard self.request?.id == request.id else { return }
            self.request = nil
            if let error = viewModel.state.stockError {
                validationAttemptID = request.id
                announce(error.stockAdjustmentMessage)
            }
        }
        .onChange(of: viewModel?.isAccepted) { _, accepted in
            if accepted == true {
                announce(.stockAdjustmentSaved)
            }
        }
        .onChange(of: viewModel?.balanceState) { _, balance in
            if case .failed = balance {
                announce(.stockAdjustmentRefreshError)
            }
        }
        .onDisappear {
            viewModel?.close()
        }
    }

    private var formTitle: LocalizedStringResource {
        dynamicTypeSize.isAccessibilitySize ? .stockAdjustmentTitleCompact : .stockAdjustmentOpen
    }

    private var saveLabel: LocalizedStringResource {
        if case .failed(.save, _) = viewModel?.state { .stockAdjustmentRetry } else { .stockAdjustmentSave }
    }

    @ViewBuilder
    private func toolbarLabel(_ label: LocalizedStringResource, systemImage: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            Image(systemName: systemImage)
                .frame(minWidth: 44, minHeight: 44)
        } else {
            Text(label)
                .frame(minWidth: 44, minHeight: 44)
        }
    }

    private func formContent(_ viewModel: StockAdjustmentViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return StockAdjustmentContent(
            direction: $viewModel.direction,
            unitsText: $viewModel.unitsText,
            reason: $viewModel.reason,
            state: viewModel.state,
            balanceState: viewModel.balanceState,
            productName: viewModel.loadedProduct?.name ?? "",
            quantity: viewModel.quantity,
            canEdit: viewModel.canEdit,
            isRequestPending: request != nil,
            validationAttemptID: validationAttemptID,
            onRetryLoad: {
                requestOperation(.load)
            },
            onRefresh: {
                requestOperation(.refresh)
            }
        )
    }

    private func requestOperation(_ operation: Operation) {
        guard request == nil else { return }
        request = Request(id: UUID(), operation: operation)
    }

    private func requestCancellation() {
        guard viewModel?.canClose != false else { return }
        if viewModel?.hasUnsavedChanges == true {
            showsDiscardChanges = true
        } else {
            finish()
        }
    }

    private func finish() {
        guard viewModel?.canClose != false else { return }
        request = nil
        viewModel?.close()
        onFinish()
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

#Preview("Adjustment", traits: .modifier(AppPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies

    StockAdjustmentScreen(
        destination: StockAdjustmentDestination(
            id: UUID(uuid: (9, 6, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1)),
            productID: ProductPreviewFixtures.standard.primaryProduct.id
        ),
        makeViewModel: dependencies.makeStockAdjustment,
        onFinish: {}
    )
}
