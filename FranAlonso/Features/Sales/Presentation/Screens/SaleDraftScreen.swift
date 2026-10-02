import Accessibility
import SwiftUI

struct SaleDraftScreen: View {
    let makeServicePicker: @MainActor @Sendable (SaleDraftViewModel) -> SaleServicePickerViewModel
    let makeDiscount: @MainActor @Sendable
        (SaleDraftViewModel, SaleDiscountDestination, Locale) -> SaleDiscountViewModel
    private enum Operation: Equatable {
        case load
        case create
        case increase(SaleLineID)
        case decrease(SaleLineID)
        case remove(SaleLineID)
        case discard
        case advance(SaleProgressAction)
        case preparePayment
        case payment
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
    @AccessibilityFocusState private var addServiceIsFocused: Bool
    @AccessibilityFocusState private var discountIsFocused: SaleLineID?
    @AccessibilityFocusState private var globalDiscountIsFocused: Bool
    @AccessibilityFocusState private var paymentIsFocused: Bool
    @State private var returnDiscountTarget: SaleDiscountDestination.Target?

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
        .sheet(item: servicePickerDestination, onDismiss: restoreAddServiceFocus) { destination in
            SaleServicePickerScreen {
                makeServicePicker(viewModel)
            }
            .id(destination.id)
        }
        .sheet(item: discountDestination, onDismiss: restoreDiscountFocus) { destination in
            SaleDiscountScreen {
                makeDiscount(viewModel, destination, locale)
            }
            .id(destination.id)
        }
        .sheet(item: stockConfirmation, onDismiss: restorePaymentFocus) { confirmation in
            SaleStockConfirmationView(
                confirmation: confirmation,
                onContinue: {
                    if viewModel.confirmPayment(confirmation.id) {
                        requestOperation(.payment)
                    }
                },
                onCancel: { viewModel.cancelPaymentConfirmation(confirmation.id) }
            )
        }
        .task(id: request) {
            guard let request else { return }
            await execute(request)
        }
        .task(id: viewModel.sale?.clientID) {
            await viewModel.resolveClientName()
        }
        .onChange(of: viewModel.stockState) {
            guard request == nil, viewModel.servicePickerDestination == nil,
                  viewModel.discountDestination == nil, viewModel.stockConfirmation == nil else { return }
            announceStockWarning()
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
                onRetry: retry,
                onAddService: presentServicePicker,
                addServiceIsFocused: $addServiceIsFocused,
                onEditDiscount: presentLineDiscount,
                discountIsFocused: $discountIsFocused,
                onEditGlobalDiscount: presentGlobalDiscount,
                globalDiscountIsFocused: $globalDiscountIsFocused,
                onAdvance: { requestOperation(.advance($0)) },
                onPayment: {
                    paymentIsFocused = false
                    requestOperation(.preparePayment)
                },
                paymentIsFocused: $paymentIsFocused
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
        requestOperation(viewModel.requiresReloadAfterActionError ? .load : (failedRequest?.operation ?? .load))
    }

    private var stockConfirmation: Binding<SaleStockConfirmation?> {
        let id = viewModel.stockConfirmation?.id
        return Binding { viewModel.stockConfirmation } set: { value in
            guard value == nil, let id else { return }
            viewModel.cancelPaymentConfirmation(id)
        }
    }

    private func restorePaymentFocus() {
        guard viewModel.stockConfirmation == nil, viewModel.showsPayment else { return }
        paymentIsFocused = true
    }

    private var servicePickerDestination: Binding<SaleServicePickerDestination?> {
        let sessionID = viewModel.servicePickerDestination?.id
        return Binding {
            viewModel.servicePickerDestination
        } set: { destination in
            guard destination == nil, let sessionID else { return }
            viewModel.finishServicePicker(sessionID)
        }
    }

    private func presentServicePicker() {
        globalDiscountIsFocused = false
        addServiceIsFocused = false
        discountIsFocused = nil
        viewModel.presentServicePicker()
    }

    private var discountDestination: Binding<SaleDiscountDestination?> {
        let sessionID = viewModel.discountDestination?.id
        return Binding {
            viewModel.discountDestination
        } set: { destination in
            guard destination == nil, let sessionID else { return }
            viewModel.finishDiscount(sessionID)
        }
    }

    private func presentLineDiscount(_ id: SaleLineID) {
        returnDiscountTarget = .line(id)
        globalDiscountIsFocused = false
        discountIsFocused = nil
        addServiceIsFocused = false
        viewModel.presentLineDiscount(for: id)
    }

    private func presentGlobalDiscount() {
        returnDiscountTarget = .global
        globalDiscountIsFocused = false
        discountIsFocused = nil
        addServiceIsFocused = false
        viewModel.presentGlobalDiscount()
    }

