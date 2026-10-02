import Foundation
import Observation

/// A presentation mode cannot gain editing capability from a later repository snapshot.
enum SaleDraftViewModelError: Error, Equatable {
    case readOnly
    case closed
    case invalidMode
    case quantityLimit
}

/// Projects one accepted sale Store for editing and work; explicit inspection remains a separate read-only session.
@Observable @MainActor
final class SaleDraftViewModel {
    /// Load lifecycle without another sale snapshot; a new create session is ready before it has a persisted sale.
    enum ContentState: Equatable {
        case idle
        case loading
        case ready
        case unavailable
        case failed
        case closed
    }

    enum InspectionState: Equatable {
        case idle
        case loading
        case content(Sale, SaleCalculation)
        case unavailable
        case failed
        case closed
    }

    let destination: SaleDraftDestination
    private(set) var contentState: ContentState = .idle
    private(set) var inspectionState: InspectionState = .idle
    private(set) var servicePickerDestination: SaleServicePickerDestination?
    private(set) var discountDestination: SaleDiscountDestination?
    private(set) var selectedPaymentMethod: PaymentMethod?
    private(set) var stockConfirmation: SaleStockConfirmation?
    private(set) var isPreparingPayment = false
    private let store: SaleDraftStore
    private let getSale: GetSaleUseCase
    private let getClient: GetClientUseCase?
    private let createdAt: Date
    private let policy = WorkdaySalesPolicy()
    private let calculator = SaleCalculator()
    private let hasWorkflow: Bool
    private let makePaymentID: @MainActor () -> UUID
    private let paymentDate: @MainActor () -> Date
    private struct PaymentCommand {
        let expected: Sale
        let id: PaymentID
        let method: PaymentMethod
        let paidAt: Date
    }
    @ObservationIgnored private var hasCreatedSale = false
    @ObservationIgnored private var pendingPayment: PaymentCommand?
    @ObservationIgnored private var paymentIsConfirmed = false
    @ObservationIgnored private var paymentGeneration: UUID?
    private var inspectionError: (any Error)?
    private var resolvedClient: (id: ClientID, name: String)?
    @ObservationIgnored private var inspectionGeneration: UUID?
    @ObservationIgnored private var contentGeneration: UUID?
    @ObservationIgnored private var clientNameGeneration: UUID?
    @ObservationIgnored private var announcedStockWarningIDs: Set<SaleLineID> = []

    var sale: Sale? {
        guard destination.mode == .inspect else { return store.sale }
        guard case let .content(sale, _) = inspectionState else { return nil }
        return sale
    }

    var calculation: SaleCalculation? {
        guard destination.mode == .inspect else { return store.calculation }
        guard case let .content(_, calculation) = inspectionState else { return nil }
        return calculation
    }

    var lastError: (any Error)? { destination.mode == .inspect ? inspectionError : store.lastError }
    var stockState: SaleDraftStockState { store.stockState }
    var stockError: (any Error)? { store.stockError }

    /// Only current editable deficits are presented; unknown stock never implies sufficiency.
    var stockWarnings: [StockImpact] {
        guard !isClosed, destination.mode != .inspect, case let .ready(impacts) = stockState else { return [] }
        return impacts.filter(\.requiresWarning)
    }

    func stockWarning(for id: SaleLineID) -> StockImpact? {
        stockWarnings.first { $0.id == id }
    }

    /// Consumes one message for newly warned identities when the screen can actually communicate it.
    /// Unknown states retain deduplication; an accepted ready snapshot without deficits rearms it.
    func takeStockWarningAnnouncement() -> LocalizedStringResource? {
        guard !isClosed, destination.mode != .inspect, case .ready = stockState else { return nil }
        let currentIDs = Set(stockWarnings.map(\.id))
        let hasNewWarning = !currentIDs.subtracting(announcedStockWarningIDs).isEmpty
        announcedStockWarningIDs = currentIDs
        return hasNewWarning ? .salesStockWarningAnnouncement : nil
    }

    var isBusy: Bool {
        isPreparingPayment || (destination.mode == .inspect ? inspectionState == .loading : store.isBusy)
    }
    var isReadOnly: Bool { destination.mode == .inspect || destination.mode == .operate ||
        (sale != nil && sale?.status != .draft) }
    var isClosed: Bool { store.state == .closed }
    var clientDisplayName: String? {
        guard !isClosed, resolvedClient?.id == sale?.clientID else { return nil }
        return resolvedClient?.name
    }

