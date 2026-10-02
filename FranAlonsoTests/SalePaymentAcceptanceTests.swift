import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Local sale payment acceptance")
struct SalePaymentAcceptanceTests {
    @Test(arguments: [PaymentMethod.cash, .card])
    func `accepted payment survives independent reads and stays in workday`(method: PaymentMethod) async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let accepted = try await fixture.pay(original, method: method)

        #expect(accepted.status == .awaitingDocument(paymentID: paymentID, method: method, paidAt: paymentDate))
        #expect(accepted.lines == original.lines)
        #expect(accepted.globalDiscount == original.globalDiscount)
        #expect(try fixture.read() == accepted)
        #expect(WorkdaySalesPolicy()([accepted]).awaitingClosure == [accepted])
        let pending = try fixture.source.pendingUpserts(in: ModelContext(fixture.container))
        #expect(pending.count == 1)
        #expect(pending.first?.operationID == paymentOperationID)
        #expect(try pending.first?.sale.toDomain() == accepted)
    }

    @Test
    func `missing method leaves the sale and queue untouched`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        await #expect(throws: SalePaymentError.methodRequired) {
            _ = try await fixture.pay(original, method: nil)
        }
        #expect(try fixture.read() == original)
        #expect(try fixture.operations().isEmpty)
    }

    @Test(arguments: [false, true])
    func `unfinished services reject payment`(started: Bool) async throws {
        let fixture = try PaymentFixture()
        var sale = try paymentSale(completed: false)
        if started {
            try sale.start()
        }
        try fixture.seed(sale)
        await #expect(throws: SaleError.invalidSaleTransition) {
            _ = try await fixture.pay(sale)
        }
        #expect(try fixture.read() == sale)
        #expect(try fixture.operations().isEmpty)
    }

    @Test(arguments: [PaymentReplayState.paid, .closed, .voided])
    func `exact replay preserves later document and reversal without pending duplication`(
        state: PaymentReplayState
    ) async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        var current = try await fixture.pay(original)
        try progressPayment(&current, to: state)
        try fixture.seed(current)
        let before = try fixture.operations()
        let result = try await fixture.pay(original)
        #expect(result == current)
        #expect(try fixture.read() == current)
        #expect(try fixture.operations() == before)
        #expect(try await fixture.pay(current) == current)
        #expect(try fixture.operations() == before)
    }

    @Test(arguments: [PaymentChange.identity, .method, .date])
    func `divergent payment metadata cannot overwrite an accepted payment`(change: PaymentChange) async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let accepted = try await fixture.pay(original)
        let before = try fixture.operations()
        let command = changedPayment(change)
        await #expect(throws: SaleError.conflictingPayment) {
            _ = try await RegisterSalePaymentUseCase(repository: fixture.repository)(
                original,
                id: command.id,
                method: command.method,
                paidAt: command.date
            )
        }
        #expect(try fixture.read() == accepted)
        #expect(try fixture.operations() == before)
    }

    @Test(arguments: [PaymentCommercialChange.client, .price, .quantity, .global], [false, true])
    func `obsolete commercial snapshot cannot accept or replay payment`(
        change: PaymentCommercialChange,
        alreadyPaid: Bool
    ) async throws {
        let fixture = try PaymentFixture()
        let expected = try paymentSale()
        var current = try paymentSale(change: change)
        if alreadyPaid {
            try current.registerPayment(id: paymentID, method: .card, paidAt: paymentDate)
        }
        try fixture.seed(current)
        await #expect(throws: SalePaymentError.staleSale) {
            _ = try await fixture.pay(expected)
        }
        #expect(try fixture.read() == current)
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `nonfinite payment date is rejected without writes`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        await #expect(throws: SaleError.invalidTimestamp) {
            _ = try await RegisterSalePaymentUseCase(repository: fixture.repository)(
                original,
                id: paymentID,
                method: .card,
                paidAt: Date(timeIntervalSinceReferenceDate: .infinity)
            )
        }
        #expect(try fixture.read() == original)
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `cancelled command leaves no accepted payment`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await fixture.pay(original)
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
        #expect(try fixture.read() == original)
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `missing sale cannot be created by payment`() async throws {
        let fixture = try PaymentFixture()
        await #expect(throws: SalePaymentError.notFound) {
            _ = try await fixture.pay(paymentSale())
        }
        #expect(try fixture.read() == nil)
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `conflict blocks payment without removing its evidence`() async throws {
        let fixture = try PaymentFixture()
        let sale = try paymentSale()
        let context = ModelContext(fixture.container)
        try fixture.source.persistPendingUpsert(sale, operationID: paymentUUID(30), in: context)
        let operation = try #require(try fixture.operations().first)
        try fixture.source.recordConflict(
            operation: operation,
            reason: .baseChanged,
            remoteRecord: nil,
            in: context
        )
        let before = try fixture.operations()
        await #expect(throws: SalePaymentError.conflict) {
            _ = try await fixture.pay(sale)
        }
        #expect(try fixture.read() == sale)
        #expect(try fixture.operations() == before)
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<SaleSyncConflictModel>()) == 1)
    }

    @Test
    func `discarded identity cannot be restored by payment`() async throws {
        let fixture = try PaymentFixture()
        let draft = try paymentSale(completed: false)
        let context = ModelContext(fixture.container)
        try fixture.source.createDraft(draft, operationID: paymentUUID(30), in: context)
        try fixture.source.discardDraft(draft.id, operationID: paymentUUID(31), in: context)
        let before = try fixture.operations()
        await #expect(throws: SalePaymentError.deleted) {
            _ = try await fixture.pay(paymentSale())
        }
        #expect(try fixture.read() == nil)
        #expect(try fixture.operations() == before)
    }

    @Test
    func `failed local acceptance rolls back both sale and pending then retries the same payment`() throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let context = ModelContext(fixture.container)
        let poison = try SaleModel(Sale.draft(
            id: SaleID(rawValue: paymentUUID(99)),
            clientID: nil,
            createdAt: paymentDate,
            lines: []
        ))
        poison.linesPayloadVersion = 99
        context.insert(poison)
        try context.save()
        #expect(throws: SalePaymentError.persistenceUnavailable) {
            _ = try fixture.source.registerPayment(
                original,
                id: paymentID,
                method: .card,
                paidAt: paymentDate,
                operationID: paymentOperationID,
                in: context
            )
        }
        #expect(!context.hasChanges)
        #expect(try fixture.read() == original)
        #expect(try fixture.operations().isEmpty)
        let persistedPoison = try #require(try context.fetch(FetchDescriptor<SaleModel>()).first {
            $0.id == paymentUUID(99)
        })
        context.delete(persistedPoison)
        try context.save()
        let accepted = try fixture.source.registerPayment(
            original,
            id: paymentID,
            method: .card,
            paidAt: paymentDate,
            operationID: paymentOperationID,
            in: context
        )
        #expect(accepted.status == .awaitingDocument(paymentID: paymentID, method: .card, paidAt: paymentDate))
        #expect(try fixture.read() == accepted)
        #expect(try fixture.operations().map(\.operationID) == [paymentOperationID])
    }

    @MainActor
    @Test
    func `contextual acceptance protects unrelated edits and shares replay semantics`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let context = ModelContext(fixture.container)
        let unrelated = try SaleModel(Sale.draft(
            id: SaleID(rawValue: paymentUUID(99)),
            clientID: nil,
            createdAt: paymentDate,
            lines: []
        ))
        context.insert(unrelated)
        let adapter = SaleContextualPersistenceAdapter(
            observationSignal: SaleObservationSignal(),
            operationID: { paymentOperationID }
        )
        await #expect(throws: SalePaymentError.persistenceUnavailable) {
            _ = try await adapter.registerPayment(
                original,
                id: paymentID,
                method: .card,
                paidAt: paymentDate,
                in: context
            )
        }
        #expect(context.hasChanges)
        #expect(try fixture.operations().isEmpty)
        context.rollback()
        let accepted = try await adapter.registerPayment(
            original,
            id: paymentID,
            method: .card,
            paidAt: paymentDate,
            in: context
        )
        #expect(try fixture.read() == accepted)
        #expect(try await fixture.pay(original) == accepted)
        #expect(try fixture.operations().map(\.operationID) == [paymentOperationID])
    }

    @Test
    func `concurrent identical commands produce one causal payment`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        async let first = fixture.pay(original)
        async let second = fixture.pay(original)
        let results = try await [first, second]
        #expect(results.first == results.last)
        #expect(try fixture.read() == results.first)
        #expect(try fixture.operations().map(\.operationID) == [paymentOperationID])
    }

    @Test
    func `payment appends one causal successor to existing service work`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.source.persistPendingUpsert(
            original,
            operationID: paymentUUID(30),
            in: ModelContext(fixture.container)
        )
        _ = try await fixture.pay(original)
        let operations = try fixture.operations()
        #expect(operations.map(\.operationID) == [paymentUUID(30), paymentOperationID])
        #expect(operations.map(\.predecessorOperationID) == [nil, paymentUUID(30)])
    }

    @Test
    func `in memory route rejects stale input and preserves closed replay`() async throws {
        let original = try paymentSale()
        let repository = InMemorySaleRepository(sales: [original])
        let useCase = RegisterSalePaymentUseCase(repository: repository)
        var accepted = try await useCase(
            original,
            id: paymentID,
            method: .cash,
            paidAt: paymentDate
        )
        try accepted.close(documentID: BillingDocumentID(rawValue: paymentUUID(50)), closedAt: paymentDate)
        try await repository.saveSale(accepted)
        #expect(try await useCase(
            original,
            id: paymentID,
            method: .cash,
            paidAt: paymentDate
        ) == accepted)
        await #expect(throws: SalePaymentError.staleSale) {
            _ = try await useCase(
                paymentSale(change: .global),
                id: paymentID,
                method: .cash,
                paidAt: paymentDate
            )
        }
        #expect(try await repository.sale(id: original.id) == accepted)
    }

    @Test
    func `cancellation after durable acceptance still returns the recorded payment`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let signal = AsyncStream<Sale>.makeStream()
        let repository = PaymentCommittedGateRepository(base: fixture.repository, signal: signal.continuation)
        let task = Task {
            try await RegisterSalePaymentUseCase(repository: repository)(
                original,
                id: paymentID,
                method: .card,
                paidAt: paymentDate
            )
        }
        var iterator = signal.stream.makeAsyncIterator()
        let committed = try #require(await iterator.next())
        #expect(try fixture.read() == committed)
        task.cancel()
        await repository.release()
        #expect(try await task.value == committed)
        #expect(try fixture.operations().map(\.operationID) == [paymentOperationID])
    }

    @Test
    func `accepted payment invalidates the shared observation stream`() async throws {
        let fixture = try PaymentFixture()
        let original = try paymentSale()
        try fixture.seed(original)
        let stream = await fixture.repository.observeSales()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == [original])
        let accepted = try await fixture.pay(original)
        #expect(try await iterator.next() == [accepted])
    }

    @Test
    func `legacy paid replay retains original line bytes and payload version`() throws {
        let fixture = try PaymentFixture()
        let context = ModelContext(fixture.container)
        let bytes = Data(#"[{"id":"83000000-0000-0000-0000-000000000002","serviceID":"83000000-0000-0000-0000-000000000003","serviceName":"Legacy service","quantity":1,"unitPrice":{"amount":"100","currency":"EUR"},"taxRate":{"percentage":"21"},"status":"completed"}]"#.utf8)
        let model = SaleModel(
            id: paymentUUID(1),
            clientID: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 1),
            createdAtCanonical: "3ff0000000000000",
            statusKindRawValue: "awaitingDocument",
            paymentID: paymentID.rawValue,
            paymentMethodRawValue: "cash",
            paidAtCanonical: "4000000000000000",
            documentID: nil,
            closedAtCanonical: nil,
            reversalID: nil,
            voidedAtCanonical: nil,
            linesPayloadVersion: 1,
            linesData: bytes
        )
        context.insert(model)
        try context.save()
        let expected = try #require(try fixture.read())
        let replay = try fixture.source.registerPayment(
            expected,
            id: paymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 2),
            operationID: paymentOperationID,
            in: context
        )
        #expect(replay.status == .awaitingDocument(
            paymentID: paymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 2)
        ))
        let recovered = try #require(try ModelContext(fixture.container).fetch(FetchDescriptor<SaleModel>()).first)
        #expect(recovered.linesPayloadVersion == 1)
        #expect(recovered.linesData == bytes)
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `file backed payment and pending survive two reopenings`() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "SalePayment-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Payment.store")
        let original = try paymentSale()
        try writePaymentStore(original, at: url)
        try verifyPaymentStore(original, at: url)
        try verifyPaymentStore(original, at: url)
    }
}

