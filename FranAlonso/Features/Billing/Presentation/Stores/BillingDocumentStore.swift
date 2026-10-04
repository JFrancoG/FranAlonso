import Foundation
import Observation

/// One allocation snapshot and its presentation lifecycle, never a second numbering authority.
enum BillingDocumentStoreState: Equatable {
    case selection
    case allocation(BillingDocumentLocalState)
    case reserving(BillingDocumentRequest)
    case closed(BillingDocumentLocalState?)
    case materialization(BillingDocumentDelivery?, activity: BillingMaterializationActivity)
}

enum BillingMaterializationActivity: Equatable {
    case ready, busy, closed
    case closing
    case accepted(Sale)
}

/// Rejected session intentions leave the prepared allocation unchanged.
enum BillingDocumentStoreError: Error, Equatable {
    case operationInProgress, noRequest, requestAlreadyPrepared, closed, persistenceRequired
}

/// Owns one immutable request; callers own the structured tasks that attempt its reservation.
@Observable @MainActor
final class BillingDocumentStore<Repository: BillingDocumentReservationRepository> {
    private(set) var state: BillingDocumentStoreState = .selection
    private let reserveDocument: ReserveBillingDocumentUseCase<Repository>
    private let materializeDocument: MaterializeBillingDocumentUseCase<Repository>?
    @ObservationIgnored private var operationGeneration: UUID?

    var localState: BillingDocumentLocalState? {
        switch state {
        case .selection: nil
        case let .allocation(allocation): allocation
        case let .reserving(request): .pendingNumber(request)
        case let .closed(retained): retained
        case let .materialization(delivery, _): delivery?.allocation
        }
    }

    var request: BillingDocumentRequest? { localState?.request }
    var document: BillingDocument? { localState?.document }
    var requiresPersistence: Bool { materializeDocument != nil }
    var delivery: BillingDocumentDelivery? {
        guard case let .materialization(delivery, _) = state else { return nil }
        return delivery
    }

    /// Saves or recovers the same sealed request before exposing durable presentation.
    func prepareDurable(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        if let prepared = self.request {
            guard prepared == request else { throw BillingDocumentStoreError.requestAlreadyPrepared }
        }
        guard let delivery = try await runDurable(recoverID: request.id, operation: { engine in
            try await engine.prepare(request)
        }) else { throw BillingDocumentPersistenceError.invalidState }
        return delivery
    }

    /// Reads an authorized checkpoint without contacting numbering, rendering or Storage.
    func recover(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        if let prepared = request {
            guard prepared.id == id else { throw BillingDocumentStoreError.requestAlreadyPrepared }
        }
        return try await runDurable(recoverID: id) { engine in
            try await engine.delivery(id: id)
        }
    }

    /// Finds a retained sale family; an ambiguous discovery requires an explicit kind.
    /// The caller's acceptance gate is revalidated before publishing successful or fallback rereads.
    func recover(
        saleID: SaleID,
        kind: BillingDocumentKind? = nil,
        validateAcceptance: @MainActor () throws -> Void = {}
    ) async throws -> BillingDocumentDelivery? {
        if let prepared = request {
            guard prepared.sale.id == saleID, kind == nil || prepared.kind == kind else {
                throw BillingDocumentStoreError.requestAlreadyPrepared
            }
        }
        return try await runDurable(validateAcceptance: validateAcceptance) { engine in
            let deliveries = try await engine.deliveries(saleID: saleID)
                .filter { kind == nil || $0.request.kind == kind }
            guard deliveries.count <= 1 else { throw BillingDocumentPersistenceError.ambiguousSelection }
            return deliveries.first
        }
    }

    /// Publishes only the saved local receipt; generation revocation cannot undo an authorized durable commit.
    func materialize() async throws -> BillingDocumentDelivery {
        guard !isClosed else { throw BillingDocumentStoreError.closed }
        guard let id = request?.id else { throw BillingDocumentStoreError.noRequest }
        guard let delivery = try await runDurable(recoverID: id, operation: { engine in
            try await engine(id)
        }) else { throw BillingDocumentPersistenceError.notFound }
        return delivery
    }

    var isBusy: Bool {
        if case let .materialization(_, activity) = state {
            return activity == .busy || activity == .closing
        }
        guard case .reserving = state else { return false }
        return true
    }

