import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale draft ViewModel concurrency", .timeLimit(.minutes(1)))
@MainActor
struct SaleDraftViewModelConcurrencyTests {
    @Test
    func `closing an inspection fences its late read and never delegates a write`() async throws {
        let original = try saleDraftViewModelInspectedSale()
        let repository = SaleDraftViewModelControlledRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextRead(at: checkpoint)
        let pending = Task {
            try await model.load()
        }
        await checkpoint.waitForEntry()
        #expect(model.isBusy)
        model.close()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        await #expect(throws: SaleDraftViewModelError.closed) {
            _ = try await model.load()
        }
        #expect(model.isClosed)
        #expect(model.inspectionState == .closed)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        #expect(await repository.calls == [.read])
        #expect(try await repository.current(id: original.id) == original)
    }

    @Test
    func `cancelled inspection reads publish no error and a fresh retry reads current local content`() async throws {
        let original = try saleDraftViewModelInspectedSale()
        let current = try saleDraftViewModelInspectedSale(quantity: 3)
        let repository = SaleDraftViewModelControlledRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        _ = try await model.load()
        try await repository.replace(current)
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextRead(at: checkpoint)
        let pending = Task {
            try await model.load()
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(model.inspectionState == .idle)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        let recovered = try await model.load()
        #expect(recovered == current)
        #expect(model.sale == current)
        #expect(model.calculation?.total.amount == (try viewModelDecimal("36.30")))
        #expect(model.lastError == nil)
        #expect(await repository.calls == [.read, .read, .read])
    }

    @Test(arguments: [SaleDraftViewModelObsoleteRead.snapshot, .absence, .failure])
    func `replaced inspection reads cannot overwrite newer content or present an obsolete failure`(
        _ outcome: SaleDraftViewModelObsoleteRead
    ) async throws {
        let original = try saleDraftViewModelInspectedSale()
        let current = try saleDraftViewModelInspectedSale(quantity: 3)
        let repository = SaleDraftViewModelControlledRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextRead(at: checkpoint, outcome: outcome)
        let obsolete = Task {
            try await model.load()
        }
        await checkpoint.waitForEntry()
        let recovered: Sale?
        do {
            try await repository.replace(current)
            recovered = try await model.load()
        } catch {
            await checkpoint.release()
            _ = await obsolete.result
            throw error
        }
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await obsolete.value
        }
        #expect(recovered == current)
        #expect(model.sale == current)
        #expect(model.calculation?.total.amount == (try viewModelDecimal("36.30")))
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        #expect(!model.isClosed)
        #expect(await repository.calls == [.read, .read])
    }

    @Test(arguments: [SaleDraftViewModelWrite.create, .update, .discard])
    func `cancellation before acceptance leaves the previous facade projection without a failure`(
        _ write: SaleDraftViewModelWrite
    ) async throws {
        let original = try viewModelSale()
        let repository = SaleDraftViewModelControlledRepository(sales: write == .create ? [] : [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: write == .create ? .create : .editDraft)
        if write != .create {
            _ = try await model.load()
        }
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextWrite(write, phase: .beforeAcceptance, at: checkpoint)
        let pending = Task {
            try await write.apply(to: model)
        }
        await checkpoint.waitForEntry()
        #expect(model.isBusy)
        pending.cancel()
        await checkpoint.release()

        await #expect(throws: CancellationError.self) {
            _ = try await pending.value
        }
        #expect(model.sale == (write == .create ? nil : original))
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        #expect(!model.isClosed)
        let persisted = try await repository.current(id: original.id)
        #expect(persisted == (write == .create ? nil : original))
        if write != .create {
            #expect(model.calculation?.total.amount == (try viewModelDecimal("12.10")))
        } else {
            #expect(model.calculation == nil)
        }
    }

    @Test(arguments: [SaleDraftViewModelWrite.create, .update, .discard])
    func `cancellation after acceptance retains durable success through the facade`(
        _ write: SaleDraftViewModelWrite
    ) async throws {
        let original = try viewModelSale()
        let repository = SaleDraftViewModelControlledRepository(sales: write == .create ? [] : [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: write == .create ? .create : .editDraft)
        if write != .create {
            _ = try await model.load()
        }
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextWrite(write, phase: .afterAcceptance, at: checkpoint)
        let pending = Task {
            try await write.apply(to: model)
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()
        let accepted = try await pending.value
        let persisted = try await repository.current(id: original.id)

        #expect(persisted == accepted)
        #expect(model.sale == accepted)
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        #expect(!model.isClosed)
        switch write {
        case .create, .update:
            #expect(accepted?.id == original.id)
            #expect(accepted?.lines.first?.quantity == 2)
            #expect(model.calculation?.total.amount == (try viewModelDecimal("24.20")))
        case .discard:
            #expect(persisted == nil)
            #expect(model.calculation == nil)
        }
    }

    @Test(arguments: [SaleDraftViewModelWrite.create, .update, .discard])
    func `closing after acceptance returns success without reopening the facade`(
        _ write: SaleDraftViewModelWrite
    ) async throws {
        let original = try viewModelSale()
        let repository = SaleDraftViewModelControlledRepository(sales: write == .create ? [] : [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: write == .create ? .create : .editDraft)
        if write != .create {
            _ = try await model.load()
        }
        let checkpoint = SaleDraftViewModelCheckpoint()
        await repository.holdNextWrite(write, phase: .afterAcceptance, at: checkpoint)
        let pending = Task {
            try await write.apply(to: model)
        }
        await checkpoint.waitForEntry()
        model.close()
        pending.cancel()
        await checkpoint.release()
        let accepted = try await pending.value
        let persisted = try await repository.current(id: original.id)

        #expect(persisted == accepted)
        #expect(model.isClosed)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(model.lastError == nil)
        #expect(!model.isBusy)
        switch write {
        case .create, .update:
            #expect(accepted?.id == original.id)
            #expect(accepted?.lines.first?.quantity == 2)
        case .discard:
            #expect(persisted == nil)
        }
        await #expect(throws: SaleDraftViewModelError.closed) {
            _ = try await model.setQuantity(3, for: original.lines[0].id)
        }
    }
}

enum SaleDraftViewModelObsoleteRead {
    case snapshot, absence, failure
}

enum SaleDraftViewModelWrite: Equatable {
    case create, update, discard

    @MainActor
    fileprivate func apply(to model: SaleDraftViewModel) async throws -> Sale? {
        switch self {
        case .create:
            return try await model.create(lines: [viewModelLine(quantity: 2)])
        case .update:
            return try await model.setQuantity(2, for: SaleLineID(rawValue: viewModelUUID(100)))
        case .discard:
            try await model.discard()
            return nil
        }
    }
}

private enum SaleDraftViewModelRepositoryCall: Equatable {
    case read, create, update, discard
}

private enum SaleDraftViewModelAcceptancePhase: Equatable {
    case beforeAcceptance, afterAcceptance
}

private actor SaleDraftViewModelControlledRepository: SaleRepository {
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        throw SalePaymentError.persistenceUnavailable
    }

    private let backing: InMemorySaleRepository
    private var readHold: (checkpoint: SaleDraftViewModelCheckpoint, outcome: SaleDraftViewModelObsoleteRead)?
    private var writeHold: (
        write: SaleDraftViewModelWrite,
        phase: SaleDraftViewModelAcceptancePhase,
        checkpoint: SaleDraftViewModelCheckpoint
    )?
    private(set) var calls: [SaleDraftViewModelRepositoryCall] = []

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await backing.observeSales()
    }

    func sale(id: SaleID) async throws -> Sale? {
        calls.append(.read)
        let captured = try await backing.sale(id: id)
        guard let held = readHold else { return captured }
        readHold = nil
        await held.checkpoint.block()
        switch held.outcome {
        case .snapshot:
            return captured
        case .absence:
            return nil
        case .failure:
            throw SaleDraftError.persistenceUnavailable
        }
    }

    func saveSale(_ sale: Sale) async throws {
        try await backing.saveSale(sale)
    }

    func createDraft(_ draft: Sale) async throws {
        calls.append(.create)
        let held = takeWriteHold(.create)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        try await backing.createDraft(draft)
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        calls.append(.update)
        let held = takeWriteHold(.update)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        let accepted = try await backing.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount
        )
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
        return accepted
    }

    func discardDraft(_ id: SaleID) async throws {
        calls.append(.discard)
        let held = takeWriteHold(.discard)
        if held?.phase == .beforeAcceptance {
            await held?.checkpoint.block()
        }
        try await backing.discardDraft(id)
        if held?.phase == .afterAcceptance {
            await held?.checkpoint.block()
        }
    }

    func current(id: SaleID) async throws -> Sale? {
        try await backing.sale(id: id)
    }

    func replace(_ sale: Sale) async throws {
        try await backing.saveSale(sale)
    }

    func holdNextRead(
        at checkpoint: SaleDraftViewModelCheckpoint,
        outcome: SaleDraftViewModelObsoleteRead = .snapshot
    ) {
        readHold = (checkpoint, outcome)
    }

    func holdNextWrite(
        _ write: SaleDraftViewModelWrite,
        phase: SaleDraftViewModelAcceptancePhase,
        at checkpoint: SaleDraftViewModelCheckpoint
    ) {
        writeHold = (write, phase, checkpoint)
    }

    private func takeWriteHold(
        _ write: SaleDraftViewModelWrite
    ) -> (phase: SaleDraftViewModelAcceptancePhase, checkpoint: SaleDraftViewModelCheckpoint)? {
        guard let held = writeHold, held.write == write else { return nil }
        writeHold = nil
        return (held.phase, held.checkpoint)
    }

    init(sales: [Sale]) {
        backing = InMemorySaleRepository(sales: sales)
    }
}

private actor SaleDraftViewModelCheckpoint {
    private var entered = false
    private var released = false
    private var entryWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    func block() async {
        entered = true
        entryWaiter?.resume()
        entryWaiter = nil
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

private func saleDraftViewModelInspectedSale(quantity: Int = 1) throws -> Sale {
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(1)),
        clientID: nil,
        createdAt: Date(timeIntervalSince1970: 100),
        lines: [viewModelLine(quantity: quantity)]
    )
    try sale.start()
    return sale
}