enum PaymentReplayState { case paid, closed, voided }
enum PaymentChange { case identity, method, date }
enum PaymentCommercialChange { case client, price, quantity, global }
private let paymentID = PaymentID(rawValue: paymentUUID(20))
private let paymentOperationID = paymentUUID(21)
private let paymentDate = Date(timeIntervalSinceReferenceDate: 0.000_000_123_456_789)

private struct PaymentFixture {
    let container: ModelContainer
    let repository: DefaultSaleRepository
    let source = SaleLocalDataSource()

    func seed(_ sale: Sale) throws {
        try source.upsert(sale, in: ModelContext(container))
    }
    func read() throws -> Sale? {
        try source.sale(id: SaleID(rawValue: paymentUUID(1)), in: ModelContext(container))
    }
    func operations() throws -> [SalePendingOperation] {
        try source.pendingOperations(in: ModelContext(container))
    }

    func pay(_ expected: Sale, method: PaymentMethod? = .card) async throws -> Sale {
        try await RegisterSalePaymentUseCase(repository: repository)(
            expected,
            id: paymentID,
            method: method,
            paidAt: paymentDate
        )
    }
}

private extension PaymentFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        self.init(
            container: container,
            repository: DefaultSaleRepository(
                persistenceActor: SalePersistenceActor(modelContainer: container),
                observationSignal: SaleObservationSignal(),
                operationID: { paymentOperationID }
            )
        )
    }
}