    var canReserve: Bool {
        if case let .materialization(delivery, .ready) = state {
            return delivery?.document == nil && delivery != nil
        }
        guard case let .allocation(allocation) = state else { return false }
        return allocation.document == nil
    }

    var failure: BillingDocumentFailure? {
        if let delivery {
            return delivery.failure?.reason
        }
        guard case let .failed(_, reason) = localState else { return nil }
        return reason
    }

    var closedSale: Sale? {
        guard case let .materialization(_, .accepted(sale)) = state else { return nil }
        return sale
    }

    /// Accepts one explicit closure without invoking any billing motor or retaining a caller context.
    func closeSale(
        _ request: SaleClosureRequest,
        accepting operation: @MainActor () async throws -> Sale
    ) async throws -> Sale {
        guard let retained = delivery, retained.document != nil, retained.pdf != nil else {
            throw SaleClosureError.documentPending
        }
        guard request.expected == retained.request.sale, request.requestID == retained.id else {
            throw SaleClosureError.staleSale
        }
        if let accepted = closedSale {
            return accepted
        }
        guard !isClosed else { throw BillingDocumentStoreError.closed }
        guard !isBusy else { throw BillingDocumentStoreError.operationInProgress }
        let generation = UUID()
        operationGeneration = generation
        state = .materialization(retained, activity: .closing)
        defer {
            if operationGeneration == generation {
                operationGeneration = nil
                if case .materialization(_, .closing) = state {
                    state = .materialization(retained, activity: .ready)
                }
            }
        }
        do {
            try Task.checkCancellation()
            let accepted = try await operation()
            try Task.checkCancellation()
            guard operationGeneration == generation else { throw CancellationError() }
            let validated = try SaleClosureAcceptancePolicy()(
                request,
                current: accepted,
                delivery: retained,
                principalID: retained.principalID
            )
            guard validated == accepted else { throw SaleClosureError.invalidDocument }
            state = .materialization(retained, activity: .accepted(accepted))
            return accepted
        } catch {
            guard operationGeneration == generation else { throw CancellationError() }
            state = .materialization(retained, activity: .ready)
            throw error
        }
    }

    /// Seals a validated paid request without generating identities or contacting its authority.
    /// Repeating the same request preserves pending, failed or confirmed allocation.
    /// - Throws: A session rejection for a closed/busy session or replacement of its sealed request.
    func prepare(_ request: BillingDocumentRequest) throws {
        if isClosed {
            throw BillingDocumentStoreError.closed
        }
        guard materializeDocument == nil else { throw BillingDocumentStoreError.persistenceRequired }
        guard !isBusy else { throw BillingDocumentStoreError.operationInProgress }
        if let prepared = self.request {
            guard prepared == request else { throw BillingDocumentStoreError.requestAlreadyPrepared }
            return
        }
        state = .allocation(.pendingNumber(request))
    }

    /// Makes one explicit attempt; cancellation retains the complete request for recovery.
    ///
    /// Confirmed allocation is returned without contacting its authority again. Errors and
    /// cancellation may follow a remote commit; retrying preserves every request field.
    /// Caller tasks own cancellation. A revoked generation cannot publish or clean up a
    /// later attempt, even when the provider ignores cancellation or returns a late error.
    /// - Throws: A session rejection, neutral reservation failure or native cancellation.
    func reserve() async throws -> BillingDocument {
        guard !isClosed else { throw BillingDocumentStoreError.closed }
        if materializeDocument != nil {
            guard let id = request?.id else { throw BillingDocumentStoreError.noRequest }
            let delivery = try await runDurable(recoverID: id) { engine in
                try await engine.reserveNumber(id: id)
            }
            guard let document = delivery?.document else { throw BillingDocumentPersistenceError.invalidState }
            return document
        }
        if isClosed {
            throw BillingDocumentStoreError.closed
        }
        guard !isBusy else { throw BillingDocumentStoreError.operationInProgress }
        guard case let .allocation(allocation) = state else { throw BillingDocumentStoreError.noRequest }
        if let confirmed = allocation.document {
            try Task.checkCancellation()
            return confirmed
        }
        let request = allocation.request
        let generation = UUID()
        operationGeneration = generation
        state = .reserving(request)
        defer {
            if operationGeneration == generation {
                operationGeneration = nil
            }
        }
        do {
            try Task.checkCancellation()
            let document = try await reserveDocument(request)
            try Task.checkCancellation()
            guard operationGeneration == generation else { throw CancellationError() }
            var accepted = BillingDocumentLocalState.pendingNumber(request)
            try accepted.accept(document)
            state = .allocation(accepted)
            return document
        } catch {
            guard operationGeneration == generation else { throw CancellationError() }
            if error is CancellationError || Task.isCancelled {
                state = .allocation(.pendingNumber(request))
                throw CancellationError()
            }
            let failure = error as? BillingDocumentReservationError ?? .unavailable
            let reason: BillingDocumentFailure = switch failure {
            case .permissionDenied: .permissionDenied
            case .conflict: .conflict
            case .unavailable, .invalidResponse: .unavailable
            }
            state = .allocation(.failed(request, reason: reason))
            throw failure
        }
    }

