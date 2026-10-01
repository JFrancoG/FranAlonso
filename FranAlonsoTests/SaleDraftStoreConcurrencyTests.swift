import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale draft store concurrency", .timeLimit(.minutes(1)))
@MainActor
struct SaleDraftStoreConcurrencyTests {
    @Test(arguments: [DraftStoreOverlappingCall.create, .load, .update, .discard])
    func `active update rejects overlapping operations without replacing accepted state`(
        call: DraftStoreOverlappingCall
    ) async throws {
        let original = try concurrentStoreSale()
        let repository = ControlledDraftStoreRepository(sales: [original])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.update, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await store.setQuantity(2, for: concurrentLineID)
        }
        await checkpoint.waitForEntry()
        #expect(store.operation == .update)
        #expect(store.draft == original)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("12.10")))

        await #expect(throws: SaleDraftStoreError.operationInProgress) {
            try await call.apply(to: store)
        }
        #expect(store.operation == .update)
        #expect(store.lastError == nil)
        #expect(store.draft == original)
        #expect(await repository.calls == [.load, .update])
        await checkpoint.release()
        _ = try await pending.value
        #expect(store.draft?.lines.first?.quantity == 2)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("24.20")))
        #expect(store.operation == nil)
        #expect(try await repository.current(id: concurrentSaleID)?.lines.first?.quantity == 2)
    }

    @Test
    func `local failure preserves accepted calculation and explicit retry clears the error`() async throws {
        let original = try concurrentStoreSale()
        let repository = ControlledDraftStoreRepository(sales: [original])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        await repository.failNextWrite(.persistenceUnavailable)

        await #expect(throws: SaleDraftError.persistenceUnavailable) {
            _ = try await store.setQuantity(2, for: concurrentLineID)
        }
        #expect(store.draft == original)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("12.10")))
        #expect((store.lastError as? SaleDraftError) == .persistenceUnavailable)
        #expect(store.operation == nil)
        #expect(try await repository.current(id: concurrentSaleID) == original)
        _ = try await store.setQuantity(2, for: concurrentLineID)
        #expect(store.lastError == nil)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("24.20")))
        #expect(store.draft?.lines.first?.quantity == 2)
        #expect(await repository.calls == [.load, .update, .update])
    }

    @Test(arguments: [DraftStoreWriteCall.update, .discard])
    func `cancellation before acceptance retains the previous snapshot without presenting an error`(
        call: DraftStoreWriteCall
    ) async throws {
        let original = try concurrentStoreSale()
        let repository = ControlledDraftStoreRepository(sales: [original])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(call.repositoryCall, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await call.apply(to: store)
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            try await pending.value
        }
        #expect(store.draft == original)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("12.10")))
        #expect(store.lastError == nil)
        #expect(store.operation == nil)
        #expect(try await repository.current(id: concurrentSaleID) == original)
    }

    @Test
    func `creation cancelled before acceptance leaves no materialized draft`() async throws {
        let repository = ControlledDraftStoreRepository(sales: [])
        let store = concurrentStore(repository: repository)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.create, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await store.create(
                id: concurrentSaleID,
                clientID: nil,
                createdAt: concurrentCreatedAt,
                lines: [concurrentStoreLine()]
            )
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(store.state == .idle)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(store.operation == nil)
        #expect(store.lastError == nil)
        #expect(try await repository.current(id: concurrentSaleID) == nil)
    }

    @Test
    func `a caller cancelled before entering the store never delegates creation`() async throws {
        let repository = ControlledDraftStoreRepository(sales: [])
        let store = concurrentStore(repository: repository)
        let checkpoint = DraftStoreCheckpoint()
        let pending = Task {
            await checkpoint.block()
            return try await store.create(
                id: concurrentSaleID,
                clientID: nil,
                createdAt: concurrentCreatedAt,
                lines: [concurrentStoreLine()]
            )
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(await repository.calls.isEmpty)
        #expect(store.state == .idle)
        #expect(store.operation == nil)
        #expect(store.lastError == nil)
    }

    @Test
    func `cancelled late read cannot replace the last accepted projection`() async throws {
        let original = try concurrentStoreSale()
        let replacementID = SaleID(rawValue: concurrentUUID(502))
        let replacement = try concurrentStoreSale(id: replacementID, quantity: 3)
        let repository = ControlledDraftStoreRepository(sales: [original, replacement])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.load, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await store.load(id: replacementID)
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(store.draft == original)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("12.10")))
        #expect(store.operation == nil)
        #expect(store.lastError == nil)
        #expect(try await repository.current(id: replacementID) == replacement)
    }

    @Test
    func `cancellation after accepted update returns durable success and publishes its calculation`() async throws {
        let repository = ControlledDraftStoreRepository(sales: [try concurrentStoreSale()])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.update, phase: .afterAcceptance, at: checkpoint)
        let pending = Task {
            try await store.setQuantity(2, for: concurrentLineID)
        }
        await checkpoint.waitForEntry()
        #expect(try await repository.current(id: concurrentSaleID)?.lines.first?.quantity == 2)
        pending.cancel()
        await checkpoint.release()

        let accepted = try await pending.value
        #expect(accepted.lines.first?.quantity == 2)
        #expect(store.draft == accepted)
        #expect(store.calculation?.total.amount == (try exactConcurrentStoreDecimal("24.20")))
        #expect(store.lastError == nil)
        #expect(store.operation == nil)
    }

    @Test
    func `closing during a read fences its late result and every later operation`() async throws {
        let original = try concurrentStoreSale()
        let repository = ControlledDraftStoreRepository(sales: [original])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.load, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await store.load(id: concurrentSaleID)
        }
        await checkpoint.waitForEntry()
        store.close()
        #expect(store.state == .closed)
        #expect(store.operation == nil)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(store.state == .closed)
        #expect(store.lastError == nil)
        #expect(try await repository.current(id: concurrentSaleID) == original)
        await #expect(throws: SaleDraftStoreError.closed) {
            _ = try await store.load(id: concurrentSaleID)
        }
        await #expect(throws: SaleDraftStoreError.closed) {
            _ = try await store.create(
                id: concurrentSaleID,
                clientID: nil,
                createdAt: concurrentCreatedAt,
                lines: []
            )
        }
        await #expect(throws: SaleDraftStoreError.closed) {
            _ = try await store.setQuantity(2, for: concurrentLineID)
        }
        await #expect(throws: SaleDraftStoreError.closed) {
            try await store.discard()
        }
        #expect(await repository.calls == [.load, .load])
        #expect(store.state == .closed)
    }

    @Test(arguments: [DraftStoreWriteCall.update, .discard])
    func `closing after local acceptance returns success without reopening presentation`(
        call: DraftStoreWriteCall
    ) async throws {
        let original = try concurrentStoreSale()
        let repository = ControlledDraftStoreRepository(sales: [original])
        let store = concurrentStore(repository: repository)
        _ = try await store.load(id: concurrentSaleID)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(call.repositoryCall, phase: .afterAcceptance, at: checkpoint)
        let pending = Task {
            try await call.apply(to: store)
        }
        await checkpoint.waitForEntry()
        store.close()
        await checkpoint.release()
        try await pending.value

        #expect(store.state == .closed)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(store.operation == nil)
        #expect(store.lastError == nil)
        #expect(try await repository.current(id: concurrentSaleID) == call.acceptedSale)
    }

    @Test
    func `closing after creation acceptance retains the durable draft and returns it to the caller`() async throws {
        let repository = ControlledDraftStoreRepository(sales: [])
        let store = concurrentStore(repository: repository)
        let checkpoint = DraftStoreCheckpoint()
        await repository.holdNext(.create, phase: .afterAcceptance, at: checkpoint)
        let pending = Task {
            try await store.create(
                id: concurrentSaleID,
                clientID: nil,
                createdAt: concurrentCreatedAt,
                lines: [concurrentStoreLine()]
            )
        }
        await checkpoint.waitForEntry()
        store.close()
        pending.cancel()
        await checkpoint.release()

        let accepted = try await pending.value
        #expect(accepted.lines.first?.quantity == 1)
        #expect(try await repository.current(id: concurrentSaleID) == accepted)
        #expect(store.state == .closed)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(store.lastError == nil)
        #expect(store.operation == nil)
    }
}