private func paymentUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "83000000-0000-0000-0000-%012d", value))!
}

private func paymentSale(completed: Bool = true, change: PaymentCommercialChange? = nil) throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(rawValue: paymentUUID(2)),
        serviceID: ServiceID(rawValue: paymentUUID(3)),
        serviceName: "Captured service",
        quantity: change == .quantity ? 2 : 1,
        unitPrice: Money(amount: change == .price ? 99 : 100, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10),
        linkedProductID: nil
    )
    var sale = try Sale.draft(
        id: SaleID(rawValue: paymentUUID(1)),
        clientID: change == .client ? ClientID(rawValue: paymentUUID(4)) : nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 1),
        lines: [line],
        globalDiscount: SaleGlobalDiscount(
            discount: Discount(percentage: change == .global ? 30 : 20),
            policy: .lineThenGlobalV1
        )
    )
    if completed {
        try sale.start()
        try sale.startLine(id: line.id)
        try sale.completeLine(id: line.id)
    }
    return sale
}

private func progressPayment(_ sale: inout Sale, to state: PaymentReplayState) throws {
    if state != .paid {
        try sale.close(documentID: BillingDocumentID(rawValue: paymentUUID(50)), closedAt: paymentDate)
    }
    if state == .voided {
        try sale.void(reversalID: SaleReversalID(rawValue: paymentUUID(51)), voidedAt: paymentDate)
    }
}