    private func restoreDiscountFocus() {
        guard viewModel.discountDestination == nil, let target = returnDiscountTarget else { return }
        returnDiscountTarget = nil
        switch target {
        case let .line(id):
            guard viewModel.canEditDiscount(for: id) else { return }
            discountIsFocused = id
        case .global:
            guard viewModel.canEditGlobalDiscount else { return }
            globalDiscountIsFocused = true
        }
        announceStockWarning()
    }

    private func restoreAddServiceFocus() {
        guard viewModel.servicePickerDestination == nil, viewModel.canAddServices else { return }
        addServiceIsFocused = true
        announceStockWarning()
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
            case let .advance(action):
                _ = try await viewModel.advance(action)
            case .preparePayment:
                if try await viewModel.preparePayment() {
                    _ = try await viewModel.registerPreparedPayment()
                }
            case .payment:
                _ = try await viewModel.registerPreparedPayment()
            }
            guard request?.id == current.id, !viewModel.isClosed, !Task.isCancelled else { return }
            request = nil
            if current.operation == .discard {
                dismiss()
            } else if current.operation == .payment || (current.operation == .preparePayment && viewModel.awaitsDocument) {
                announce("sales.payment.accepted")
            } else if viewModel.stockConfirmation != nil {
                // The modal communicates the advisory state without a competing background announcement.
            } else if let warning = viewModel.takeStockWarningAnnouncement() {
                announce(warning)
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

    private func announceStockWarning() {
        guard let warning = viewModel.takeStockWarningAnnouncement() else { return }
        announce(warning)
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension SaleDraftScreen {
    /// Keeps the already prepared preview snapshot visible without an initial load task.
    fileprivate init(
        previewModel: SaleDraftViewModel,
        makeServicePicker: @escaping @MainActor @Sendable (SaleDraftViewModel) -> SaleServicePickerViewModel,
        makeDiscount: @escaping @MainActor @Sendable
            (SaleDraftViewModel, SaleDiscountDestination, Locale) -> SaleDiscountViewModel
    ) {
        self.makeServicePicker = makeServicePicker
        self.makeDiscount = makeDiscount
        _viewModel = State(initialValue: previewModel)
        _request = State(initialValue: nil)
    }

    init(
        destination: SaleDraftDestination,
        makeViewModel: @MainActor @Sendable (SaleDraftDestination) -> SaleDraftViewModel,
        makeServicePicker: @escaping @MainActor @Sendable (SaleDraftViewModel) -> SaleServicePickerViewModel,
        makeDiscount: @escaping @MainActor @Sendable
            (SaleDraftViewModel, SaleDiscountDestination, Locale) -> SaleDiscountViewModel
    ) {
        self.makeServicePicker = makeServicePicker
        self.makeDiscount = makeDiscount
        _viewModel = State(initialValue: makeViewModel(destination))
    }
}

#Preview("Draft", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 2, mode: .editDraft),
        makeViewModel: dependencies.makeSaleDraft,
        makeServicePicker: dependencies.makeSaleServicePicker,
        makeDiscount: dependencies.makeSaleDiscount
    )
}

#Preview("In progress", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 3, mode: .operate),
        makeViewModel: dependencies.makeSaleDraft,
        makeServicePicker: dependencies.makeSaleServicePicker,
        makeDiscount: dependencies.makeSaleDiscount
    )
}

#Preview("Awaiting payment", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 4, mode: .operate),
        makeViewModel: dependencies.makeSaleDraft,
        makeServicePicker: dependencies.makeSaleServicePicker,
        makeDiscount: dependencies.makeSaleDiscount
    )
}

#Preview("Awaiting document", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    SaleDraftScreen(
        destination: SalesPreviewFixtures.destination(index: 5, mode: .operate),
        makeViewModel: dependencies.makeSaleDraft,
        makeServicePicker: dependencies.makeSaleServicePicker,
        makeDiscount: dependencies.makeSaleDiscount
    )
}

#Preview("Stock warnings", traits: .modifier(SaleStockPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    @Previewable @Environment(\.saleStockPreviewModel) var model
    if let model {
        SaleDraftScreen(
            previewModel: model,
            makeServicePicker: dependencies.makeSaleServicePicker,
            makeDiscount: dependencies.makeSaleDiscount
        )
    }
}

#Preview("Operational payment", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    @Previewable @Environment(\.salesPreviewModels) var models
    if let model = models[SalesPreviewFixtures.workday.sales[4].id] {
        SaleDraftScreen(
            previewModel: model,
            makeServicePicker: dependencies.makeSaleServicePicker,
            makeDiscount: dependencies.makeSaleDiscount
        )
    }
}
