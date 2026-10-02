import Foundation
import Observation

/// One accepted draft and its monetary projection, published as a single observable value.
enum SaleDraftStoreState: Equatable {
    case idle
    case editing(Sale, SaleCalculation)
    case discarded(SaleID)
    case closed
}

/// Advisory inventory projection, independent of the accepted monetary snapshot.
enum SaleDraftStockState: Equatable {
    case idle
    case loading
    case ready([StockImpact])
    case failed
}

/// A physical draft requires an explicit quantity reader; absence never implies sufficient stock.
enum SaleDraftStockError: Error, Equatable {
    case readerUnavailable
}

/// The exclusive local operation currently owned by the draft session.
enum SaleDraftStoreOperation: Equatable {
    case create
    case load
    case update
    case discard
}

/// A rejected presentation-session intention, separate from commercial Domain errors.
enum SaleDraftStoreError: Error, Equatable {
    case operationInProgress
    case noDraft
    case draftAlreadyLoaded
    case closed
}

/// Owns the accepted draft session; callers own the structured tasks that invoke its intentions.
@Observable @MainActor
final class SaleDraftStore {
    let currency: Currency
    private(set) var state: SaleDraftStoreState = .idle
    private(set) var operation: SaleDraftStoreOperation?
    private(set) var lastError: (any Error)?
    private(set) var stockState: SaleDraftStockState = .idle
    private(set) var stockError: (any Error)?
    private let getStock: GetSaleStockQuantitiesUseCase?
    private let analyzeStock = AnalyzeSaleStockImpactUseCase()
    private let createDraft: CreateSaleDraftUseCase
    private let getDraft: GetSaleDraftUseCase
    private let updateDraft: UpdateSaleDraftUseCase
    private let discardDraft: DiscardSaleDraftUseCase
    private let editingPolicy = SaleDraftEditingPolicy()
    private let calculator = SaleCalculator()
    @ObservationIgnored private var operationGeneration: UUID?

    @ObservationIgnored private var stockGeneration: UUID?

    var draft: Sale? {
        guard case let .editing(draft, _) = state else { return nil }
        return draft
    }

    var calculation: SaleCalculation? {
        guard case let .editing(_, calculation) = state else { return nil }
        return calculation
    }

    var isBusy: Bool { operation != nil }

    /// Calculates a new draft before local acceptance.
    /// Accepted writes retain success even after cancellation or close.
    /// - Throws: A session rejection, Domain validation/calculation error, repository error
    ///   or preacceptance cancellation.
    func create(
        id: SaleID,
        clientID: ClientID?,
        createdAt: Date,
        lines: [SaleLine]
    ) async throws -> Sale {
        try await perform(.create) { generation in
            guard draft == nil else { throw SaleDraftStoreError.draftAlreadyLoaded }
            let candidate = try Sale.draft(
                id: id,
                clientID: clientID,
                createdAt: createdAt,
                lines: lines
            )
            let calculation = try calculator.calculate(sale: candidate, currency: currency)
            let accepted = try await createDraft(
                id: id,
                clientID: clientID,
                createdAt: createdAt,
                lines: lines
            )
            publish(accepted, calculation: calculation, generation: generation)
            await refreshStock()
            return accepted
        }
    }

    /// Recovers and recalculates a draft. Valid absence clears the projection; invalid or cancelled reads retain it.
    /// - Throws: Domain/repository errors, cancellation, or session rejection. A late read after close is cancelled.
    func load(id: SaleID) async throws -> Sale? {
        try await perform(.load) { generation in
            let recovered = try await getDraft(id: id)
            try Task.checkCancellation()
            guard operationGeneration == generation else { throw CancellationError() }
            guard let recovered else {
                clearStock()
                state = .idle
                return nil
            }
            let calculation = try calculator.calculate(sale: recovered, currency: currency)
            publish(recovered, calculation: calculation, generation: generation)
            await refreshStock()
            return recovered
        }
    }

