import Accessibility
import SwiftUI

struct WorkdayScreen<Repository: BillingDocumentReservationRepository>: View {
    let makeSaleDraft: @MainActor @Sendable (SaleDraftDestination) -> SaleDraftViewModel
    let makeServicePicker: @MainActor @Sendable (SaleDraftViewModel) -> SaleServicePickerViewModel
    let makeDiscount: @MainActor @Sendable
        (SaleDraftViewModel, SaleDiscountDestination, Locale) -> SaleDiscountViewModel
    let makeBilling: @MainActor @Sendable
        (SaleDraftViewModel, BillingDocumentDestination) -> BillingViewModel<Repository>
    @Environment(\.locale) private var locale
    @AccessibilityFocusState private var focusedSale: SaleID?
    @AccessibilityFocusState private var createIsFocused: Bool
    @State private var observationRequestID = UUID()
    @State private var returnSaleID: SaleID?
    @State private var viewModel: WorkdayViewModel

    var body: some View {
        WorkdayContent(
            state: viewModel.state,
            clientNames: viewModel.clientDisplayNames,
            focusedSale: $focusedSale,
            onSelect: openSale,
            onRetry: { observationRequestID = UUID() }
        )
        .navigationTitle(Text("sales.workday.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: beginCreating) {
                    Label("sales.workday.create", systemImage: "plus")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityFocused($createIsFocused)
            }
        }
        .sheet(item: destination, onDismiss: restoreFocus) { destination in
            SaleDraftScreen(
                destination: destination,
                makeViewModel: makeSaleDraft,
                makeServicePicker: makeServicePicker,
                makeDiscount: makeDiscount,
                makeBilling: makeBilling
            )
                .id(destination.id)
        }
        .task(id: observationRequestID) {
            await viewModel.load()
        }
        .task(id: viewModel.clientIDs) {
            await viewModel.resolveClientNames()
        }
        .onChange(of: viewModel.state) { _, state in
            if state == .failed {
                announce("sales.workday.error.title")
            }
        }
    }

    private var destination: Binding<SaleDraftDestination?> {
        let sessionID = viewModel.destination?.id
        return Binding {
            viewModel.destination
        } set: { newValue in
            guard newValue == nil, let sessionID, viewModel.destination?.id == sessionID else { return }
            viewModel.finishSession(sessionID)
        }
    }

    private func openSale(_ id: SaleID) {
        returnSaleID = id
        focusedSale = nil
        createIsFocused = false
        viewModel.openSale(id)
    }

    private func beginCreating() {
        returnSaleID = nil
        focusedSale = nil
        createIsFocused = false
        viewModel.beginCreatingSale()
    }

    private func restoreFocus() {
        guard viewModel.destination == nil else { return }
        if let returnSaleID, case let .content(board) = viewModel.state,
           board.sales.contains(where: { $0.id == returnSaleID }) {
            focusedSale = returnSaleID
        } else {
            createIsFocused = true
        }
        returnSaleID = nil
    }

    private func announce(_ resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = locale
        AccessibilityNotification.Announcement(String(localized: resource)).post()
    }
}

extension WorkdayScreen {
    init(
        makeViewModel: @MainActor @Sendable () -> WorkdayViewModel,
        makeSaleDraft: @escaping @MainActor @Sendable (SaleDraftDestination) -> SaleDraftViewModel,
        makeServicePicker: @escaping @MainActor @Sendable (SaleDraftViewModel) -> SaleServicePickerViewModel,
        makeDiscount: @escaping @MainActor @Sendable
            (SaleDraftViewModel, SaleDiscountDestination, Locale) -> SaleDiscountViewModel,
        makeBilling: @escaping @MainActor @Sendable
            (SaleDraftViewModel, BillingDocumentDestination) -> BillingViewModel<Repository>
    ) {
        self.makeSaleDraft = makeSaleDraft
        self.makeServicePicker = makeServicePicker
        self.makeDiscount = makeDiscount
        self.makeBilling = makeBilling
        _viewModel = State(initialValue: makeViewModel())
    }
}

#Preview("Workday", traits: .modifier(SalesPreviewModifier())) {
    @Previewable @Environment(\.appDependencies) var dependencies
    NavigationStack {
        WorkdayScreen(
            makeViewModel: dependencies.makeWorkday,
            makeSaleDraft: dependencies.makeSaleDraft,
            makeServicePicker: dependencies.makeSaleServicePicker,
            makeDiscount: dependencies.makeSaleDiscount,
            makeBilling: dependencies.makeBilling
        )
    }
}
