import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale draft advisory stock", .timeLimit(.minutes(1)))
@MainActor
struct SaleDraftStockTests {
    @Test("Screen projects only negative current impacts by line identity and leaves editing available")
    func projectsLineWarnings() async throws {
        let sales = InMemorySaleRepository()
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): 1])
        let model = draftStockModel(sales: sales, stock: stock)
        _ = try await model.load()
        _ = try await model.create(lines: [
            draftStockLine(1, product: 1),
            draftStockLine(2, product: 1, quantity: 2),
            draftStockLine(3, product: nil)
        ])
        let warnedID = SaleLineID(rawValue: draftStockUUID(2))

        #expect(model.stockWarnings.map(\.id) == [warnedID])
        #expect(model.stockWarning(for: warnedID)?.projectedQuantity == -2)
        #expect(model.stockWarning(for: SaleLineID(rawValue: draftStockUUID(1))) == nil)
        #expect(model.stockWarning(for: SaleLineID(rawValue: draftStockUUID(3))) == nil)
        #expect(model.stockWarning(for: SaleLineID(rawValue: draftStockUUID(99))) == nil)
        #expect(model.canIncrease(for: warnedID))
        #expect(model.canDecrease(for: warnedID))
        #expect(model.canAddServices)
        #expect(model.calculation?.total.amount == 4)
        #expect(await stock.appendCount == 0)
    }

    @Test("Unknown refresh states hide stale warnings without rearming an already announced deficit")
    func hidesUnknownWarnings() async throws {
        let sales = InMemorySaleRepository()
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): 0])
        let model = draftStockModel(sales: sales, stock: stock)
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
        _ = try await model.create(lines: [draftStockLine(1, product: 1)])
        #expect(model.takeStockWarningAnnouncement() != nil)
        let gate = DraftStockGate()
        await stock.failNext()
        await stock.holdNext(at: gate)
        let refresh = Task {
            try await model.refreshStock()
        }
        await gate.waitForEntry()
        #expect(model.stockState == .loading)
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
        await gate.release()
        try await refresh.value
        #expect(model.stockState == .failed)
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
        try await model.refreshStock()
        #expect(model.stockWarnings.count == 1)
        #expect(model.takeStockWarningAnnouncement() == nil)
        model.close()
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
    }

    @Test("Warning announcement is deduplicated until a ready snapshot clears the deficit")
    func rearmsOnlyAfterReadyRecovery() async throws {
        let sales = InMemorySaleRepository()
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): 0])
        let model = draftStockModel(sales: sales, stock: stock)
        let id = SaleLineID(rawValue: draftStockUUID(1))
        _ = try await model.create(lines: [draftStockLine(1, product: 1)])
        #expect(model.takeStockWarningAnnouncement() != nil)
        #expect(model.takeStockWarningAnnouncement() == nil)
        _ = try await model.increaseQuantity(for: id)
        #expect(model.stockWarning(for: id)?.projectedQuantity == -2)
        #expect(model.takeStockWarningAnnouncement() == nil)
        await stock.setQuantity(2, for: draftStockProduct(1))
        try await model.refreshStock()
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
        _ = try await model.increaseQuantity(for: id)
        #expect(model.takeStockWarningAnnouncement() != nil)
        #expect(model.takeStockWarningAnnouncement() == nil)
    }

    @Test("Removing one warned identity lets a newly accepted warned line announce once")
    func announcesNewIdentity() async throws {
        let sales = InMemorySaleRepository()
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): 0])
        let model = draftStockModel(sales: sales, stock: stock)
        _ = try await model.create(lines: [draftStockLine(1, product: 1)])
        #expect(model.takeStockWarningAnnouncement() != nil)
        _ = try await model.removeLine(id: SaleLineID(rawValue: draftStockUUID(1)))
        #expect(model.takeStockWarningAnnouncement() == nil)
        _ = try await model.addLine(draftStockLine(2, product: 1))
        #expect(model.stockWarnings.map(\.id) == [SaleLineID(rawValue: draftStockUUID(2))])
        #expect(model.takeStockWarningAnnouncement() != nil)
        #expect(model.takeStockWarningAnnouncement() == nil)
    }

    @Test("Inspection never publishes editable draft warnings or reads stock")
    func inspectionOmitsWarnings() async throws {
        let sales = InMemorySaleRepository()
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): -1])
        let model = draftStockModel(sales: sales, stock: stock, mode: .inspect)
        _ = try await model.load()
        #expect(model.stockWarnings.isEmpty)
        #expect(model.takeStockWarningAnnouncement() == nil)
        #expect(await stock.reads.isEmpty)
    }

    @Test("Localized warnings retain signed stock, service context and permission to continue", arguments: ["es", "en"])
    func localizesWarning(localeIdentifier: String) {
        let locale = Locale(identifier: localeIdentifier)
        var visible = LocalizedStringResource.salesStockWarning("-2")
        var accessible = LocalizedStringResource.salesStockWarningFor("Synthetic service", "-2")
        var announcement = LocalizedStringResource.salesStockWarningAnnouncement
        visible.locale = locale
        accessible.locale = locale
        announcement.locale = locale
        let visibleText = String(localized: visible)
        let accessibleText = String(localized: accessible)
        let announcementText = String(localized: announcement)
        let continuation = localeIdentifier == "es" ? "Puedes continuar." : "You can continue."
        #expect(visibleText.contains("-2"))
        #expect(visibleText.contains(continuation))
        #expect(accessibleText.contains(visibleText))
        #expect(accessibleText.contains("Synthetic service"))
        #expect(announcementText.contains(continuation))
    }

    @Test("Domain reads each linked product once in first-occurrence order")
    func readsUniqueProducts() async throws {
        let stock = DraftStockRepository(quantities: [draftStockProduct(1): 3, draftStockProduct(2): -2])
        let lines = try [
            draftStockLine(1, product: 1),
            draftStockLine(2, product: nil),
            draftStockLine(3, product: 2),
            draftStockLine(4, product: 1)
        ]
        let quantities = try await GetSaleStockQuantitiesUseCase(repository: stock)(lines: lines)

        #expect(quantities == [draftStockProduct(1): 3, draftStockProduct(2): -2])
        #expect(await stock.reads == [draftStockProduct(1), draftStockProduct(2)])
        #expect(await stock.appendCount == 0)
    }

    @Test("Recovering an existing draft reads current stock without rewriting its captured sale")
    func reloadsCurrentStock() async throws {
        let fixture = try await loadedStockFixture()
        await fixture.stock.setQuantity(-2, for: draftStockProduct(1))
        let recoveredStore = draftStockStore(sales: fixture.sales, stock: fixture.stock)
        let recovered = try await recoveredStore.load(id: draftStockSaleID)

        #expect(recovered == fixture.store.draft)
        #expect(try stockImpacts(recoveredStore).map(\.projectedQuantity) == [-3])
        #expect(try stockImpacts(recoveredStore).map(\.requiresWarning) == [true])
        #expect(try await fixture.sales.sale(id: draftStockSaleID) == recovered)
        #expect(await fixture.stock.appendCount == 0)
    }

    @Test("Accepted quantities and removals recompute repeated-product impacts")
    func recomputesAcceptedEdits() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 3])
        _ = try await fixture.store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1), draftStockLine(2, product: 1)]
        )
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [2, 1])

        _ = try await fixture.store.setQuantity(3, for: SaleLineID(rawValue: draftStockUUID(1)))
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [0, -1])
        #expect(try stockImpacts(fixture.store).map(\.requiresWarning) == [false, true])
        _ = try await fixture.store.removeLine(id: SaleLineID(rawValue: draftStockUUID(1)))
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [2])
        #expect(try stockImpacts(fixture.store).map(\.id) == [SaleLineID(rawValue: draftStockUUID(2))])
        _ = try await fixture.store.addLine(draftStockLine(3, product: 1, quantity: 3))
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [2, -1])
        #expect(try await fixture.sales.sale(id: draftStockSaleID)?.lines.map(\.quantity) == [1, 3])
        #expect(await fixture.stock.appendCount == 0)
    }

    @Test("Explicit refresh reads changed stock without rewriting accepted sale")
    func refreshesPhysicalStock() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 2])
        let accepted = try await fixture.store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1, quantity: 2)]
        )
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [0])
        await fixture.stock.setQuantity(-1, for: draftStockProduct(1))
        await fixture.store.refreshStock()

        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-3])
        #expect(try stockImpacts(fixture.store).map(\.requiresWarning) == [true])
        #expect(try await fixture.sales.sale(id: draftStockSaleID) == accepted)
        #expect(fixture.store.lastError == nil)
    }

    @Test("Professional-only and empty drafts require no inventory reader", arguments: [false, true])
    func omitsNonphysicalReads(includeProfessional: Bool) async throws {
        let repository = InMemorySaleRepository()
        let store = draftStockStore(sales: repository, stock: nil)
        _ = try await store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: includeProfessional ? [draftStockLine(1, product: nil)] : []
        )
        #expect(store.stockState == .ready([]))
        #expect(store.stockError == nil)
    }

    @Test("Unavailable inventory capability is explicit and does not reject accepted physical draft")
    func identifiesUnavailableReader() async throws {
        let repository = InMemorySaleRepository()
        let store = draftStockStore(sales: repository, stock: nil)
        let accepted = try await store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1)]
        )
        #expect(store.stockState == .failed)
        #expect(store.stockError as? SaleDraftStockError == .readerUnavailable)
        #expect(try await repository.sale(id: draftStockSaleID) == accepted)
        #expect(store.lastError == nil)
    }

    @Test("Read failure after acceptance is advisory and refresh can recover")
    func recoversAdvisoryFailure() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 1])
        await fixture.stock.failNext()
        let accepted = try await fixture.store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1)]
        )
        #expect(fixture.store.stockState == .failed)
        #expect(fixture.store.stockError as? StockError == .storageFailure)
        #expect(fixture.store.draft == accepted)
        #expect(fixture.store.calculation?.total.amount == 1)
        #expect(fixture.store.lastError == nil)
        await fixture.store.refreshStock()
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [0])
        #expect(fixture.store.stockError == nil)
    }

    @Test("Analysis overflow does not revoke accepted edit or reuse old warnings")
    func isolatesAnalysisFailure() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 1])
        _ = try await fixture.store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1)]
        )
        await fixture.stock.setQuantity(Int.min, for: draftStockProduct(1))
        let accepted = try await fixture.store.setQuantity(2, for: SaleLineID(rawValue: draftStockUUID(1)))

        #expect(fixture.store.stockState == .failed)
        let overflow = StockWarningPolicyError.quantityOverflow(productID: draftStockProduct(1))
        #expect(fixture.store.stockError as? StockWarningPolicyError == overflow)
        #expect(fixture.store.draft == accepted)
        #expect(fixture.store.lastError == nil)
        #expect(try await fixture.sales.sale(id: draftStockSaleID)?.lines.first?.quantity == 2)
    }

    @Test("Failed sale edit preserves stock for the last accepted snapshot")
    func retainsAcceptedWarningsOnRejectedEdit() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 0])
        _ = try await fixture.store.create(
            id: draftStockSaleID,
            clientID: nil,
            createdAt: draftStockDate,
            lines: [draftStockLine(1, product: 1)]
        )
        await #expect(throws: SaleLineError.invalidQuantity) {
            _ = try await fixture.store.setQuantity(0, for: SaleLineID(rawValue: draftStockUUID(1)))
        }
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-1])
        #expect(fixture.store.draft?.lines.first?.quantity == 1)
    }

    @Test("Late success or failure cannot replace a newer successful refresh", arguments: [false, true])
    func fencesSupersededResult(fails: Bool) async throws {
        let fixture = try await loadedStockFixture()
        let gate = DraftStockGate()
        if fails {
            await fixture.stock.failNext()
        }
        await fixture.stock.holdNext(at: gate)
        let old = Task {
            await fixture.store.refreshStock()
        }
        await gate.waitForEntry()
        #expect(fixture.store.stockState == .loading)
        await fixture.stock.setQuantity(0, for: draftStockProduct(1))
        await fixture.store.refreshStock()
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-1])
        await gate.release()
        await old.value
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-1])
        #expect(fixture.store.stockError == nil)
    }

    @Test("Accepted edit fences a suspended old-snapshot refresh")
    func fencesOldSnapshotAfterEdit() async throws {
        let fixture = try await loadedStockFixture()
        let gate = DraftStockGate()
        await fixture.stock.holdNext(at: gate)
        let old = Task {
            await fixture.store.refreshStock()
        }
        await gate.waitForEntry()
        _ = try await fixture.store.setQuantity(4, for: SaleLineID(rawValue: draftStockUUID(1)))
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-1])
        await gate.release()
        await old.value
        #expect(try stockImpacts(fixture.store).map(\.consumedQuantity) == [4])
        #expect(try stockImpacts(fixture.store).map(\.projectedQuantity) == [-1])
    }

    @Test("Close fences pending refresh without reopening the draft")
    func fencesClose() async throws {
        let fixture = try await loadedStockFixture()
        let gate = DraftStockGate()
        await fixture.stock.holdNext(at: gate)
        let old = Task {
            await fixture.store.refreshStock()
        }
        await gate.waitForEntry()
        fixture.store.close()
        await gate.release()
        await old.value
        #expect(fixture.store.state == .closed)
        #expect(fixture.store.stockState == .idle)
        #expect(fixture.store.stockError == nil)
    }

    @Test("Discard fences pending refresh and clears stock")
    func fencesDiscard() async throws {
        let fixture = try await loadedStockFixture()
        let gate = DraftStockGate()
        await fixture.stock.holdNext(at: gate)
        let old = Task {
            await fixture.store.refreshStock()
        }
        await gate.waitForEntry()
        try await fixture.store.discard()
        await gate.release()
        await old.value
        #expect(fixture.store.state == .discarded(draftStockSaleID))
        #expect(fixture.store.stockState == .idle)
        #expect(try await fixture.sales.sale(id: draftStockSaleID) == nil)
    }

    @Test("Cancellation during stock read retains durable creation and publishes no stale impact")
    func retainsAcceptedCreationAfterCancellation() async throws {
        let fixture = draftStockFixture(quantities: [draftStockProduct(1): 3])
        let gate = DraftStockGate()
        await fixture.stock.holdNext(at: gate)
        let pending = Task {
            try await fixture.store.create(
                id: draftStockSaleID,
                clientID: nil,
                createdAt: draftStockDate,
                lines: [draftStockLine(1, product: 1)]
            )
        }
        await gate.waitForEntry()
        #expect(try await fixture.sales.sale(id: draftStockSaleID)?.lines.count == 1)
        pending.cancel()
        await gate.release()
        let accepted = try await pending.value

        #expect(fixture.store.draft == accepted)
        #expect(fixture.store.stockState == .idle)
        #expect(fixture.store.stockError == nil)
        #expect(fixture.store.lastError == nil)
        #expect(fixture.store.operation == nil)
    }

    @Test("Valid absence clears prior stock when loading another identity")
    func clearsAbsentDraft() async throws {
        let fixture = try await loadedStockFixture()
        _ = try await fixture.store.load(id: SaleID(rawValue: draftStockUUID(99)))
        #expect(fixture.store.state == .idle)
        #expect(fixture.store.stockState == .idle)
        #expect(fixture.store.stockError == nil)
    }

    @Test("Interactive App composition reads the shared ledger and creates no movements while analyzing")
    func composesSharedLocalLedger() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let product = Product(id: draftStockProduct(1), name: "Synthetic stock", status: .active)
        try seedStockTestProduct(product, in: container)
        let stock = DefaultStockRepository(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            observationSignal: ProductObservationSignal()
        )
        _ = try await stock.append(stockTestMovement(productID: product.id, delta: 3, ordinal: 1))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let destination = SaleDraftDestination(id: draftStockUUID(70), saleID: draftStockSaleID, mode: .create)
        let model = dependencies.makeSaleDraft(destination)
        _ = try await model.load()
        _ = try await model.create(lines: [draftStockLine(1, product: 1, quantity: 4)])
        #expect(try stockImpacts(model).map(\.projectedQuantity) == [-1])

        _ = try await stock.append(stockTestMovement(productID: product.id, delta: 2, ordinal: 2))
        try await model.refreshStock()
        #expect(try stockImpacts(model).map(\.projectedQuantity) == [1])
        #expect(model.lastError == nil)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 2)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<SaleModel>()) == 1)
        model.close()
        #expect(model.stockState == .idle)
        await #expect(throws: SaleDraftViewModelError.closed) {
            try await model.refreshStock()
        }
        let inspection = dependencies.makeSaleDraft(
            SaleDraftDestination(id: draftStockUUID(71), saleID: draftStockSaleID, mode: .inspect)
        )
        await #expect(throws: SaleDraftViewModelError.readOnly) {
            try await inspection.refreshStock()
        }
        #expect(inspection.stockState == .idle)
    }
}

