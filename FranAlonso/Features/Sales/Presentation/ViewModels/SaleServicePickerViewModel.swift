import Foundation
import Observation

/// Coordinates a caller-owned service selection with the retained parent draft's acceptance capability.
@Observable @MainActor
final class SaleServicePickerViewModel {
    enum SelectionState: Equatable {
        case idle
        case requested(UUID, SaleLine)
        case adding(UUID, SaleLine)
        case failed(SaleLine)
        case unavailable
        case accepted
        case closed
    }

    let picker: ServicePickerViewModel
    private(set) var selectionState: SelectionState = .idle
    private(set) var observationRequestID: UUID? = UUID()
    private let canAdd: @MainActor @Sendable () -> Bool
    private let addLine: @MainActor @Sendable (SaleLine) async throws -> Void
    private let makeLineID: @MainActor @Sendable () -> SaleLineID

    /// Retains the task identity while submission starts so `.task(id:)` does not cancel its own accepted write.
    var selectionRequestID: UUID? {
        switch selectionState {
        case let .requested(id, _), let .adding(id, _): id
        default: nil
        }
    }

    var isBusy: Bool { selectionRequestID != nil }
    var canSelectServices: Bool {
        guard selectionState != .closed, !hasAcceptedSelection, !isBusy, canAdd() else { return false }
        if case .content = picker.state {
            return true
        }
        return false
    }
    var hasSelectionError: Bool {
        if case .failed = selectionState {
            return true
        }
        return false
    }
    var isSelectionUnavailable: Bool { selectionState == .unavailable }
    var hasAcceptedSelection: Bool { selectionState == .accepted }

    /// Captures the latest visible service synchronously before any acceptance task can suspend.
    /// Busy and terminal sessions ignore duplicate intentions; unavailable choices never reach the parent draft.
    func requestSelection(id: ServiceID) {
        guard selectionState != .closed, !hasAcceptedSelection, !isBusy else { return }
        guard canAdd(), let service = picker.selectService(id: id) else {
            selectionState = .unavailable
            return
        }
        do {
            let line = try SaleLine.capturing(service: service, id: makeLineID())
            selectionState = .requested(UUID(), line)
        } catch {
            selectionState = .unavailable
        }
    }

    /// Starts another caller-owned task for the same frozen line after a preacceptance failure.
    /// A retry never reloads commercial terms or creates another line identity.
    func retrySelection() {
        guard case let .failed(line) = selectionState else { return }
        guard canAdd() else {
            selectionState = .unavailable
            return
        }
        selectionState = .requested(UUID(), line)
    }

    /// Delegates acceptance once; durable success remains success even when the caller was later cancelled.
    /// Close fences publication without undoing a parent write.
    /// Only a still-active preacceptance failure permits retry.
    func submitSelection() async {
        guard case let .requested(requestID, line) = selectionState else { return }
        selectionState = .adding(requestID, line)
        do {
            try Task.checkCancellation()
            guard canAdd() else {
                selectionState = .unavailable
                return
            }
            try await addLine(line)
            guard selectionRequestID == requestID else { return }
            selectionState = .accepted
        } catch {
            guard selectionRequestID == requestID else { return }
            selectionState = error is CancellationError || Task.isCancelled ? .idle : .failed(line)
        }
    }

    /// Uses the existing catalogue ViewModel's caller-owned observation independently of submission.
    func loadCatalogue() async {
        guard observationRequestID != nil, selectionState != .closed else { return }
        await picker.load()
    }

    /// Requests a new observation while preserving filters and any frozen acceptance intention.
    func reloadCatalogue() {
        guard selectionState != .closed else { return }
        observationRequestID = UUID()
    }

    /// Ends only selector publication; the screen cancels its tasks and the accepted parent draft remains alive.
    func close() {
        observationRequestID = nil
        selectionState = .closed
    }

    init(
        picker: ServicePickerViewModel,
        canAdd: @escaping @MainActor @Sendable () -> Bool,
        addLine: @escaping @MainActor @Sendable (SaleLine) async throws -> Void,
        makeLineID: @escaping @MainActor @Sendable () -> SaleLineID = { SaleLineID(rawValue: UUID()) }
    ) {
        self.picker = picker
        self.canAdd = canAdd
        self.addLine = addLine
        self.makeLineID = makeLineID
    }
}