    var canCreate: Bool {
        destination.mode == .create && !hasCreatedSale && contentState == .ready && store.state == .idle && !isBusy
    }

    var canAddServices: Bool {
        !isClosed && !isReadOnly && !isBusy && contentState == .ready && store.draft != nil
            && discountDestination == nil
    }

    /// Opens selection only over an accepted editable draft; repeated requests retain the active sheet identity.
    func presentServicePicker() {
        guard canAddServices, servicePickerDestination == nil else { return }
        servicePickerDestination = SaleServicePickerDestination(id: UUID())
    }

    /// Ends only the matching nested presentation, preserving the parent Store and accepted draft.
    func finishServicePicker(_ id: UUID) {
        guard servicePickerDestination?.id == id else { return }
        servicePickerDestination = nil
    }

    /// Grants editing only for a current line of an accepted editable draft, outside service selection.
    func canEditDiscount(for id: SaleLineID) -> Bool {
        !isClosed && !isReadOnly && !isBusy && contentState == .ready && servicePickerDestination == nil
            && store.draft?.lines.contains(where: { $0.id == id }) == true
    }

    /// Retains one editor identity; presentation itself does not mutate commercial terms.
    func presentLineDiscount(for id: SaleLineID) {
        guard canEditDiscount(for: id), discountDestination == nil else { return }
        discountDestination = SaleDiscountDestination(id: UUID(), target: .line(id))
    }

    var canEditGlobalDiscount: Bool {
        !isClosed && !isReadOnly && !isBusy && contentState == .ready && servicePickerDestination == nil
            && store.draft != nil
    }

    /// Opens a global editor without changing either captured discount term.
    func presentGlobalDiscount() {
        guard canEditGlobalDiscount, discountDestination == nil else { return }
        discountDestination = SaleDiscountDestination(id: UUID(), target: .global)
    }

    /// Ends only the matching nested editor, leaving the accepted parent Store alive.
    func finishDiscount(_ id: UUID) {
        guard discountDestination?.id == id else { return }
        discountDestination = nil
    }

    func canIncrease(for id: SaleLineID) -> Bool {
        guard !isClosed, !isReadOnly, !isBusy, contentState == .ready,
              let line = sale?.lines.first(where: { $0.id == id }) else { return false }
        return line.quantity < Int.max
    }

    func canDecrease(for id: SaleLineID) -> Bool {
        guard !isClosed, !isReadOnly, !isBusy, contentState == .ready,
              let line = sale?.lines.first(where: { $0.id == id }) else { return false }
        return line.quantity > 1
    }

    /// Accepts a single quantity increase without integer overflow; read-only and closed sessions reject first.
    /// - Throws: A session rejection, missing line, quantity limit or Store acceptance error.
    func increaseQuantity(for id: SaleLineID) async throws -> Sale {
        try requireEditable()
        let quantity = try currentQuantity(for: id)
        guard quantity < Int.max else { throw SaleDraftViewModelError.quantityLimit }
        return try await setQuantity(quantity + 1, for: id)
    }

    /// Accepts a single quantity decrease while retaining a strictly positive quantity.
    /// - Throws: A session rejection, missing line, quantity limit or Store acceptance error.
    func decreaseQuantity(for id: SaleLineID) async throws -> Sale {
        try requireEditable()
        let quantity = try currentQuantity(for: id)
        guard quantity > 1 else { throw SaleDraftViewModelError.quantityLimit }
        return try await setQuantity(quantity - 1, for: id)
    }

    /// Resolves only a display label in a caller-owned task.
    /// Client lookup never changes sale acceptance or association.
    /// Cancellation, changed association and close fence late reads; unavailable clients have no label.
    func resolveClientName() async {
        let generation = UUID()
        clientNameGeneration = generation
        resolvedClient = nil
        guard !isClosed, let id = sale?.clientID, let getClient else { return }
        do {
            try Task.checkCancellation()
            let client = try await getClient(id)
            try Task.checkCancellation()
            guard clientNameGeneration == generation, !isClosed, sale?.clientID == id else { return }
            resolvedClient = (id, client.displayName)
        } catch {
            guard clientNameGeneration == generation else { return }
            resolvedClient = nil
        }
    }