enum DraftStoreOverlappingCall {
    case create, load, update, discard

    @MainActor
    fileprivate func apply(to store: SaleDraftStore) async throws {
        switch self {
        case .create:
            _ = try await store.create(
                id: SaleID(rawValue: concurrentUUID(999)),
                clientID: nil,
                createdAt: concurrentCreatedAt,
                lines: []
            )
        case .load:
            _ = try await store.load(id: concurrentSaleID)
        case .update:
            _ = try await store.setClient(ClientID(rawValue: concurrentUUID(601)))
        case .discard:
            try await store.discard()
        }
    }
}

enum DraftStoreWriteCall {
    case update, discard

    fileprivate var repositoryCall: DraftStoreRepositoryCall {
        switch self {
        case .update: .update
        case .discard: .discard
        }
    }

    fileprivate var acceptedSale: Sale? {
        get throws {
            switch self {
            case .update:
                try concurrentStoreSale(quantity: 2)
            case .discard:
                nil
            }
        }
    }

    @MainActor
    fileprivate func apply(to store: SaleDraftStore) async throws {
        switch self {
        case .update:
            _ = try await store.setQuantity(2, for: concurrentLineID)
        case .discard:
            try await store.discard()
        }
    }
}

private enum DraftStoreRepositoryCall: Equatable {
    case create, load, update, discard
}

