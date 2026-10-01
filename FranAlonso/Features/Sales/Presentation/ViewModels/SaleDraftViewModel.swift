import Foundation
import Observation

/// A presentation mode cannot gain editing capability from a later repository snapshot.
enum SaleDraftViewModelError: Error, Equatable {
    case readOnly
    case closed
    case invalidMode
}

/// Projects one accepted draft Store and owns the separate read-only operational inspection session.
@Observable @MainActor
final class SaleDraftViewModel {
    enum InspectionState: Equatable {
        case idle
        case loading
        case content(Sale, SaleCalculation)
        case unavailable
        case failed
        case closed
    }

    let destination: SaleDraftDestination
    private(set) var inspectionState: InspectionState = .idle
    private let store: SaleDraftStore
    private let getSale: GetSaleUseCase
    private let createdAt: Date
    private let policy = WorkdaySalesPolicy()
    private let calculator = SaleCalculator()
    private var inspectionError: (any Error)?
    @ObservationIgnored private var inspectionGeneration: UUID?

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
    var isBusy: Bool { isReadOnly ? inspectionState == .loading : store.isBusy }
    var isReadOnly: Bool { destination.mode == .inspect }
    var isClosed: Bool { store.state == .closed }

    /// Loads editable content through the one Store, or reads operational content without granting mutation capability.
    /// Create sessions load no snapshot; their stable identity and timestamp are used only by explicit creation.
    /// - Throws: Draft rejection, read/calculation failure, cancellation, or a closed presentation session.
    func load() async throws -> Sale? {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        switch destination.mode {
        case .create:
            return store.draft
        case .editDraft:
            return try await store.load(id: destination.saleID)
        case .inspect:
            return try await inspect()
        }
    }

    /// Uses the session's fixed identity and creation time across local failures and retries.
    /// - Throws: A mode/session rejection or Store validation and local acceptance errors.
    func create(clientID: ClientID? = nil, lines: [SaleLine] = []) async throws -> Sale {
        try requireEditable()
        guard destination.mode == .create else { throw SaleDraftViewModelError.invalidMode }
        return try await store.create(
            id: destination.saleID,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines
        )
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

    /// Discards only through the Store's durable draft contract.
    /// - Throws: A mode/session rejection or the Store's preacceptance failure.
    func discard() async throws {
        try requireEditable()
        try await store.discard()
    }

    /// Ends presentation, fences late inspection reads and closes the Store without discarding accepted data.
    func close() {
        inspectionGeneration = nil
        inspectionError = nil
        inspectionState = .closed
        store.close()
    }

    private func requireEditable() throws {
        guard !isClosed else { throw SaleDraftViewModelError.closed }
        guard !isReadOnly else { throw SaleDraftViewModelError.readOnly }
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
            let calculation = try calculator.calculate(lines: recovered.lines, currency: store.currency)
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
        getSale: GetSaleUseCase
    ) {
        self.destination = destination
        self.createdAt = createdAt
        self.getSale = getSale
        store = SaleDraftStore(
            currency: currency,
            create: create,
            get: getDraft,
            update: update,
            discard: discard
        )
    }
}