    /// Loads editable content through the one Store, or reads operational content without granting mutation capability.
    /// Reserved create sessions read no snapshot; after acceptance, reload recovers the same stable identity.
    /// - Throws: Draft rejection, read/calculation failure, cancellation, or a closed presentation session.
    func load() async throws -> Sale? {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        invalidatePayment()
        let generation = UUID()
        contentGeneration = generation
        contentState = .loading
        do {
            try Task.checkCancellation()
            let recovered: Sale?
            switch destination.mode {
            case .create:
                if hasWorkflow, hasCreatedSale {
                    recovered = try await store.loadOperation(id: destination.saleID)
                } else {
                    recovered = store.draft
                }
            case .editDraft:
                recovered = hasWorkflow ? try await store.loadOperation(id: destination.saleID) :
                    try await store.load(id: destination.saleID)
            case .inspect:
                recovered = try await inspect()
            case .operate:
                recovered = try await store.loadOperation(id: destination.saleID)
            }
            try Task.checkCancellation()
            guard contentGeneration == generation, !isClosed else { throw CancellationError() }
            let isReservedCreation = destination.mode == .create && !hasCreatedSale
            contentState = recovered != nil || isReservedCreation ? .ready : .unavailable
            return recovered
        } catch {
            if contentGeneration == generation, !isClosed {
                contentState = error is CancellationError || Task.isCancelled ? .idle : .failed
            }
            throw error
        }
    }

    /// Uses the session's fixed identity and creation time across local failures and retries.
    /// - Throws: A mode/session rejection or Store validation and local acceptance errors.
    func create(clientID: ClientID? = nil, lines: [SaleLine] = []) async throws -> Sale {
        try requireEditable()
        guard destination.mode == .create, !hasCreatedSale else { throw SaleDraftViewModelError.invalidMode }
        let accepted = try await store.create(
            id: destination.saleID,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines
        )
        hasCreatedSale = true
        if !isClosed {
            contentState = .ready
        }
        return accepted
    }

