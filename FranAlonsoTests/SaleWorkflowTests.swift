import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct SaleWorkflowTests {
    @Test
    func `progress survives fresh reads and replay creates no extra causal operation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let draft = try viewModelSale()
        try source.upsert(draft, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let advance = AdvanceSaleUseCase(repository: repository)
        let started = try await advance(draft, action: .start)
        #expect(started.status == .inProgress)
        #expect(started.lines == draft.lines)
        let before = try source.pendingOperations(in: ModelContext(container))
        #expect(before.count == 1)
        #expect(try await advance(draft, action: .start) == started)
        #expect(try source.pendingOperations(in: ModelContext(container)) == before)
        let working = try await advance(started, action: .startLine(started.lines[0].id))
        let completed = try await advance(working, action: .completeLine(working.lines[0].id))
        #expect(completed.status == .awaitingPayment)
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == completed)
        #expect(try source.pendingOperations(in: ModelContext(container)).count == 3)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    func `stale progress cannot overwrite commercial edits`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let draft = try viewModelSale()
        let edited = try draft.replacingDraft(clientID: ClientID(rawValue: viewModelUUID(800)), lines: draft.lines)
        try source.upsert(edited, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        await #expect(throws: SaleProgressError.staleSale) {
            _ = try await AdvanceSaleUseCase(repository: repository)(draft, action: .start)
        }
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == edited)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test
    func `show cancel and repeat leave sale queue and stock untouched`() async throws {
        let fixture = try await workflowFixture(stock: 0)
        let before = try fixture.operations()
        let original = try #require(fixture.model.sale)
        fixture.model.selectPaymentMethod(.card)
        #expect(try await !fixture.model.preparePayment())
        let first = try #require(fixture.model.stockConfirmation)
        #expect(!first.stockUnavailable)
        fixture.model.cancelPaymentConfirmation(first.id)
        #expect(!fixture.model.confirmPayment(first.id))
        #expect(try await !fixture.model.preparePayment())
        let second = try #require(fixture.model.stockConfirmation)
        #expect(second.id != first.id)
        fixture.model.cancelPaymentConfirmation(first.id)
        #expect(fixture.model.stockConfirmation?.id == second.id)
        #expect(fixture.model.sale == original)
        #expect(try fixture.read() == original)
        #expect(try fixture.operations() == before)
        #expect(try fixture.movementCount() == 0)
    }

    @Test(arguments: [PaymentMethod.cash, .card])
    func `continue pays once and stays in workday pending document`(method: PaymentMethod) async throws {
        let fixture = try await workflowFixture(stock: 0)
        let before = try fixture.operations().count
        fixture.model.selectPaymentMethod(method)
        #expect(try await !fixture.model.preparePayment())
        let confirmation = try #require(fixture.model.stockConfirmation)
        #expect(fixture.model.confirmPayment(confirmation.id))
        #expect(!fixture.model.confirmPayment(confirmation.id))
        let paid = try await fixture.model.registerPreparedPayment()
        guard case let .awaitingDocument(_, acceptedMethod, _) = paid.status else {
            Issue.record("Continuing must accept a real payment")
            return
        }
        #expect(acceptedMethod == method)
        #expect(try fixture.read() == paid)
        #expect(try fixture.operations().count == before + 1)
        #expect(WorkdaySalesPolicy()([paid]).awaitingClosure == [paid])
        #expect(try fixture.movementCount() == 1)
        await #expect(throws: SaleDraftViewModelError.invalidMode) {
            _ = try await fixture.model.registerPreparedPayment()
        }
        #expect(try fixture.operations().count == before + 1)
    }

    @Test(arguments: [1, 2])
    func `exact exhaustion and sufficient stock need no extra confirmation`(stock: Int) async throws {
        let fixture = try await workflowFixture(stock: stock)
        fixture.model.selectPaymentMethod(.cash)
        #expect(try await fixture.model.preparePayment())
        #expect(fixture.model.stockConfirmation == nil)
        _ = try await fixture.model.registerPreparedPayment()
        #expect(try fixture.operations().count == 1)
    }

    @Test
    func `unknown stock requires explicit permission but never prevents continuation`() async throws {
        let fixture = try await workflowFixture(stock: nil)
        fixture.model.selectPaymentMethod(.cash)
        #expect(try await !fixture.model.preparePayment())
        let confirmation = try #require(fixture.model.stockConfirmation)
        #expect(confirmation.stockUnavailable)
        #expect(try fixture.operations().isEmpty)
        #expect(fixture.model.confirmPayment(confirmation.id))
        _ = try await fixture.model.registerPreparedPayment()
        #expect(try fixture.operations().count == 1)
    }

    @Test
    func `close revokes a confirmation without recording payment`() async throws {
        let fixture = try await workflowFixture(stock: 0)
        fixture.model.selectPaymentMethod(.cash)
        _ = try await fixture.model.preparePayment()
        let confirmation = try #require(fixture.model.stockConfirmation)
        fixture.model.close()
        #expect(!fixture.model.confirmPayment(confirmation.id))
        #expect(fixture.model.stockConfirmation == nil)
        #expect(try fixture.operations().isEmpty)
        #expect(try fixture.read()?.status == .awaitingPayment)
    }

    @Test
    func `lost acceptance response retries the same command without adding a second payment`() async throws {
        let fixture = try await workflowFixture(stock: 1)
        fixture.model.selectPaymentMethod(.card)
        #expect(try await fixture.model.preparePayment())
        await fixture.sales.loseNextPaymentResponse()
        await #expect(throws: SalePaymentError.persistenceUnavailable) {
            _ = try await fixture.model.registerPreparedPayment()
        }
        #expect(try fixture.operations().count == 1)
        #expect(fixture.model.sale?.status == .awaitingPayment)
        #expect(try await fixture.model.preparePayment())
        let accepted = try await fixture.model.registerPreparedPayment()
        let attempts = await fixture.sales.paymentAttempts
        #expect(attempts.count == 2)
        #expect(attempts[0] == attempts[1])
        #expect(try fixture.operations().count == 1)
        #expect(try fixture.read() == accepted)
    }

    @Test
    func `a concurrent payment is rejected and late accepted success never reopens a closed session`() async throws {
        let fixture = try await workflowFixture(stock: 1)
        fixture.model.selectPaymentMethod(.cash)
        _ = try await fixture.model.preparePayment()
        let gate = WorkflowGate()
        await fixture.sales.holdNextPayment(at: gate)
        let first = Task { try await fixture.model.registerPreparedPayment() }
        await gate.waitForEntry()
        await #expect(throws: SaleDraftViewModelError.invalidMode) {
            _ = try await fixture.model.registerPreparedPayment()
        }
        fixture.model.close()
        await gate.release()
        let accepted = try await first.value
        #expect(try fixture.read() == accepted)
        #expect(try fixture.operations().count == 1)
        #expect(fixture.model.isClosed)
        #expect(fixture.model.sale == nil)
    }

    @Test
    func `reloading revokes an old consent and never accepts its delayed continue`() async throws {
        let fixture = try await workflowFixture(stock: 0)
        fixture.model.selectPaymentMethod(.card)
        _ = try await fixture.model.preparePayment()
        let id = try #require(fixture.model.stockConfirmation?.id)
        _ = try await fixture.model.load()
        #expect(!fixture.model.confirmPayment(id))
        #expect(try fixture.operations().isEmpty)
    }

    @Test
    func `created session reloads external changes and recovers rejected progress`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let model = AppDependencies.preview(modelContainer: container).makeSaleDraft(
            SaleDraftDestination(id: viewModelUUID(970), saleID: SaleID(rawValue: viewModelUUID(971)), mode: .create)
        )
        #expect(try await model.load() == nil)
        let original = try await model.create(lines: viewModelSale().lines)
        let external = try original.replacingDraft(
            clientID: ClientID(rawValue: viewModelUUID(972)),
            lines: original.lines
        )
        try source.upsert(external, in: ModelContext(container))
        await #expect(throws: SaleProgressError.staleSale) {
            _ = try await model.advance(.start)
        }
        #expect(model.requiresReloadAfterActionError)
        #expect(try await model.load() == external)
        #expect(model.sale == external)
        let started = try await model.advance(.start)
        #expect(started.clientID == external.clientID)
        #expect(started.status == .inProgress)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == started)
    }

    @Test
    func `created session cannot become a new creation after recovered absence`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let model = AppDependencies.preview(modelContainer: container).makeSaleDraft(
            SaleDraftDestination(id: viewModelUUID(973), saleID: SaleID(rawValue: viewModelUUID(974)), mode: .create)
        )
        _ = try await model.load()
        let original = try await model.create(lines: viewModelSale().lines)
        try source.discardDraft(original.id, operationID: viewModelUUID(975), in: ModelContext(container))
        let pending = try source.pendingOperations(in: ModelContext(container))
        for _ in 0..<2 {
            #expect(try await model.load() == nil)
            #expect(model.contentState == .unavailable)
            #expect(!model.canCreate)
        }
        await #expect(throws: SaleDraftViewModelError.invalidMode) {
            _ = try await model.create()
        }
        #expect(try source.pendingOperations(in: ModelContext(container)) == pending)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == nil)
    }

    @Test(arguments: [false, true])
    func `draft rejection after external changes requires reload`(progressed: Bool) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let original = try viewModelSale()
        try source.upsert(original, in: ModelContext(container))
        let model = AppDependencies.preview(modelContainer: container).makeSaleDraft(
            SaleDraftDestination(id: viewModelUUID(976), saleID: original.id, mode: .editDraft)
        )
        _ = try await model.load()
        var external = try original.replacingDraft(
            clientID: ClientID(rawValue: viewModelUUID(977)),
            lines: original.lines
        )
        if progressed {
            try external.start()
        }
        try source.upsert(external, in: ModelContext(container))
        await #expect(throws: progressed ? SaleDraftError.requiresDraft : .staleDraft) {
            _ = try await model.setQuantity(2, for: original.lines[0].id)
        }
        #expect(model.requiresReloadAfterActionError)
        #expect(try await model.load() == external)
        #expect(model.sale == external)
        #expect(model.isReadOnly == progressed)
        #expect(model.canAddServices == !progressed)
    }

    @Test
    func `beginning service work revokes commercial editing while preserving the same accepted terms`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let original = try viewModelSale()
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let model = dependencies.makeSaleDraft(
            SaleDraftDestination(id: viewModelUUID(960), saleID: original.id, mode: .editDraft)
        )
        _ = try await model.load()
        let accepted = try await model.advance(.start)
        #expect(accepted.status == .inProgress)
        #expect(accepted.lines == original.lines)
        #expect(model.sale == accepted)
        #expect(model.isReadOnly)
        #expect(!model.canAddServices)
        await #expect(throws: SaleDraftViewModelError.readOnly) {
            _ = try await model.setQuantity(2, for: original.lines[0].id)
        }
        let working = try await model.advance(.startLine(original.lines[0].id))
        #expect(working.lines[0].status == .inProgress)
        let completed = try await model.advance(.completeLine(original.lines[0].id))
        #expect(completed.status == .awaitingPayment)
        #expect(model.showsPayment)
        #expect(!model.canRegisterPayment)
    }
}

private struct WorkflowFixture {
    let container: ModelContainer
    let model: SaleDraftViewModel
    let saleID: SaleID
    let sales: WorkflowSaleRepository

    func operations() throws -> [SalePendingOperation] {
        try SaleLocalDataSource().pendingOperations(in: ModelContext(container))
    }
    func read() throws -> Sale? {
        try SaleLocalDataSource().sale(id: saleID, in: ModelContext(container))
    }
    func movementCount() throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>())
    }
}

@MainActor
private func workflowFixture(stock: Int?) async throws -> WorkflowFixture {
    let container = try ModelContainer.inMemory(for: .franAlonso)
    let productID = ProductID(rawValue: viewModelUUID(950))
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(951)),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 100),
        lines: [SaleLine.upcoming(
            id: SaleLineID(rawValue: viewModelUUID(952)),
            serviceID: ServiceID(rawValue: viewModelUUID(953)),
            serviceName: "Synthetic workflow",
            quantity: 1,
            unitPrice: Money(amount: 10, currency: .eur),
            taxRate: TaxRate(percentage: 0),
            discount: nil,
            linkedProductID: productID
        )]
    )
    try sale.start()
    try sale.startLine(id: sale.lines[0].id)
    try sale.completeLine(id: sale.lines[0].id)
    let context = ModelContext(container)
    context.insert(ProductModel(Product(id: productID, name: "Synthetic workflow product", status: .active)))
    try context.save()
    try SaleLocalDataSource().upsert(sale, in: context)
    let sales = WorkflowSaleRepository(base: DefaultSaleRepository(
        persistenceActor: SalePersistenceActor(modelContainer: container),
        observationSignal: SaleObservationSignal()
    ))
    let model = SaleDraftViewModel(
        destination: SaleDraftDestination(id: viewModelUUID(954), saleID: sale.id, mode: .operate),
        createdAt: Date(timeIntervalSinceReferenceDate: 100),
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: sales),
        getDraft: GetSaleDraftUseCase(repository: sales),
        update: UpdateSaleDraftUseCase(repository: sales),
        discard: DiscardSaleDraftUseCase(repository: sales),
        getSale: GetSaleUseCase(repository: sales),
        getStock: GetSaleStockQuantitiesUseCase(repository: WorkflowStockReader(quantity: stock)),
        advance: AdvanceSaleUseCase(repository: sales),
        registerPayment: RegisterSalePaymentUseCase(repository: sales)
    )
    _ = try await model.load()
    return WorkflowFixture(
        container: container,
        model: model,
        saleID: sale.id,
        sales: sales
    )
}

private actor WorkflowStockReader: StockRepository {
    let quantity: Int?
    init(quantity: Int?) { self.quantity = quantity }
    func quantity(for productID: ProductID) throws -> Int {
        guard let quantity else { throw StockError.storageFailure }
        return quantity
    }
    func append(_ movement: StockMovement) throws -> StockMovement { throw StockError.storageFailure }
    func movement(id: StockMovementID) -> StockMovement? { nil }
    func observeQuantity(for productID: ProductID) -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

private actor WorkflowSaleRepository: SaleRepository {
    struct PaymentAttempt: Equatable {
        let id: PaymentID
        let method: PaymentMethod
        let paidAt: Date
    }
    let base: DefaultSaleRepository
    private var loseResponse = false
    private var paymentGate: WorkflowGate?
    private(set) var paymentAttempts: [PaymentAttempt] = []
    init(base: DefaultSaleRepository) { self.base = base }
    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await base.observeSales()
    }
    func sale(id: SaleID) async throws -> Sale? {
        try await base.sale(id: id)
    }
    func saveSale(_ sale: Sale) async throws {
        try await base.saveSale(sale)
    }
    func createDraft(_ draft: Sale) async throws {
        try await base.createDraft(draft)
    }
    func discardDraft(_ id: SaleID) async throws {
        try await base.discardDraft(id)
    }
    func advanceSale(_ expected: Sale, action: SaleProgressAction) async throws -> Sale {
        try await base.advanceSale(expected, action: action)
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
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        paymentAttempts.append(PaymentAttempt(id: paymentID, method: method, paidAt: paidAt))
        let lost = loseResponse
        let gate = paymentGate
        loseResponse = false
        paymentGate = nil
        await gate?.block()
        let accepted = try await base.registerPayment(
            expected,
            id: paymentID,
            method: method,
            paidAt: paidAt
        )
        if lost {
            throw SalePaymentError.persistenceUnavailable
        }
        return accepted
    }
    func loseNextPaymentResponse() {
        loseResponse = true
    }
    func holdNextPayment(at gate: WorkflowGate) {
        paymentGate = gate
    }
}

private actor WorkflowGate {
    private var entered = false
    private var entry: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?
    func block() async {
        entered = true
        entry?.resume()
        entry = nil
        await withCheckedContinuation { releaseContinuation = $0 }
    }
    func waitForEntry() async {
        guard !entered else { return }
        await withCheckedContinuation { entry = $0 }
    }
    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}
