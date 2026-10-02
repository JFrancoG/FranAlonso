import Foundation
import Observation
import Testing
@testable import FranAlonso

@Suite("History observation fences", .timeLimit(.minutes(1)))
@MainActor
struct SalesHistoryConcurrencyTests {
    @Test(arguments: [HistoryTarget.history, .detail], [HistoryInterruption.cancel, .close, .replace])
    func `suspended acquisition cannot publish after cancellation closure or replacement`(
        target: HistoryTarget,
        interruption: HistoryInterruption
    ) async throws {
        let old = try viewModelSale(stage: .closed)
        let current = try viewModelSale(stage: .voided)
        let checkpoint = SaleDraftScreenCheckpoint()
        let repository = HistoryControlledRepository(plans: [
            HistoryStreamPlan(stream: historyStream([old]), hold: checkpoint),
            HistoryStreamPlan(stream: historyStream([current]))
        ])
        let model = HistoryHarness(target: target, repository: repository)
        let pending = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        switch interruption {
        case .cancel: pending.cancel()
        case .close: model.close()
        case .replace: await model.load()
        }
        await checkpoint.release()
        await pending.value
        switch interruption {
        case .cancel:
            #expect(model.phase == .idle)
            #expect(model.sale == nil)
        case .close:
            #expect(model.phase == .closed)
            #expect(model.sale == nil)
            await model.load()
        case .replace:
            #expect(model.sale == current)
            #expect(model.phase == .ready)
        }
        #expect(model.error == nil)
        #expect(await repository.count == (interruption == .replace ? 2 : 1))
    }

    @Test(arguments: [HistoryTarget.history, .detail], [HistoryLateEvent.snapshot, .failure, .completion])
    func `a replaced active stream cannot change snapshot or surface an obsolete error`(
        target: HistoryTarget,
        event: HistoryLateEvent
    ) async throws {
        let old = try viewModelSale(stage: .closed)
        let current = try viewModelSale(stage: .voided)
        let pair = AsyncThrowingStream<[Sale], any Error>.makeStream()
        let checkpoint = HistoryEntryCheckpoint()
        let repository = HistoryControlledRepository(plans: [
            HistoryStreamPlan(stream: pair.stream, entered: checkpoint),
            HistoryStreamPlan(stream: historyStream([current]))
        ])
        let model = HistoryHarness(target: target, repository: repository)
        let pending = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        await model.publish([old], through: pair.continuation)
        #expect(model.sale == old)
        await model.load()
        switch event {
        case .snapshot:
            pair.continuation.yield([old])
            pair.continuation.finish()
        case .failure:
            pair.continuation.finish(throwing: ViewModelRepositoryError.unavailable)
        case .completion:
            pair.continuation.finish()
        }
        await pending.value
        #expect(model.sale == current)
        #expect(model.phase == .ready)
        #expect(model.error == nil)
    }

    @Test(arguments: [HistoryTarget.history, .detail])
    func `cancelling active observation permits a fresh retry`(target: HistoryTarget) async throws {
        let sale = try viewModelSale(stage: .closed)
        let pair = AsyncThrowingStream<[Sale], any Error>.makeStream()
        let checkpoint = HistoryEntryCheckpoint()
        let repository = HistoryControlledRepository(plans: [
            HistoryStreamPlan(stream: pair.stream, entered: checkpoint),
            HistoryStreamPlan(stream: historyStream([sale]))
        ])
        let model = HistoryHarness(target: target, repository: repository)
        let pending = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        await model.publish([sale], through: pair.continuation)
        pending.cancel()
        await pending.value
        #expect(model.phase == .idle)
        #expect(model.error == nil)
        await model.load()
        #expect(model.sale == sale)
    }

    @Test(arguments: [HistoryTarget.history, .detail])
    func `closing fences an active stream even when it fails late`(target: HistoryTarget) async throws {
        let pair = AsyncThrowingStream<[Sale], any Error>.makeStream()
        let checkpoint = HistoryEntryCheckpoint()
        let repository = HistoryControlledRepository(plans: [
            HistoryStreamPlan(stream: pair.stream, entered: checkpoint)
        ])
        let model = HistoryHarness(target: target, repository: repository)
        let pending = Task {
            await model.load()
        }
        await checkpoint.waitForEntry()
        model.close()
        pair.continuation.finish(throwing: ViewModelRepositoryError.unavailable)
        await pending.value
        #expect(model.phase == .closed)
        #expect(model.error == nil)
    }

    @Test(
        arguments: [HistoryTarget.history, .detail],
        [ScreenClientReadInterruption.changedClient, .cancelled, .closed]
    )
    func `optional client labels cannot publish after identity replacement cancellation or close`(
        target: HistoryTarget,
        interruption: ScreenClientReadInterruption
    ) async throws {
        let oldClient = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Obsolete name")
        let newClient = Client.draft(id: ClientID(rawValue: viewModelUUID(601)), displayName: "Current name")
        let clients = ScreenClientReadRepository(clients: [oldClient, newClient])
        let sales = ViewModelSaleRepository(sales: [try viewModelSale(stage: .closed, clientID: oldClient.id)])
        let model = HistoryHarness(target: target, repository: sales, clients: clients)
        await model.load()
        let checkpoint = SaleDraftScreenCheckpoint()
        await clients.holdNextRead(at: checkpoint)
        let pending = Task {
            await model.resolveNames()
        }
        await checkpoint.waitForEntry()
        switch interruption {
        case .changedClient:
            await sales.saveSale(try viewModelSale(stage: .closed, clientID: newClient.id))
            await model.load()
            await model.resolveNames()
        case .cancelled: pending.cancel()
        case .closed: model.close()
        }
        await checkpoint.release()
        await pending.value
        #expect(model.name == (interruption == .changedClient ? "Current name" : nil))
        #expect(model.error == nil)
    }