    /// Delegates captured-line acceptance to the Store without maintaining another editable snapshot.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func addLine(_ line: SaleLine) async throws -> Sale {
        try requireEditable()
        return try await store.addLine(line)
    }

    /// Delegates removal by stable line identity.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func removeLine(id: SaleLineID) async throws -> Sale {
        try requireEditable()
        return try await store.removeLine(id: id)
    }

    /// Accepted writes keep their success after cancellation or close; the Store alone controls publication.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func setQuantity(_ quantity: Int, for id: SaleLineID) async throws -> Sale {
        try requireEditable()
        return try await store.setQuantity(quantity, for: id)
    }

    /// Delegates client association or removal to the accepted draft session.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func setClient(_ id: ClientID?) async throws -> Sale {
        try requireEditable()
        return try await store.setClient(id)
    }

    /// Delegates the existing line-discount policy; global discounts remain outside this façade.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func setDiscount(_ discount: Discount?, for id: SaleLineID) async throws -> Sale {
        try requireEditable()
        return try await store.setDiscount(discount, for: id)
    }

    /// Delegates the editor's frozen percentage; Domain selects and captures the provisional policy.
    func setGlobalDiscount(_ discount: Discount?) async throws -> Sale {
        try requireEditable()
        return try await store.setGlobalDiscount(discount)
    }

    /// Discards only through the Store's durable draft contract.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func discard() async throws {
        try requireEditable()
        try await store.discard()
        if !isClosed {
            contentState = .unavailable
        }
    }

    /// Ends presentation, fences late inspection reads and closes the Store without discarding accepted data.
    func close() {
        invalidatePayment()
        servicePickerDestination = nil
        discountDestination = nil
        inspectionGeneration = nil
        contentGeneration = nil
        clientNameGeneration = nil
        resolvedClient = nil
        contentState = .closed
        inspectionError = nil
        inspectionState = .closed
        store.close()
    }

    /// Revalidates the accepted sale's advisory inventory without changing commercial terms.
    /// - Throws: A closed or read-only session rejection; stock failures remain in stockError.
    func refreshStock() async throws {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        guard destination.mode != .inspect else { throw SaleDraftViewModelError.readOnly }
        await store.refreshStock()
    }

    private func requireEditable() throws {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        guard !isReadOnly else { throw SaleDraftViewModelError.readOnly }
        guard !isPreparingPayment, stockConfirmation == nil else { throw SaleDraftStoreError.operationInProgress }
    }

    private func currentQuantity(for id: SaleLineID) throws -> Int {
        guard let draft = store.draft else { throw SaleDraftStoreError.noDraft }
        guard let line = draft.lines.first(where: { $0.id == id }) else { throw SaleError.lineNotFound }
        return line.quantity
    }

    private func inspect() async throws -> Sale? {
        let generation = UUID()
        inspectionGeneration = generation
        inspectionState = .loading
        inspectionError = nil
        do {
            let recovered = try await getSale(id: destination.saleID)
            try Task.checkCancellation()
            guard inspectionGeneration == generation else { throw CancellationError() }
            guard let recovered, let category = policy.category(of: recovered), category != .upcoming else {
                inspectionState = .unavailable
                return nil
            }
            let calculation = try calculator.calculate(sale: recovered, currency: store.currency)
            inspectionState = .content(recovered, calculation)
            return recovered
        } catch {
            guard inspectionGeneration == generation else { throw CancellationError() }
            if error is CancellationError || Task.isCancelled {
                inspectionState = .idle
                throw CancellationError()
            }
            inspectionError = error
            inspectionState = .failed
            throw error
        }
    }

    init(
        destination: SaleDraftDestination,
        createdAt: Date,
        currency: Currency,
        create: CreateSaleDraftUseCase,
        getDraft: GetSaleDraftUseCase,
        update: UpdateSaleDraftUseCase,
        discard: DiscardSaleDraftUseCase,
        getSale: GetSaleUseCase,
        getClient: GetClientUseCase? = nil,
        getStock: GetSaleStockQuantitiesUseCase? = nil,
        advance: AdvanceSaleUseCase? = nil,
        registerPayment: RegisterSalePaymentUseCase? = nil,
        makePaymentID: @escaping @MainActor () -> UUID = { UUID() },
        paymentDate: @escaping @MainActor () -> Date = { Date() }
    ) {
        hasWorkflow = advance != nil && registerPayment != nil
        self.makePaymentID = makePaymentID
        self.paymentDate = paymentDate
        self.destination = destination
        self.createdAt = createdAt
        self.getSale = getSale
        self.getClient = getClient
        store = SaleDraftStore(
            currency: currency,
            create: create,
            get: getDraft,
            update: update,
            discard: discard,
            getStock: getStock,
            getSale: getSale,
            advance: advance,
            registerPayment: registerPayment
        )
    }
}

extension SaleDraftViewModel {
    var requiresReloadAfterActionError: Bool {
        let draftError = lastError as? SaleDraftError
        return lastError as? SaleProgressError == .staleSale || lastError as? SalePaymentError == .staleSale
            || draftError == .requiresDraft || draftError == .staleDraft
    }
    var showsWorkflow: Bool { hasWorkflow && destination.mode != .inspect && sale != nil && !isClosed }
    var awaitsDocument: Bool {
        guard showsWorkflow, case .awaitingDocument = sale?.status else { return false }
        return true
    }

    func title(for action: SaleProgressAction) -> LocalizedStringResource {
        switch action {
        case .start: return "sales.workflow.start"
        case let .startLine(id):
            return .salesWorkflowStartLine(sale?.lines.first { $0.id == id }?.serviceName ?? "")
        case let .completeLine(id):
            return .salesWorkflowCompleteLine(sale?.lines.first { $0.id == id }?.serviceName ?? "")
        }
    }

    var confirmationWarnings: [SaleStockConfirmation.Warning] {
        stockWarnings.compactMap { impact in
            guard let line = sale?.lines.first(where: { $0.id == impact.id }) else { return nil }
            return SaleStockConfirmation.Warning(
                id: impact.id,
                serviceName: line.serviceName,
                projectedQuantity: impact.projectedQuantity
            )
        }
    }
    /// Available work intentions come from the aggregate's state; Views only render these intentions.
    var progressActions: [SaleProgressAction] {
        guard hasWorkflow, destination.mode != .inspect, !isClosed, !isBusy, stockConfirmation == nil,
              servicePickerDestination == nil, discountDestination == nil, let sale else { return [] }
        switch sale.status {
        case .draft: return sale.lines.isEmpty ? [] : [.start]
        case .inProgress:
            return sale.lines.compactMap { line in
                switch line.status {
                case .upcoming: .startLine(line.id)
                case .inProgress: .completeLine(line.id)
                case .completed: nil
                }
            }
        default: return []
        }
    }

