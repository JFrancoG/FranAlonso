import Foundation
import Observation

/// A presentation mode cannot gain editing capability from a later repository snapshot.
enum SaleDraftViewModelError: Error, Equatable {
    case readOnly
    case closed
    case invalidMode
    case quantityLimit
}

/// Projects one accepted draft Store and owns the separate read-only operational inspection session.
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
    private let store: SaleDraftStore
    private let getSale: GetSaleUseCase
    private let getClient: GetClientUseCase?
    private let createdAt: Date
    private let policy = WorkdaySalesPolicy()
    private let calculator = SaleCalculator()
    private var inspectionError: (any Error)?
    private var resolvedClient: (id: ClientID, name: String)?
    @ObservationIgnored private var inspectionGeneration: UUID?
    @ObservationIgnored private var contentGeneration: UUID?
    @ObservationIgnored private var clientNameGeneration: UUID?
    @ObservationIgnored private var announcedStockWarningIDs: Set<SaleLineID> = []

    var sale: Sale? {
        guard isReadOnly else { return store.draft }
        guard case let .content(sale, _) = inspectionState else { return nil }
        return sale
    }

    var calculation: SaleCalculation? {
        guard isReadOnly else { return store.calculation }
        guard case let .content(_, calculation) = inspectionState else { return nil }
        return calculation
    }

    var lastError: (any Error)? { isReadOnly ? inspectionError : store.lastError }
    var stockState: SaleDraftStockState { store.stockState }
    var stockError: (any Error)? { store.stockError }

    /// Only current editable deficits are presented; unknown stock never implies sufficiency.
    var stockWarnings: [StockImpact] {
        guard !isClosed, !isReadOnly, case let .ready(impacts) = stockState else { return [] }
        return impacts.filter(\.requiresWarning)
    }

    func stockWarning(for id: SaleLineID) -> StockImpact? {
        stockWarnings.first { $0.id == id }
    }

    /// Consumes one message for newly warned identities when the screen can actually communicate it.
    /// Unknown states retain deduplication; an accepted ready snapshot without deficits rearms it.
    func takeStockWarningAnnouncement() -> LocalizedStringResource? {
        guard !isClosed, !isReadOnly, case .ready = stockState else { return nil }
        let currentIDs = Set(stockWarnings.map(\.id))
        let hasNewWarning = !currentIDs.subtracting(announcedStockWarningIDs).isEmpty
        announcedStockWarningIDs = currentIDs
        return hasNewWarning ? .salesStockWarningAnnouncement : nil
    }

    var isBusy: Bool { isReadOnly ? inspectionState == .loading : store.isBusy }
    var isReadOnly: Bool { destination.mode == .inspect }
    var isClosed: Bool { store.state == .closed }
    var clientDisplayName: String? {
        guard !isClosed, resolvedClient?.id == sale?.clientID else { return nil }
        return resolvedClient?.name
    }

    var canCreate: Bool {
        destination.mode == .create && contentState == .ready && store.state == .idle && !isBusy
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
    /// Create sessions load no snapshot; their stable identity and timestamp are used only by explicit creation.
    /// - Throws: Draft rejection, read/calculation failure, cancellation, or a closed presentation session.
    func load() async throws -> Sale? {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        let generation = UUID()
        contentGeneration = generation
        contentState = .loading
        do {
            try Task.checkCancellation()
            let recovered: Sale?
            switch destination.mode {
            case .create:
                recovered = store.draft
            case .editDraft:
                recovered = try await store.load(id: destination.saleID)
            case .inspect:
                recovered = try await inspect()
            }
            try Task.checkCancellation()
            guard contentGeneration == generation, !isClosed else { throw CancellationError() }
            contentState = recovered != nil || destination.mode == .create ? .ready : .unavailable
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
        guard destination.mode == .create else { throw SaleDraftViewModelError.invalidMode }
        let accepted = try await store.create(
            id: destination.saleID,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines
        )
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

    /// Revalidates the accepted draft's advisory inventory without changing commercial terms.
    /// - Throws: A closed or read-only session rejection; stock failures remain in stockError.
    func refreshStock() async throws {
        try requireEditable()
        await store.refreshStock()
    }

    private func requireEditable() throws {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        guard !isReadOnly else { throw SaleDraftViewModelError.readOnly }
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
        getStock: GetSaleStockQuantitiesUseCase? = nil
    ) {
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
            getStock: getStock
        )
    }
}