    /// Revokes publication without claiming to cancel caller work or roll back a remote commit.
    /// Pending/failed/confirmed snapshots remain unchanged when no attempt is active.
    func cancelReservation() {
        if case let .materialization(delivery, activity) = state, activity == .busy || activity == .closing {
            operationGeneration = nil
            state = delivery.map { .materialization($0, activity: .ready) } ?? .selection
            return
        }
        guard case let .reserving(request) = state else { return }
        operationGeneration = nil
        state = .allocation(.pendingNumber(request))
    }

    /// Ends presentation, retaining allocation for its owner; never closes a sale.
    /// Repeating close is a no-op; a new presentation must recover through its retained request.
    func close() {
        if isClosed {
            return
        }
        if materializeDocument != nil {
            operationGeneration = nil
            state = .materialization(delivery, activity: .closed)
            return
        }
        let retained = localState
        operationGeneration = nil
        state = .closed(retained)
    }

    init(
        reserve: ReserveBillingDocumentUseCase<Repository>,
        materialize: MaterializeBillingDocumentUseCase<Repository>? = nil
    ) {
        reserveDocument = reserve
        materializeDocument = materialize
    }
}

private extension BillingDocumentStore {
    var isClosed: Bool {
        switch state {
        case .closed, .materialization(_, .closed), .materialization(_, .accepted): true
        default: false
        }
    }

    func runDurable(
        recoverID: BillingDocumentRequestID? = nil,
        validateAcceptance: @MainActor () throws -> Void = {},
        operation: (MaterializeBillingDocumentUseCase<Repository>) async throws -> BillingDocumentDelivery?
    ) async throws -> BillingDocumentDelivery? {
        guard !isClosed else { throw BillingDocumentStoreError.closed }
        guard !isBusy else { throw BillingDocumentStoreError.operationInProgress }
        guard let materializeDocument else { throw BillingDocumentStoreError.persistenceRequired }
        let retained = delivery
        let generation = UUID()
        operationGeneration = generation
        state = .materialization(retained, activity: .busy)
        defer {
            if operationGeneration == generation {
                operationGeneration = nil
                if case .materialization(_, .busy) = state {
                    state = retained.map { .materialization($0, activity: .ready) } ?? .selection
                }
            }
        }
        do {
            try validateAcceptance()
            let recovered = try await operation(materializeDocument)
            try Task.checkCancellation()
            try validateAcceptance()
            guard operationGeneration == generation else { throw CancellationError() }
            if let retained, let recovered {
                guard retained.request == recovered.request else {
                    throw BillingDocumentStoreError.requestAlreadyPrepared
                }
            }
            state = recovered.map { .materialization($0, activity: .ready) } ?? .selection
            return recovered
        } catch {
            guard operationGeneration == generation else { throw CancellationError() }
            if error is CancellationError || Task.isCancelled {
                state = retained.map { .materialization($0, activity: .ready) } ?? .selection
                throw CancellationError()
            }
            var recovered = retained
            if let id = recoverID ?? retained?.id {
                try validateAcceptance()
                if let latest = try? await materializeDocument.delivery(id: id) {
                    try validateAcceptance()
                    recovered = latest
                }
                try validateAcceptance()
            }
            try Task.checkCancellation()
            try validateAcceptance()
            guard operationGeneration == generation else { throw CancellationError() }
            state = recovered.map { .materialization($0, activity: .ready) } ?? .selection
            throw error
        }
    }
}