private actor DraftStockRepository: StockRepository {
    private var quantities: [ProductID: Int]
    private var nextFailure = false
    private var nextGate: DraftStockGate?
    private(set) var reads: [ProductID] = []
    private(set) var appendCount = 0

    init(quantities: [ProductID: Int]) {
        self.quantities = quantities
    }

    func quantity(for productID: ProductID) async throws -> Int {
        reads.append(productID)
        let captured = quantities[productID]
        let failure = nextFailure
        let gate = nextGate
        nextFailure = false
        nextGate = nil
        await gate?.block()
        if failure {
            throw StockError.storageFailure
        }
        guard let captured else { throw StockError.productNotFound }
        return captured
    }

    func append(_ movement: StockMovement) throws -> StockMovement {
        appendCount += 1
        throw StockError.storageFailure
    }

    func movement(id: StockMovementID) -> StockMovement? { nil }

    func observeQuantity(for productID: ProductID) -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream {
            $0.finish(throwing: StockError.storageFailure)
        }
    }

    func setQuantity(_ value: Int, for productID: ProductID) {
        quantities[productID] = value
    }
    func failNext() {
        nextFailure = true
    }
    func holdNext(at gate: DraftStockGate) {
        nextGate = gate
    }
}

private actor DraftStockGate {
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

private struct DraftStockFixture {
    let store: SaleDraftStore
    let sales: InMemorySaleRepository
    let stock: DraftStockRepository
}

@MainActor
private func draftStockFixture(quantities: [ProductID: Int]) -> DraftStockFixture {
    let sales = InMemorySaleRepository()
    let stock = DraftStockRepository(quantities: quantities)
    return DraftStockFixture(store: draftStockStore(sales: sales, stock: stock), sales: sales, stock: stock)
}

@MainActor
private func draftStockStore(sales: InMemorySaleRepository, stock: DraftStockRepository?) -> SaleDraftStore {
    SaleDraftStore(
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: sales),
        get: GetSaleDraftUseCase(repository: sales),
        update: UpdateSaleDraftUseCase(repository: sales),
        discard: DiscardSaleDraftUseCase(repository: sales),
        getStock: stock.map { GetSaleStockQuantitiesUseCase(repository: $0) }
    )
}