private enum DraftStoreHoldPhase: Equatable {
    case beforeAcceptance, afterAcceptance
}

private actor ControlledDraftStoreRepository: SaleRepository {
    private let backing: InMemorySaleRepository
    private var hold: (call: DraftStoreRepositoryCall, phase: DraftStoreHoldPhase, checkpoint: DraftStoreCheckpoint)?
    private var nextWriteFailure: SaleDraftError?
    private(set) var calls: [DraftStoreRepositoryCall] = []

    init(sales: [Sale]) {
        backing = InMemorySaleRepository(sales: sales)
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await backing.observeSales()
    }

    func saveSale(_ sale: Sale) async throws {
        try await backing.saveSale(sale)
    }

    func sale(id: SaleID) async throws -> Sale? {
        calls.append(.load)
        let captured = try await backing.sale(id: id)
        let checkpoint = takeHold(for: .load)?.checkpoint
        await checkpoint?.block()
        return captured
    }

    func createDraft(_ draft: Sale) async throws {
        calls.append(.create)
        let held = takeHold(for: .create)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        try takeWriteFailure()
        try await backing.createDraft(draft)
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
    }

    func updateDraft(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        calls.append(.update)
        let held = takeHold(for: .update)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        try takeWriteFailure()
        let accepted = try await backing.updateDraft(expected, clientID: clientID, lines: lines)
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
        return accepted
    }

    func discardDraft(_ id: SaleID) async throws {
        calls.append(.discard)
        let held = takeHold(for: .discard)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        try takeWriteFailure()
        try await backing.discardDraft(id)
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
    }

    func current(id: SaleID) async throws -> Sale? {
        try await backing.sale(id: id)
    }

    func holdNext(_ call: DraftStoreRepositoryCall, phase: DraftStoreHoldPhase, at checkpoint: DraftStoreCheckpoint) {
        hold = (call, phase, checkpoint)
    }

    func failNextWrite(_ error: SaleDraftError) {
        nextWriteFailure = error
    }

    private func takeHold(
        for call: DraftStoreRepositoryCall
    ) -> (phase: DraftStoreHoldPhase, checkpoint: DraftStoreCheckpoint)? {
        guard let held = hold, held.call == call else { return nil }
        hold = nil
        return (held.phase, held.checkpoint)
    }

    private func takeWriteFailure() throws {
        guard let error = nextWriteFailure else { return }
        nextWriteFailure = nil
        throw error
    }
}

private actor DraftStoreCheckpoint {
    private var entered = false
    private var entryWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    func block() async {
        entered = true
        entryWaiter?.resume()
        entryWaiter = nil
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
        releaseWaiter?.resume()
        releaseWaiter = nil
    }
}

@MainActor
private func concurrentStore(repository: any SaleRepository) -> SaleDraftStore {
    SaleDraftStore(
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: repository),
        get: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository)
    )
}

private func concurrentStoreSale(id: SaleID = concurrentSaleID, quantity: Int = 1) throws -> Sale {
    try Sale.draft(
        id: id,
        clientID: nil,
        createdAt: concurrentCreatedAt,
        lines: [concurrentStoreLine(quantity: quantity)]
    )
}

private func concurrentStoreLine(quantity: Int = 1) throws -> SaleLine {
    try SaleLine.upcoming(
        id: concurrentLineID,
        serviceID: ServiceID(rawValue: concurrentUUID(101)),
        serviceName: "Captured cut",
        quantity: quantity,
        unitPrice: Money(amount: exactConcurrentStoreDecimal("12.10"), currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
}

private let concurrentCreatedAt = Date(timeIntervalSinceReferenceDate: 123.456)
private let concurrentSaleID = SaleID(rawValue: concurrentUUID(501))
private let concurrentLineID = SaleLineID(rawValue: concurrentUUID(1))

private func exactConcurrentStoreDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}

private func concurrentUUID(_ index: Int) -> UUID {
    UUID(uuidString: String(format: "11310000-0000-0000-0000-%012d", index))!
}