    var showsPayment: Bool { hasWorkflow && destination.mode != .inspect && sale?.status == .awaitingPayment }
    var canRegisterPayment: Bool {
        showsPayment && !isBusy && stockConfirmation == nil && selectedPaymentMethod != nil
    }

    /// Advances only eligible work, revoking any prior payment review before accepting a transition.
    func advance(_ action: SaleProgressAction) async throws -> Sale {
        guard progressActions.contains(action) else { throw SaleDraftViewModelError.invalidMode }
        invalidatePayment()
        return try await store.advance(action)
    }

    /// Changing a method invalidates a prepared command rather than mutating its frozen metadata.
    func selectPaymentMethod(_ method: PaymentMethod?) {
        guard showsPayment, !isBusy, stockConfirmation == nil else { return }
        if selectedPaymentMethod != method {
            invalidatePayment()
            selectedPaymentMethod = method
        }
    }

    /// Refreshes advisory inventory in the caller's task; presentation itself never mutates business data.
    /// Returns true for sufficient stock or a previously confirmed retry; unknown stock requires explicit consent.
    func preparePayment() async throws -> Bool {
        guard canRegisterPayment, let expected = sale, let method = selectedPaymentMethod else {
            throw SaleDraftViewModelError.invalidMode
        }
        if paymentIsConfirmed, let pendingPayment, pendingPayment.expected == expected,
           pendingPayment.method == method {
            return true
        }
        invalidatePayment()
        let generation = UUID()
        paymentGeneration = generation
        isPreparingPayment = true
        defer {
            if paymentGeneration == generation {
                isPreparingPayment = false
            }
        }
        await store.refreshStock()
        try Task.checkCancellation()
        guard !isClosed, paymentGeneration == generation, sale == expected else { throw CancellationError() }
        let command = PaymentCommand(
            expected: expected,
            id: PaymentID(rawValue: makePaymentID()),
            method: method,
            paidAt: paymentDate()
        )
        pendingPayment = command
        let warnings = confirmationWarnings
        let unavailable: Bool
        if case .ready = stockState {
            unavailable = false
        } else {
            unavailable = true
        }
        if warnings.isEmpty && !unavailable {
            paymentIsConfirmed = true
            return true
        }
        stockConfirmation = SaleStockConfirmation(
            id: command.id.rawValue,
            warnings: warnings,
            stockUnavailable: unavailable
        )
        return false
    }

    /// Consumes only the matching live review; duplicate callbacks and obsolete snapshots cannot pay.
    func confirmPayment(_ id: UUID) -> Bool {
        guard stockConfirmation?.id == id, let command = pendingPayment, command.expected == sale,
              !isClosed, !isBusy, command.method == selectedPaymentMethod else { return false }
        stockConfirmation = nil
        paymentIsConfirmed = true
        return true
    }

    /// Explicit cancel and interactive sheet dismissal revoke only the matching unconfirmed intention.
    func cancelPaymentConfirmation(_ id: UUID) {
        guard stockConfirmation?.id == id else { return }
        invalidatePayment()
    }

    /// Uses the same identity/time on failure and retry; successful local acceptance consumes the command.
    /// Late accepted success is returned without reopening a closed Store or presentation.
    func registerPreparedPayment() async throws -> Sale {
        guard !isClosed, !isBusy, paymentIsConfirmed, let command = pendingPayment else {
            throw SaleDraftViewModelError.invalidMode
        }
        let accepted = try await store.pay(
            command.expected,
            id: command.id,
            method: command.method,
            paidAt: command.paidAt
        )
        if pendingPayment?.id == command.id {
            invalidatePayment()
        }
        return accepted
    }

    private func invalidatePayment() {
        pendingPayment = nil
        paymentIsConfirmed = false
        stockConfirmation = nil
        paymentGeneration = nil
        isPreparingPayment = false
    }
}
