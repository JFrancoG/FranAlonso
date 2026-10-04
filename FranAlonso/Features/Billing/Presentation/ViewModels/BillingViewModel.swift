import Foundation
import Observation
import SwiftData

/// The presentation facade reads its Store directly, including through Observation tracking.
@Observable @MainActor
final class BillingViewModel<Repository: BillingDocumentReservationRepository> {
    typealias CloseSale = @MainActor (SaleClosureRequest, ModelContext) async throws -> Sale

    private let store: BillingDocumentStore<Repository>
    private let sale: Sale?
    private let prepareDocument: PrepareBillingDocumentRequestUseCase
    private let getClient: GetClientUseCase?
    private let preparationIsAvailable: @MainActor @Sendable () -> Bool
    private let acceptSaleClosure: CloseSale?
    private let now: @MainActor @Sendable () -> Date
    private var closureRequest: SaleClosureRequest?
    private var fiscalInput = BillingFiscalRecipientInput()
    private var selection: BillingDocumentKind = .ticket
    @ObservationIgnored private var prefillGeneration: UUID?
    @ObservationIgnored private var hasAttemptedPrefill = false
    @ObservationIgnored private var hasEditedInput = false
    @ObservationIgnored private var activeOperationID: UUID?
    private(set) var formIssue: BillingFormIssue?
    private(set) var validationID: UUID?
    private(set) var isLoadingRecipient = false
    let isDemonstration: Bool
    private(set) var closureFailure: SaleClosureError?
    private(set) var operationRequest: BillingOperationRequest?
    private(set) var operationFailed = false
    private(set) var operationAnnouncementID: UUID?
    private(set) var recoveryFailed = false
    private(set) var requiresDocumentSelection = false
    private var hasLoaded = false

    var requiresPersistence: Bool { store.requiresPersistence }
    var closedSale: Sale? { store.closedSale }
    var canCloseSale: Bool {
        guard preparationIsAvailable(), acceptSaleClosure != nil, !isBusy, closedSale == nil,
              let delivery, delivery.document != nil, delivery.pdf != nil else { return false }
        guard case .materialization(_, .ready) = state else { return false }
        return true
    }
    var isWorking: Bool { isBusy || operationRequest != nil }
    var canGenerate: Bool {
        guard requiresPersistence, preparationIsAvailable(), !isWorking, closedSale == nil,
              let delivery, !delivery.isFinal else { return false }
        guard case .materialization(_, .ready) = state else { return false }
        return true
    }

    /// Discovers an existing sale family before a new selection can generate allocation identities.
    func load() async throws {
        defer {
            if hasLoaded, activeOperationID == nil, operationRequest?.operation == .load {
                operationRequest = nil
            }
        }
        guard !hasLoaded else { return }
        guard requiresPersistence else {
            hasLoaded = true
            return
        }
        guard preparationIsAvailable(), let sale else { throw BillingDocumentPersistenceError.unauthorized }
        do {
            _ = try await store.recover(saleID: sale.id, validateAcceptance: validateRecoveryAcceptance)
        } catch BillingDocumentPersistenceError.ambiguousSelection {
            try validateRecoveryAcceptance()
            requiresDocumentSelection = true
        }
        try validateRecoveryAcceptance()
        hasLoaded = true
        recoveryFailed = false
    }