private func changedPayment(
    _ change: PaymentChange
) -> (id: PaymentID, method: PaymentMethod, date: Date) {
    (
        change == .identity ? PaymentID(rawValue: paymentUUID(22)) : paymentID,
        change == .method ? .cash : .card,
        change == .date ? Date(timeIntervalSinceReferenceDate: 2) : paymentDate
    )
}

private func paymentContainer(at url: URL) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "SalePayment",
        schema: .franAlonso,
        url: url,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: Schema.franAlonso,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

private func writePaymentStore(_ original: Sale, at url: URL) throws {
    let container = try paymentContainer(at: url)
    let context = ModelContext(container)
    let source = SaleLocalDataSource()
    try source.upsert(original, in: context)
    _ = try source.registerPayment(
        original,
        id: paymentID,
        method: .card,
        paidAt: paymentDate,
        operationID: paymentOperationID,
        in: context
    )
}

private func verifyPaymentStore(_ original: Sale, at url: URL) throws {
    let container = try paymentContainer(at: url)
    let context = ModelContext(container)
    let source = SaleLocalDataSource()
    let sale = try #require(try source.sale(id: original.id, in: context))
    #expect(sale.status == .awaitingDocument(paymentID: paymentID, method: .card, paidAt: paymentDate))
    #expect(sale.lines == original.lines)
    #expect(sale.globalDiscount == original.globalDiscount)
    let before = try source.pendingOperations(in: context)
    #expect(before.map(\.operationID) == [paymentOperationID])
    #expect(try source.registerPayment(
        original,
        id: paymentID,
        method: .card,
        paidAt: paymentDate,
        operationID: paymentUUID(25),
        in: context
    ) == sale)
    #expect(try source.pendingOperations(in: context) == before)
}

private actor PaymentCommittedGateRepository: SaleRepository {
    let base: any SaleRepository
    let signal: AsyncStream<Sale>.Continuation
    private var gate: CheckedContinuation<Void, Never>?

    init(base: any SaleRepository, signal: AsyncStream<Sale>.Continuation) {
        self.base = base
        self.signal = signal
    }

    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        let accepted = try await base.registerPayment(
            expected,
            id: paymentID,
            method: method,
            paidAt: paidAt
        )
        await withCheckedContinuation { continuation in
            gate = continuation
            signal.yield(accepted)
            signal.finish()
        }
        return accepted
    }

    func release() {
        gate?.resume()
        gate = nil
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await base.observeSales()
    }
    func saveSale(_ sale: Sale) async throws {
        try await base.saveSale(sale)
    }
    func sale(id: SaleID) async throws -> Sale? {
        try await base.sale(id: id)
    }
    func createDraft(_ draft: Sale) async throws {
        try await base.createDraft(draft)
    }
    func discardDraft(_ id: SaleID) async throws {
        try await base.discardDraft(id)
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        try await base.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount
        )
    }
}