@MainActor
private func draftStockModel(
    sales: InMemorySaleRepository,
    stock: DraftStockRepository,
    mode: SaleDraftDestination.Mode = .create
) -> SaleDraftViewModel {
    SaleDraftViewModel(
        destination: SaleDraftDestination(id: draftStockUUID(70), saleID: draftStockSaleID, mode: mode),
        createdAt: draftStockDate,
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: sales),
        getDraft: GetSaleDraftUseCase(repository: sales),
        update: UpdateSaleDraftUseCase(repository: sales),
        discard: DiscardSaleDraftUseCase(repository: sales),
        getSale: GetSaleUseCase(repository: sales),
        getStock: GetSaleStockQuantitiesUseCase(repository: stock)
    )
}

@MainActor
private func loadedStockFixture() async throws -> DraftStockFixture {
    let fixture = draftStockFixture(quantities: [draftStockProduct(1): 3])
    _ = try await fixture.store.create(
        id: draftStockSaleID,
        clientID: nil,
        createdAt: draftStockDate,
        lines: [draftStockLine(1, product: 1)]
    )
    return fixture
}

@MainActor
private func stockImpacts(_ store: SaleDraftStore) throws -> [StockImpact] {
    guard case let .ready(impacts) = store.stockState else {
        Issue.record("Expected ready stock projection")
        throw StockError.storageFailure
    }
    return impacts
}

@MainActor
private func stockImpacts(_ model: SaleDraftViewModel) throws -> [StockImpact] {
    guard case let .ready(impacts) = model.stockState else {
        Issue.record("Expected ready stock projection")
        throw StockError.storageFailure
    }
    return impacts
}

private func draftStockLine(_ index: UInt8, product: UInt8?, quantity: Int = 1) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: draftStockUUID(index)),
        serviceID: ServiceID(rawValue: draftStockUUID(20)),
        serviceName: "Synthetic sale",
        quantity: quantity,
        unitPrice: Money(amount: 1, currency: .eur),
        taxRate: TaxRate(percentage: 0),
        discount: nil,
        linkedProductID: product.map(draftStockProduct)
    )
}

private func draftStockProduct(_ index: UInt8) -> ProductID { ProductID(rawValue: draftStockUUID(index)) }
private func draftStockUUID(_ index: UInt8) -> UUID {
    UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, index))
}
private let draftStockSaleID = SaleID(rawValue: draftStockUUID(50))
private let draftStockDate = Date(timeIntervalSinceReferenceDate: 100)
