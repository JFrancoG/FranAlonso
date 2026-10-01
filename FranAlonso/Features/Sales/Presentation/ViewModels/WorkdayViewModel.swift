import Foundation
import Observation

/// Coordinates the operational board and independent detail sessions over the local sale source.
@Observable @MainActor
final class WorkdayViewModel {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case content(WorkdaySales)
        case failed
        case closed
    }

    private(set) var state: State = .idle
    private(set) var destination: SaleDraftDestination?
    private(set) var lastError: (any Error)?
    private let observeSales: ObserveSalesUseCase
    private let policy = WorkdaySalesPolicy()
    private let makeID: @MainActor () -> UUID
    @ObservationIgnored private var observationGeneration: UUID?

    var selectedSaleID: SaleID? {
        guard let destination, destination.mode != .create else { return nil }
        return destination.saleID
    }

    /// Reserves one sale and presentation identity until the create session is dismissed.
    func beginCreatingSale() {
        guard state != .closed, destination == nil else { return }
        destination = SaleDraftDestination(id: makeID(), saleID: SaleID(rawValue: makeID()), mode: .create)
    }

    /// Opens only a currently visible operation, granting editing exclusively to drafts.
    func openSale(_ id: SaleID) {
        guard destination == nil, case let .content(board) = state,
              let sale = board.sales.first(where: { $0.id == id }) else { return }
        destination = SaleDraftDestination(
            id: makeID(),
            saleID: id,
            mode: policy.category(of: sale) == .upcoming ? .editDraft : .inspect
        )
    }

    /// A delayed dismissal from a previous presentation cannot dismiss its replacement.
    func finishSession(_ sessionID: UUID) {
        guard destination?.id == sessionID else { return }
        destination = nil
    }

    /// Observes for the caller's task lifetime; replaced observations cannot publish values, failures or completion.
    /// Cancellation returns to idle, valid completion without values becomes empty, and close is terminal.
    func load() async {
        guard state != .closed else { return }
        let generation = UUID()
        observationGeneration = generation
        state = .loading
        lastError = nil

        do {
            try Task.checkCancellation()
            let stream = await observeSales()
            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false
            for try await sales in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                let board = policy(sales)
                state = board.isEmpty ? .empty : .content(board)
                reconcileDestination(with: board)
            }
            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                state = .empty
                reconcileDestination(with: policy([]))
            }
        } catch {
            guard observationGeneration == generation else { return }
            if error is CancellationError || Task.isCancelled {
                state = .idle
            } else {
                lastError = error
                state = .failed
            }
        }
    }

    /// Fences caller-owned work and ends navigation without owning or cancelling task handles.
    func close() {
        observationGeneration = nil
        destination = nil
        lastError = nil
        state = .closed
    }

    private func reconcileDestination(with board: WorkdaySales) {
        guard let destination, destination.mode != .create else { return }
        guard let sale = board.sales.first(where: { $0.id == destination.saleID }) else {
            self.destination = nil
            return
        }
        let mode: SaleDraftDestination.Mode = policy.category(of: sale) == .upcoming ? .editDraft : .inspect
        if destination.mode != mode {
            self.destination = nil
        }
    }

    init(
        observe: ObserveSalesUseCase,
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        observeSales = observe
        self.makeID = makeID
    }
}