    /// Keeps the caller's context ephemeral; every retry retains the same closure request and timestamp.
    func closeSale(in context: ModelContext) async throws -> Sale {
        if let accepted = closedSale {
            return accepted
        }
        guard !isBusy else { throw BillingDocumentStoreError.operationInProgress }
        guard preparationIsAvailable(), let acceptSaleClosure else { throw SaleClosureError.unauthorized }
        guard let delivery, delivery.document != nil, delivery.pdf != nil else {
            throw SaleClosureError.documentPending
        }
        let request: SaleClosureRequest
        if let retained = closureRequest {
            request = retained
        } else {
            request = try SaleClosureRequest(expected: delivery.request.sale, requestID: delivery.id, closedAt: now())
            closureRequest = request
        }
        do {
            let accepted = try await store.closeSale(request) {
                let accepted = try await acceptSaleClosure(request, context)
                guard self.preparationIsAvailable() else { throw CancellationError() }
                return accepted
            }
            closureFailure = nil
            return accepted
        } catch {
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }
            closureFailure = error as? SaleClosureError ?? .persistenceUnavailable
            throw error
        }
    }

    func requestLoad() {
        requestOperation(.load)
    }

    /// Captures an explicit saved family; retry never prepares a replacement request.
    func requestSelectedDocumentRecovery() {
        guard requiresDocumentSelection, canSelectKind else { return }
        requestOperation(.recoverFamily(selection))
    }

    func requestPreparation() {
        guard !requiresDocumentSelection else { return }
        requestOperation(.prepare)
    }

    func requestGeneration() {
        requestOperation(.generate)
    }

    func requestSaleClosure() {
        requestOperation(.closeSale)
    }

    /// Claims only the captured current intention once; stale, nil and duplicate task snapshots have no effects.
    func performRequestedOperation(_ request: BillingOperationRequest?, in context: ModelContext) async {
        guard let request, operationRequest == request, activeOperationID == nil else { return }
        let operationRequest = request
        activeOperationID = request.id
        operationFailed = false
        defer {
            if activeOperationID == operationRequest.id {
                activeOperationID = nil
                if self.operationRequest?.id == operationRequest.id {
                    self.operationRequest = nil
                }
            }
        }
        do {
            switch operationRequest.operation {
            case .load:
                try await load()
            case let .recoverFamily(kind):
                try await recoverSelectedFamily(kind)
            case .prepare:
                if requiresPersistence {
                    _ = try await prepareSelectionDurable()
                } else {
                    _ = prepareSelection()
                }
            case .generate:
                _ = try await materialize()
            case .closeSale:
                _ = try await closeSale(in: context)
            }
            guard self.operationRequest?.id == operationRequest.id, !Task.isCancelled else { return }
            if operationRequest.operation != .load || requiresDocumentSelection {
                operationAnnouncementID = UUID()
            }
        } catch {
            guard self.operationRequest?.id == operationRequest.id, !(error is CancellationError),
                  !Task.isCancelled else { return }
            if case let BillingFiscalRecipientError.required(field) = error {
                _ = reject(.required(field))
            } else {
                operationFailed = true
                switch operationRequest.operation {
                case .load, .recoverFamily:
                    recoveryFailed = true
                default:
                    break
                }
                operationAnnouncementID = UUID()
            }
        }
    }

    /// Allows explicit non-UI callers to run their current intention through the same ownership guard.
    func performRequestedOperation(in context: ModelContext) async {
        let captured = operationRequest
        await performRequestedOperation(captured, in: context)
    }

    private func requestOperation(_ operation: BillingOperationRequest.Operation) {
        guard operationRequest == nil, !isBusy else { return }
        operationRequest = BillingOperationRequest(id: UUID(), operation: operation)
    }

    var selectedKind: BillingDocumentKind { request?.kind ?? selection }
    var canSelectKind: Bool {
        guard case .selection = state, preparationIsAvailable(), !isWorking,
              let sale, case .awaitingDocument = sale.status else { return false }
        return isEditing || requiresDocumentSelection
    }
    var isEditing: Bool {
        guard case .selection = state, preparationIsAvailable(), !recoveryFailed, !requiresDocumentSelection,
              !isWorking, !requiresPersistence || hasLoaded,
              let sale, case .awaitingDocument = sale.status else { return false }
        return true
    }

    func fieldValue(_ field: BillingFiscalField) -> String {
        request?.fiscalRecipient?.input[field] ?? fiscalInput[field]
    }

    func selectKind(_ kind: BillingDocumentKind) {
        guard canSelectKind, kind != selection else { return }
        invalidatePrefill()
        selection = kind
        formIssue = nil
        validationID = nil
        if kind == .ticket {
            fiscalInput = BillingFiscalRecipientInput()
            hasEditedInput = false
            hasAttemptedPrefill = false
        }
    }

    func updateField(_ field: BillingFiscalField, value: String) {
        guard isEditing, selection == .invoice, fiscalInput[field] != value else { return }
        invalidatePrefill()
        hasEditedInput = true
        fiscalInput[field] = value
        formIssue = nil
        validationID = nil
    }

    /// Seals one paid snapshot locally; validation preserves editing and never contacts numbering.
    func prepareSelection() -> BillingDocumentRequest? {
        guard !store.requiresPersistence else { return reject(.unavailable) }
        guard preparationIsAvailable(), let sale else { return reject(.unavailable) }
        if case .closed = state {
            return reject(.unavailable)
        }
        if let request {
            return request
        }
        do {
            let prepared = try prepareDocument(
                sale: sale,
                kind: selection,
                recipientInput: selection == .invoice ? fiscalInput : nil
            )
            try prepare(prepared)
            return prepared
        } catch let BillingFiscalRecipientError.required(field) {
            return reject(.required(field))
        } catch {
            return reject(.unavailable)
        }
    }

    /// Caller-owned local prefill cannot replace manual input or publish into a revoked parent session.
    func loadRecipient() async {
        guard isEditing, selection == .invoice, !hasEditedInput, !hasAttemptedPrefill,
              !Task.isCancelled, let id = sale?.clientID, let getClient else { return }
        hasAttemptedPrefill = true
        let generation = UUID()
        prefillGeneration = generation
        isLoadingRecipient = true
        defer {
            if prefillGeneration == generation {
                prefillGeneration = nil
                isLoadingRecipient = false
            }
        }
        do {
            let client = try await getClient(id)
            guard prefillGeneration == generation, !Task.isCancelled, isEditing,
                  selection == .invoice, !hasEditedInput, client.id == id else { return }
            let input = BillingFiscalRecipientInput(
                displayName: client.displayName,
                taxIdentifier: client.taxIdentifier ?? "",
                streetLine: client.billingAddress?.streetLine ?? "",
                postalCode: client.billingAddress?.postalCode ?? "",
                city: client.billingAddress?.city ?? "",
                province: client.billingAddress?.province ?? ""
            )
            if input != fiscalInput {
                fiscalInput = input
                formIssue = nil
                validationID = nil
            }
        } catch {
            // A missing, failed or cancelled optional prefill leaves manual entry available.
        }
    }

    private func reject(_ issue: BillingFormIssue) -> BillingDocumentRequest? {
        formIssue = issue
        validationID = UUID()
        return nil
    }

    private func invalidatePrefill() {
        prefillGeneration = nil
        isLoadingRecipient = false
    }

    var state: BillingDocumentStoreState { store.state }
    var localState: BillingDocumentLocalState? { store.localState }
    var request: BillingDocumentRequest? { store.request }
    var document: BillingDocument? { store.document }
    var delivery: BillingDocumentDelivery? { store.delivery }
    var isBusy: Bool { store.isBusy }
    var canReserve: Bool { store.canReserve }
    var failure: BillingDocumentFailure? { store.failure }

    func prepare(_ request: BillingDocumentRequest) throws {
        try store.prepare(request)
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
    }

    func reserve() async throws -> BillingDocument {
        try await store.reserve()
    }

    /// Explicitly retries the same sealed request; generates no new allocation identity.
    func retry() async throws -> BillingDocument {
        try await store.reserve()
    }

    func prepareDurable(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        try await store.prepareDurable(request)
    }

    /// Discovers the retained sale/family before generating identities, then saves a new paid snapshot if absent.
    /// A reopened facade cannot consume another request ID for an already sealed family.
    func prepareSelectionDurable() async throws -> BillingDocumentDelivery {
        guard preparationIsAvailable(), let sale else { throw BillingDocumentPersistenceError.unauthorized }
        guard !requiresDocumentSelection else { throw BillingDocumentPersistenceError.ambiguousSelection }
        let kind = request?.kind ?? selection
        let input = fiscalInput
        if let retained = try await store.recover(saleID: sale.id, kind: kind) {
            return retained
        }
        guard preparationIsAvailable() else { throw BillingDocumentPersistenceError.unauthorized }
        let request = try prepareDocument(sale: sale, kind: kind, recipientInput: kind == .invoice ? input : nil)
        let delivery = try await store.prepareDurable(request)
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
        return delivery
    }

    func recover(saleID: SaleID, kind: BillingDocumentKind? = nil) async throws -> BillingDocumentDelivery? {
        try await store.recover(saleID: saleID, kind: kind)
    }

    /// Accepts only the captured saved family; an empty or rejected read retains explicit selection for retry.
    private func recoverSelectedFamily(_ kind: BillingDocumentKind) async throws {
        guard requiresDocumentSelection, let sale else { throw BillingDocumentPersistenceError.invalidState }
        guard try await store.recover(
            saleID: sale.id,
            kind: kind,
            validateAcceptance: validateRecoveryAcceptance
        ) != nil else { throw BillingDocumentPersistenceError.notFound }
        try validateRecoveryAcceptance()
        requiresDocumentSelection = false
        recoveryFailed = false
        hasLoaded = true
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
    }

    private func validateRecoveryAcceptance() throws {
        try Task.checkCancellation()
        guard preparationIsAvailable() else { throw BillingDocumentPersistenceError.unauthorized }
    }

    func materialize() async throws -> BillingDocumentDelivery {
        try await store.materialize()
    }

    func cancelReservation() {
        store.cancelReservation()
    }

    func close() {
        operationRequest = nil
        activeOperationID = nil
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
        store.close()
    }

    init(
        reserve: ReserveBillingDocumentUseCase<Repository>,
        materialize: MaterializeBillingDocumentUseCase<Repository>? = nil
    ) {
        store = BillingDocumentStore(reserve: reserve, materialize: materialize)
        sale = nil
        prepareDocument = PrepareBillingDocumentRequestUseCase()
        getClient = nil
        preparationIsAvailable = { false }
        acceptSaleClosure = nil
        now = { .now }
        isDemonstration = false
    }

    /// Creates the facade; initial recovery is an inert intention executed later by the screen's captured task.
    init(
        sale: Sale?,
        reserve: ReserveBillingDocumentUseCase<Repository>,
        prepare: PrepareBillingDocumentRequestUseCase = .init(),
        getClient: GetClientUseCase? = nil,
        materialize: MaterializeBillingDocumentUseCase<Repository>? = nil,
        closeSale: CloseSale? = nil,
        now: @escaping @MainActor @Sendable () -> Date = { .now },
        isDemonstration: Bool = false,
        startsWithRecovery: Bool = false,
        canPrepare: @escaping @MainActor @Sendable () -> Bool = { true }
    ) {
        store = BillingDocumentStore(reserve: reserve, materialize: materialize)
        self.sale = sale
        prepareDocument = prepare
        self.getClient = getClient
        preparationIsAvailable = canPrepare
        acceptSaleClosure = closeSale
        self.now = now
        self.isDemonstration = isDemonstration
        operationRequest = startsWithRecovery ? BillingOperationRequest(id: UUID(), operation: .load) : nil
    }
}