    @Test(arguments: [HistoryTarget.history, .detail])
    func `missing and failed optional labels retain the terminal sale and can retry`(
        target: HistoryTarget
    ) async throws {
        let client = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Available name")
        let sale = try viewModelSale(stage: .closed, clientID: client.id)
        let clients = ScreenClientReadRepository(clients: [])
        let repository = ViewModelSaleRepository(sales: [sale])
        let model = HistoryHarness(target: target, repository: repository, clients: clients)
        await model.load()
        await model.resolveNames()
        #expect(model.name == nil)
        #expect(model.sale == sale)
        try await clients.saveClient(client)
        await clients.failNextRead()
        await model.resolveNames()
        #expect(model.name == nil)
        #expect(model.error == nil)
        await model.resolveNames()
        #expect(model.name == "Available name")
        #expect(model.sale == sale)
    }
}

enum HistoryTarget { case history, detail }
enum HistoryInterruption { case cancel, close, replace }
enum HistoryLateEvent { case snapshot, failure, completion }
enum HistoryPhase { case idle, loading, ready, unavailable, failed, closed }

@MainActor
struct HistoryHarness {
    let history: SalesHistoryViewModel?
    let detail: SaleDetailViewModel?

    var sale: Sale? { history?.visibleSales.first ?? detail?.sale }
    var error: (any Error)? { history?.lastError ?? detail?.lastError }
    var name: String? { history?.clientDisplayNames.values.first ?? detail?.clientName }
    var phase: HistoryPhase {
        if let history {
            switch history.state {
            case .idle: return .idle
            case .loading: return .loading
            case .content: return .ready
            case .failed: return .failed
            case .closed: return .closed
            }
        }
        guard let detail else { return .unavailable }
        switch detail.state {
        case .idle: return .idle
        case .loading: return .loading
        case .content: return .ready
        case .unavailable: return .unavailable
        case .failed: return .failed
        case .closed: return .closed
        }
    }

    func load() async {
        if let history {
            await history.load()
        } else {
            await detail?.load()
        }
    }

    func close() {
        history?.close()
        detail?.close()
    }

    func resolveNames() async {
        if let history {
            await history.resolveClientNames()
        } else {
            await detail?.resolveClientName()
        }
    }

    func publish(
        _ sales: [Sale],
        through continuation: AsyncThrowingStream<[Sale], any Error>.Continuation
    ) async {
        await withCheckedContinuation { changed in
            withObservationTracking {
                _ = history?.state
                _ = detail?.state
            } onChange: {
                changed.resume()
            }
            continuation.yield(sales)
        }
    }
}

extension HistoryHarness {
    init(target: HistoryTarget, repository: any SaleRepository, clients: (any ClientRepository)? = nil) {
        let getClient = clients.map { GetClientUseCase(repository: $0) }
        switch target {
        case .history:
            history = SalesHistoryViewModel(observe: ObserveSalesUseCase(repository: repository), getClient: getClient)
            detail = nil
        case .detail:
            history = nil
            detail = SaleDetailViewModel(
                destination: SaleDetailDestination(id: viewModelUUID(500), saleID: SaleID(rawValue: viewModelUUID(1))),
                observe: ObserveSalesUseCase(repository: repository),
                getClient: getClient
            )
        }
    }
}

private struct HistoryStreamPlan {
    let stream: AsyncThrowingStream<[Sale], any Error>
    var hold: SaleDraftScreenCheckpoint?
    var entered: HistoryEntryCheckpoint?
}

private actor HistoryControlledRepository: SaleRepository {
    private var plans: [HistoryStreamPlan]
    private(set) var count = 0

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        count += 1
        guard !plans.isEmpty else { return historyStream([]) }
        let plan = plans.removeFirst()
        if let entered = plan.entered {
            await entered.enter()
        }
        await plan.hold?.block()
        return plan.stream
    }

    func sale(id: SaleID) -> Sale? { nil }
    func saveSale(_ sale: Sale) throws { throw SaleDraftError.persistenceUnavailable }
    func createDraft(_ draft: Sale) throws { throw SaleDraftError.persistenceUnavailable }
    func discardDraft(_ id: SaleID) throws { throw SaleDraftError.persistenceUnavailable }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) throws -> Sale {
        throw SaleDraftError.persistenceUnavailable
    }

    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) throws -> Sale {
        throw SalePaymentError.persistenceUnavailable
    }

    init(plans: [HistoryStreamPlan]) {
        self.plans = plans
    }
}

func historyStream(_ sales: [Sale]) -> AsyncThrowingStream<[Sale], any Error> {
    AsyncThrowingStream { continuation in
        continuation.yield(sales)
        continuation.finish()
    }
}

private actor HistoryEntryCheckpoint {
    private var entered = false
    private var waiter: CheckedContinuation<Void, Never>?

    func enter() {
        entered = true
        waiter?.resume()
        waiter = nil
    }

    func waitForEntry() async {
        guard !entered else { return }
        await withCheckedContinuation {
            waiter = $0
        }
    }
}
