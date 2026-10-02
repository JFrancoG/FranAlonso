import Foundation
import Observation
import Testing
@testable import FranAlonso

@Suite("Workday ViewModel concurrency", .timeLimit(.minutes(1)))
@MainActor
struct WorkdayViewModelConcurrencyTests {
    @Test(arguments: [WorkdayViewModelObsoleteEvent.snapshot, .failure, .completion])
    func `replaced live observations cannot change the current board selection or error`(
        _ event: WorkdayViewModelObsoleteEvent
    ) async throws {
        let previous = try viewModelSale(index: 10)
        let current = try viewModelSale(index: 11, stage: .awaitingDocument)
        let pair = AsyncThrowingStream<[Sale], any Error>.makeStream()
        let entered = WorkdayViewModelCheckpoint()
        let repository = WorkdayViewModelControlledRepository(plans: [
            WorkdayViewModelStreamPlan(stream: pair.stream, entered: entered),
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([current]))
        ])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        let obsolete = Task {
            await model.load()
        }
        await entered.waitForEntry()
        await workdayViewModelPublish(previous, to: model, through: pair.continuation)
        model.openSale(previous.id)
        #expect(model.selectedSaleID == previous.id)

        await model.load()
        model.openSale(current.id)
        let session = model.destination
        switch event {
        case .snapshot:
            pair.continuation.yield([previous])
            pair.continuation.finish()
        case .failure:
            pair.continuation.finish(throwing: SaleDraftError.persistenceUnavailable)
        case .completion:
            pair.continuation.finish()
        }
        await obsolete.value

        guard case let .content(board) = model.state else {
            Issue.record("A completed replacement observation must retain its operational snapshot")
            return
        }
        #expect(board.sales.map(\.id) == [current.id])
        #expect(board.awaitingClosure.map(\.id) == [current.id])
        #expect(model.selectedSaleID == current.id)
        #expect(model.destination == session)
        #expect(model.destination?.mode == .inspect)
        #expect(model.lastError == nil)
        #expect(await repository.observationCount == 2)
    }

    @Test
    func `an observation returned after replacement cannot overwrite the newer session`() async throws {
        let previous = try viewModelSale(index: 12)
        let current = try viewModelSale(index: 13)
        let checkpoint = WorkdayViewModelCheckpoint()
        let repository = WorkdayViewModelControlledRepository(plans: [
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([previous]), hold: checkpoint),
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([current]))
        ])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        let obsolete = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        await model.load()
        model.openSale(current.id)
        let session = model.destination
        await checkpoint.release()
        await obsolete.value

        guard case let .content(board) = model.state else {
            Issue.record("An obsolete stream acquisition must not replace the current board")
            return
        }
        #expect(board.sales.map(\.id) == [current.id])
        #expect(model.destination == session)
        #expect(model.selectedSaleID == current.id)
        #expect(model.lastError == nil)
    }

    @Test
    func `close fences late observation acquisition and ends every navigation intention`() async throws {
        let sale = try viewModelSale(index: 14)
        let checkpoint = WorkdayViewModelCheckpoint()
        let repository = WorkdayViewModelControlledRepository(plans: [
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([sale]), hold: checkpoint)
        ])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        model.beginCreatingSale()
        let loading = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        model.close()
        await checkpoint.release()
        await loading.value
        await model.load()
        model.beginCreatingSale()
        model.openSale(sale.id)

        #expect(model.state == .closed)
        #expect(model.destination == nil)
        #expect(model.selectedSaleID == nil)
        #expect(model.lastError == nil)
        #expect(await repository.observationCount == 1)
    }

    @Test
    func `cancelled observation acquisition returns to idle and explicit retry consumes a fresh stream`() async throws {
        let previous = try viewModelSale(index: 15)
        let current = try viewModelSale(index: 16, stage: .inProgress)
        let checkpoint = WorkdayViewModelCheckpoint()
        let repository = WorkdayViewModelControlledRepository(plans: [
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([previous]), hold: checkpoint),
            WorkdayViewModelStreamPlan(stream: workdayViewModelStream([current]))
        ])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        let cancelled = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        cancelled.cancel()
        await checkpoint.release()
        await cancelled.value
        #expect(model.state == .idle)
        #expect(model.lastError == nil)
        await model.load()

        guard case let .content(board) = model.state else {
            Issue.record("A fresh observation after cancellation must load the current operations")
            return
        }
        #expect(board.sales.map(\.id) == [current.id])
        #expect(board.inProgress.map(\.id) == [current.id])
        #expect(model.lastError == nil)
        #expect(await repository.observationCount == 2)
    }

    @Test
    func `a caller cancelled before entering never acquires an observation`() async {
        let checkpoint = WorkdayViewModelCheckpoint()
        let repository = WorkdayViewModelControlledRepository(plans: [])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        let cancelled = Task {
            await checkpoint.block()
            await model.load()
        }
        await checkpoint.waitForEntry()
        cancelled.cancel()
        await checkpoint.release()
        await cancelled.value

        #expect(model.state == .idle)
        #expect(model.lastError == nil)
        #expect(await repository.observationCount == 0)
    }
}

enum WorkdayViewModelObsoleteEvent {
    case snapshot, failure, completion
}

private struct WorkdayViewModelStreamPlan {
    let stream: AsyncThrowingStream<[Sale], any Error>
    var entered: WorkdayViewModelCheckpoint?
    var hold: WorkdayViewModelCheckpoint?
}

private actor WorkdayViewModelControlledRepository: SaleRepository {
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        throw SalePaymentError.persistenceUnavailable
    }

    private var plans: [WorkdayViewModelStreamPlan]
    private(set) var observationCount = 0

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        observationCount += 1
        guard !plans.isEmpty else { return workdayViewModelStream([]) }
        let plan = plans.removeFirst()
        await plan.entered?.enter()
        await plan.hold?.block()
        return plan.stream
    }

    func sale(id: SaleID) -> Sale? { nil }

    func saveSale(_ sale: Sale) throws {
        throw SaleDraftError.persistenceUnavailable
    }

    func createDraft(_ draft: Sale) throws {
        throw SaleDraftError.persistenceUnavailable
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) throws -> Sale {
        throw SaleDraftError.persistenceUnavailable
    }

    func discardDraft(_ id: SaleID) throws {
        throw SaleDraftError.persistenceUnavailable
    }

    init(plans: [WorkdayViewModelStreamPlan]) {
        self.plans = plans
    }
}

private actor WorkdayViewModelCheckpoint {
    private var entered = false
    private var released = false
    private var entryWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    func enter() {
        entered = true
        entryWaiter?.resume()
        entryWaiter = nil
    }

    func block() async {
        enter()
        guard !released else { return }
        await withCheckedContinuation {
            releaseWaiter = $0
        }
    }

    func waitForEntry() async {
        guard !entered else { return }
        await withCheckedContinuation {
            entryWaiter = $0
        }
    }

    func release() {
        released = true
        releaseWaiter?.resume()
        releaseWaiter = nil
    }
}

private func workdayViewModelStream(_ sales: [Sale]) -> AsyncThrowingStream<[Sale], any Error> {
    AsyncThrowingStream { continuation in
        continuation.yield(sales)
        continuation.finish()
    }
}

@MainActor
private func workdayViewModelPublish(
    _ sale: Sale,
    to model: WorkdayViewModel,
    through continuation: AsyncThrowingStream<[Sale], any Error>.Continuation
) async {
    await withCheckedContinuation { changed in
        withObservationTracking {
            _ = model.state
        } onChange: {
            changed.resume()
        }
        continuation.yield([sale])
    }
}