    /// Accepts an appended captured line without merging repeated services.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func addLine(_ line: SaleLine) async throws -> Sale {
        try await edit { try editingPolicy.adding(line, to: $0) }
    }

    /// Accepts removal by stable line identity; a missing line is rejected.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func removeLine(id: SaleLineID) async throws -> Sale {
        try await edit { try editingPolicy.removing(id: id, from: $0) }
    }

    /// Accepts a quantity change while preserving the line's captured terms.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func setQuantity(_ quantity: Int, for id: SaleLineID) async throws -> Sale {
        try await edit { try editingPolicy.settingQuantity(quantity, for: id, in: $0) }
    }

    /// Accepts association or removal of a client without changing captured lines.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func setClient(_ id: ClientID?) async throws -> Sale {
        try await edit { try editingPolicy.settingClient(id, in: $0) }
    }

    /// Accepts a validated line discount or its removal while retaining the global term.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func setDiscount(_ discount: Discount?, for id: SaleLineID) async throws -> Sale {
        try await edit { try editingPolicy.settingDiscount(discount, for: id, in: $0) }
    }

    /// Accepts an independent sale-wide discount or its removal through the common edit boundary.
    /// - Throws: Session, Domain/calculation or local acceptance errors; prior accepted content remains on failure.
    func setGlobalDiscount(_ discount: Discount?) async throws -> Sale {
        try await edit { try editingPolicy.settingGlobalDiscount(discount, in: $0) }
    }

    /// Accepts a durable discard and clears the projection. Repeating an accepted discard has no additional effect.
    /// - Throws: Session or local acceptance errors. Cancellation after acceptance does not turn success into failure.
    func discard() async throws {
        try await perform(.discard) { generation in
            if case .discarded = state {
                return
            }
            guard let draft else { throw SaleDraftStoreError.noDraft }
            try await discardDraft(draft.id)
            guard operationGeneration == generation else { return }
            clearStock()
            state = .discarded(draft.id)
        }
    }

    /// Terminates presentation and fences late results without cancelling caller tasks or undoing accepted writes.
    func close() {
        operationGeneration = nil
        operation = nil
        lastError = nil
        clearStock()
        state = .closed
    }

    private func edit(
        _ candidate: @MainActor (Sale) throws -> Sale
    ) async throws -> Sale {
        try await perform(.update) { generation in
            guard let expected = draft else { throw SaleDraftStoreError.noDraft }
            let edited = try candidate(expected)
            let calculation = try calculator.calculate(sale: edited, currency: currency)
            let accepted = try await updateDraft(
                expected,
                clientID: edited.clientID,
                lines: edited.lines,
                globalDiscount: edited.globalDiscount
            )
            publish(accepted, calculation: calculation, generation: generation)
            await refreshStock()
            return accepted
        }
    }

    private func publish(_ draft: Sale, calculation: SaleCalculation, generation: UUID) {
        guard operationGeneration == generation else { return }
        clearStock()
        state = .editing(draft, calculation)
    }

    /// Refreshes advisory stock in the caller's task; the latest request for the accepted draft wins.
    /// Failure or cancellation never revokes an accepted sale or changes its acceptance error.
    func refreshStock() async {
        guard let captured = draft else { return }
        let generation = UUID()
        stockGeneration = generation
        stockError = nil
        stockState = .loading
        do {
            try Task.checkCancellation()
            let quantities: [ProductID: Int]
            if captured.lines.contains(where: { $0.linkedProductID != nil }) {
                guard let getStock else { throw SaleDraftStockError.readerUnavailable }
                quantities = try await getStock(lines: captured.lines)
            } else {
                quantities = [:]
            }
            try Task.checkCancellation()
            guard stockGeneration == generation, draft == captured else { return }
            let impacts = try analyzeStock(lines: captured.lines, availableQuantities: quantities)
            stockState = .ready(impacts)
        } catch {
            guard stockGeneration == generation, draft == captured else { return }
            if error is CancellationError || Task.isCancelled {
                stockState = .idle
                stockError = nil
            } else {
                stockError = error
                stockState = .failed
            }
        }
    }

    private func clearStock() {
        stockGeneration = nil
        stockState = .idle
        stockError = nil
    }

    private func perform<Result>(
        _ activity: SaleDraftStoreOperation,
        body: @MainActor (UUID) async throws -> Result
    ) async throws -> Result {
        guard state != .closed else { throw SaleDraftStoreError.closed }
        guard operation == nil else { throw SaleDraftStoreError.operationInProgress }
        let generation = UUID()
        operationGeneration = generation
        operation = activity
        lastError = nil
        defer {
            if operationGeneration == generation {
                operationGeneration = nil
                operation = nil
            }
        }
        do {
            try Task.checkCancellation()
            return try await body(generation)
        } catch {
            if operationGeneration == generation, !(error is CancellationError) {
                lastError = error
            }
            throw error
        }
    }

    init(
        currency: Currency,
        create: CreateSaleDraftUseCase,
        get: GetSaleDraftUseCase,
        update: UpdateSaleDraftUseCase,
        discard: DiscardSaleDraftUseCase,
        getStock: GetSaleStockQuantitiesUseCase? = nil
    ) {
        self.getStock = getStock
        self.currency = currency
        createDraft = create
        getDraft = get
        updateDraft = update
        discardDraft = discard
    }
}
