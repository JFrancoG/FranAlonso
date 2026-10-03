import Foundation
import Observation

/// One allocation snapshot and its presentation lifecycle, never a second numbering authority.
enum BillingDocumentStoreState: Equatable {
    case selection
    case allocation(BillingDocumentLocalState)
    case reserving(BillingDocumentRequest)
    case closed(BillingDocumentLocalState?)
}

/// Rejected session intentions leave the prepared allocation unchanged.
enum BillingDocumentStoreError: Error, Equatable {
    case operationInProgress, noRequest, requestAlreadyPrepared, closed
}

/// Owns one immutable request; callers own the structured tasks that attempt its reservation.
@Observable @MainActor
final class BillingDocumentStore<Repository: BillingDocumentReservationRepository> {
    private(set) var state: BillingDocumentStoreState = .selection
    private let reserveDocument: ReserveBillingDocumentUseCase<Repository>
    @ObservationIgnored private var operationGeneration: UUID?

    var localState: BillingDocumentLocalState? {
        switch state {
        case .selection: nil
        case let .allocation(allocation): allocation
        case let .reserving(request): .pendingNumber(request)
        case let .closed(retained): retained
        }
    }

    var request: BillingDocumentRequest? { localState?.request }
    var document: BillingDocument? { localState?.document }

    var isBusy: Bool {
        guard case .reserving = state else { return false }
        return true
    }

    var canReserve: Bool {
        guard case let .allocation(allocation) = state else { return false }
        return allocation.document == nil
    }

    var failure: BillingDocumentFailure? {
        guard case let .failed(_, reason) = localState else { return nil }
        return reason
    }

    /// Seals a validated paid request without generating identities or contacting its authority.
    /// Repeating the same request preserves pending, failed or confirmed allocation.
    /// - Throws: A session rejection for a closed/busy session or replacement of its sealed request.
    func prepare(_ request: BillingDocumentRequest) throws {
        if case .closed = state {
            throw BillingDocumentStoreError.closed
        }
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
        if case .closed = state {
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
        guard case let .reserving(request) = state else { return }
        operationGeneration = nil
        state = .allocation(.pendingNumber(request))
    }

    /// Ends presentation, retaining allocation for its owner; never closes a sale.
    /// Repeating close is a no-op; a new presentation must recover through its retained request.
    func close() {
        if case .closed = state {
            return
        }
        let retained = localState
        operationGeneration = nil
        state = .closed(retained)
    }

    init(reserve: ReserveBillingDocumentUseCase<Repository>) {
        reserveDocument = reserve
    }
}
