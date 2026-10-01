import Accessibility
import SwiftUI

struct SaleDraftScreen: View {
    private enum Operation: Equatable {
        case load
        case create
        case increase(SaleLineID)
        case decrease(SaleLineID)
        case remove(SaleLineID)
        case discard
    }

    private struct Request: Equatable {
        let id: UUID
        let operation: Operation
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: SaleDraftViewModel
    @State private var request: Request? = Request(id: UUID(), operation: .load)
    @State private var failedRequest: Request?
    @State private var confirmsDiscard = false
    @State private var removalID: SaleLineID?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(viewModel.isReadOnly ? LocalizedStringResource("sales.detail.title") :
                    LocalizedStringResource("sales.draft.title")))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("sales.close") {
                            dismiss()
                        }
                    }
                    if !viewModel.isReadOnly, viewModel.sale != nil {
                        ToolbarItem(placement: .primaryAction) {
                            Button("sales.discard", role: .destructive) {
                                confirmsDiscard = true
                            }
                            .disabled(isWorking)
                        }
                    }
                }
                .alert("sales.discard.title", isPresented: $confirmsDiscard) {
                    Button("sales.discard", role: .destructive) {
                        requestOperation(.discard)
                    }
                    Button("sales.keep", role: .cancel) {}
                } message: {
                    Text("sales.discard.message")
                }
                .confirmationDialog(
                    "sales.line.remove.title",
                    isPresented: showsRemovalConfirmation,
                    titleVisibility: .visible,
                    presenting: removalID
                ) { id in
                    Button("sales.line.remove", role: .destructive) {
                        requestOperation(.remove(id))
                    }
                    Button("sales.keep", role: .cancel) {}
                } message: { _ in
                    Text("sales.line.remove.message")
                }
        }
        .task(id: request) {
            guard let request else { return }
            await execute(request)
        }
        .task(id: viewModel.sale?.clientID) {
            await viewModel.resolveClientName()
        }
        .onDisappear {
            request = nil
            viewModel.close()
        }
    }

    private var isWorking: Bool { request != nil || viewModel.isBusy }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contentState {
        case .idle, .loading:
            LoadingStateView(label: "sales.detail.loading")
        case .ready:
            SaleDraftContent(
                viewModel: viewModel,
                isWorking: isWorking,
                hasActionError: failedRequest != nil,
                onCreate: { requestOperation(.create) },
                onIncrease: { requestOperation(.increase($0)) },
                onDecrease: { requestOperation(.decrease($0)) },
                onRemove: { removalID = $0 },
                onRetry: retry
            )
        case .unavailable, .closed:
            UnavailableStateView(
                title: "sales.detail.unavailable.title",
                systemImage: "doc.questionmark",
                message: "sales.detail.unavailable.message"
            )
        case .failed:
            UnavailableStateView(
                title: "sales.action.error.title",
                systemImage: "exclamationmark.triangle",
                message: "sales.action.error.message"
            ) {
                Button(action: retry) {
                    Text("sales.retry")
                        .frame(minHeight: 44)
                }
                .disabled(isWorking)
            }
        }
    }

    private func requestOperation(_ operation: Operation) {
        guard request == nil else { return }
        request = Request(id: UUID(), operation: operation)
    }

    private var showsRemovalConfirmation: Binding<Bool> {
        Binding {
            removalID != nil
        } set: { presented in
            if !presented {
                removalID = nil
            }
        }
    }

    private func retry() {
        requestOperation(failedRequest?.operation ?? .load)
    }

    private func execute(_ current: Request) async {
        failedRequest = nil
        do {
            switch current.operation {
            case .load:
                _ = try await viewModel.load()
            case .create:
                _ = try await viewModel.create()
            case let .increase(id):
                _ = try await viewModel.increaseQuantity(for: id)
            case let .decrease(id):
                _ = try await viewModel.decreaseQuantity(for: id)
            case let .remove(id):
                _ = try await viewModel.removeLine(id: id)
            case .discard:
                try await viewModel.discard()
            }
            guard request?.id == current.id, !viewModel.isClosed, !Task.isCancelled else { return }
            request = nil
            if current.operation == .discard {
                dismiss()
            } else if current.operation != .load {
                announce("sales.action.accepted")
            }
        } catch {
            guard request?.id == current.id, !viewModel.isClosed else { return }
            request = nil
            guard !(error is CancellationError), !Task.isCancelled else { return }
            failedRequest = current
            announce("sales.action.error.title")
        }
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension SaleDraftScreen {
    init(
        destination: SaleDraftDestination,
        makeViewModel: @MainActor @Sendable (SaleDraftDestination) -> SaleDraftViewModel
    ) {
        _viewModel = State(initialValue: makeViewModel(destination))
    }
}

#Preview("Draft", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 2, mode: .editDraft),
        makeViewModel: dependencies.makeSaleDraft
    )
}

#Preview("In progress", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 3, mode: .inspect),
        makeViewModel: dependencies.makeSaleDraft
    )
}

#Preview("Awaiting payment", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 4, mode: .inspect),
        makeViewModel: dependencies.makeSaleDraft
    )
}

#Preview("Awaiting document", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 5, mode: .inspect),
        makeViewModel: dependencies.makeSaleDraft
    )
}
