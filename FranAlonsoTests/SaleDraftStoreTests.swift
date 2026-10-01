import Foundation
import Observation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale draft store", .timeLimit(.minutes(1)))
@MainActor
struct SaleDraftStoreTests {
    @Test(arguments: [Currency.eur, .usd])
    func `empty creation publishes zero amounts and survives independent recovery`(currency: Currency) async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store(currency: currency)
        #expect(try fixture.operations().isEmpty)

        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: []
        )

        let persisted = try #require(try fixture.persisted(id: storeSaleID))
        #expect(persisted.id == storeSaleID)
        #expect(persisted.status == .draft)
        #expect(persisted.lines.isEmpty)
        #expect(persisted.createdAt.timeIntervalSinceReferenceDate.bitPattern == storeCreatedAtInterval.bitPattern)
        #expect(store.draft == persisted)
        #expect(store.calculation?.total.currency == currency)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "0",
            discount: "0",
            base: "0",
            tax: "0",
            total: "0"
        )
        #expect(try fixture.operations().count == 1)
        #expect(store.operation == nil)
        #expect(store.lastError == nil)

        let recovered = fixture.store(currency: currency)
        _ = try await recovered.load(id: storeSaleID)
        #expect(recovered.draft == persisted)
        try expectStoreAmounts(
            recovered.calculation,
            subtotal: "0",
            discount: "0",
            base: "0",
            tax: "0",
            total: "0"
        )
        #expect(try fixture.operations().count == 1)
    }

    @Test
    func `edits persist captured terms and publish literal rounded amounts`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: []
        )
        _ = try await store.addLine(storeLine())
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
        _ = try await store.addLine(storeLine(index: 2, amount: "9.99"))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "22.09",
            discount: "0",
            base: "19.08",
            tax: "3.01",
            total: "22.09"
        )
        _ = try await store.setQuantity(3, for: storeLineID(1))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "46.29",
            discount: "0",
            base: "39.08",
            tax: "7.21",
            total: "46.29"
        )
        _ = try await store.setDiscount(Discount(percentage: 10), for: storeLineID(1))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "46.29",
            discount: "3.63",
            base: "36.08",
            tax: "6.58",
            total: "42.66"
        )
        _ = try await store.setClient(storeClientID)

        let persisted = try #require(try fixture.persisted(id: storeSaleID))
        #expect(persisted.clientID == storeClientID)
        #expect(persisted.lines.map(\.id) == [storeLineID(1), storeLineID(2)])
        #expect(persisted.lines.map(\.serviceName) == ["Captured cut", "Captured treatment"])
        #expect(persisted.lines[0].quantity == 3)
        #expect(persisted.lines[0].unitPrice.amount == (try exactStoreDecimal("12.10")))
        #expect(persisted.lines[0].taxRate.percentage == 21)
        #expect(persisted.lines[0].discount?.percentage == 10)
        #expect(persisted.lines[0].serviceID == ServiceID(rawValue: storeUUID(101)))
        #expect(persisted.lines[0].linkedProductID == ProductID(rawValue: storeUUID(201)))
        #expect(persisted.createdAt.timeIntervalSinceReferenceDate.bitPattern == storeCreatedAtInterval.bitPattern)
        #expect(store.draft == persisted)

        _ = try await store.setClient(nil)
        _ = try await store.removeLine(id: storeLineID(2))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "36.30",
            discount: "3.63",
            base: "27",
            tax: "5.67",
            total: "32.67"
        )
        _ = try await store.setDiscount(nil, for: storeLineID(1))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "36.30",
            discount: "0",
            base: "30",
            tax: "6.30",
            total: "36.30"
        )
        #expect(try fixture.persisted(id: storeSaleID)?.clientID == nil)
        #expect(try fixture.persisted(id: storeSaleID)?.lines.first?.discount == nil)
        _ = try await store.removeLine(id: storeLineID(1))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "0",
            discount: "0",
            base: "0",
            tax: "0",
            total: "0"
        )
        #expect(try fixture.persisted(id: storeSaleID)?.lines.isEmpty == true)

        let operations = try fixture.operations()
        #expect(operations.count == 10)
        #expect(operations.first?.predecessorOperationID == nil)
        #expect(operations.dropFirst().map(\.predecessorOperationID) == operations.dropLast().map {
            Optional($0.operationID)
        })
    }

    @Test
    func `repeated services retain distinct line identities and insertion order`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: [storeLine()]
        )
        _ = try await store.addLine(storeLine(index: 3))

        #expect(store.draft?.lines.map(\.id) == [storeLineID(1), storeLineID(3)])
        #expect(store.draft?.lines.map(\.serviceID) == [
            ServiceID(rawValue: storeUUID(101)), ServiceID(rawValue: storeUUID(101))
        ])
        try expectStoreAmounts(
            store.calculation,
            subtotal: "24.20",
            discount: "0",
            base: "20",
            tax: "4.20",
            total: "24.20"
        )
        #expect(try fixture.persisted(id: storeSaleID)?.lines.count == 2)
    }

    @Test(arguments: [Currency.eur, .usd])
    func `recovery recalculates captured lines and valid absence clears presentation`(currency: Currency) async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine(currency: currency)])
        let replacementID = SaleID(rawValue: storeUUID(998))
        let replacement = try fixture.seed(id: replacementID, lines: [storeLine(currency: currency, quantity: 2)])
        let store = fixture.store(currency: currency)

        _ = try await store.load(id: storeSaleID)
        #expect(store.draft == original)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
        _ = try await store.load(id: replacementID)
        #expect(store.draft == replacement)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "24.20",
            discount: "0",
            base: "20",
            tax: "4.20",
            total: "24.20"
        )
        _ = try await store.load(id: SaleID(rawValue: storeUUID(999)))
        #expect(store.state == .idle)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(store.lastError == nil)
        #expect(try fixture.operations().count == 2)
        #expect(try fixture.persisted(id: storeSaleID) == original)
    }

    @Test(arguments: [DraftStoreIdleIntention.add, .remove, .quantity, .client, .discount, .discard])
    func `editing without a draft reports absence without any durable effect`(
        intention: DraftStoreIdleIntention
    ) async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        await #expect(throws: SaleDraftStoreError.noDraft) {
            try await intention.apply(to: store)
        }
        #expect(store.state == .idle)
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(try fixture.operations().isEmpty)
        #expect(try fixture.persisted(id: storeSaleID) == nil)
    }

    @Test
    func `creation with loaded draft cannot replace its accepted snapshot`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        let original = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: [storeLine()]
        )
        await #expect(throws: SaleDraftStoreError.draftAlreadyLoaded) {
            _ = try await store.create(
                id: SaleID(rawValue: storeUUID(999)),
                clientID: nil,
                createdAt: storeCreatedAt,
                lines: []
            )
        }
        #expect(store.draft == original)
        #expect(try fixture.operations().count == 1)
        #expect(try fixture.persisted(id: SaleID(rawValue: storeUUID(999))) == nil)
    }

    @Test
    func `occupied identity reports rejection and an explicit retry recovers`() async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let store = fixture.store()

        await #expect(throws: SaleDraftError.alreadyExists) {
            _ = try await store.create(
                id: storeSaleID,
                clientID: nil,
                createdAt: storeCreatedAt,
                lines: []
            )
        }
        #expect(store.state == .idle)
        #expect((store.lastError as? SaleDraftError) == .alreadyExists)
        #expect(try fixture.persisted(id: storeSaleID) == original)
        #expect(try fixture.operations().count == 1)
        _ = try await store.create(
            id: SaleID(rawValue: storeUUID(999)),
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: []
        )
        #expect(store.lastError == nil)
        #expect(try fixture.operations().count == 2)
    }

    @Test(arguments: [0, -1, Int.min])
    func `invalid quantity preserves the accepted draft without writing`(quantity: Int) async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let store = fixture.store()
        _ = try await store.load(id: storeSaleID)
        let before = try fixture.operations()

        await #expect(throws: SaleLineError.invalidQuantity) {
            _ = try await store.setQuantity(quantity, for: storeLineID(1))
        }
        #expect(store.draft == original)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
        #expect(try fixture.persisted(id: storeSaleID) == original)
        #expect(try fixture.operations() == before)
        #expect((store.lastError as? SaleLineError) == .invalidQuantity)
        #expect(store.operation == nil)
    }

    @Test(arguments: [DraftStoreMissingLineEdit.remove, .quantity, .discount])
    func `missing line rejects every identity targeted edit`(edit: DraftStoreMissingLineEdit) async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let store = fixture.store()
        _ = try await store.load(id: storeSaleID)
        let before = try fixture.operations()

        await #expect(throws: SaleError.lineNotFound) {
            try await edit.apply(to: store, id: storeLineID(999))
        }
        #expect(store.draft == original)
        #expect(try fixture.persisted(id: storeSaleID) == original)
        #expect(try fixture.operations() == before)
    }

    @Test(arguments: [false, true])
    func `duplicate or progressed additions never reach local acceptance`(progressed: Bool) async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let store = fixture.store()
        _ = try await store.load(id: storeSaleID)
        var added = try storeLine(index: progressed ? 3 : 1)
        if progressed {
            try added.start()
        }
        let before = try fixture.operations()

        await #expect(throws: SaleError.invalidDraftState) {
            _ = try await store.addLine(added)
        }
        #expect(store.draft == original)
        #expect(try fixture.operations() == before)
        #expect(try fixture.persisted(id: storeSaleID) == original)
    }

    @Test
    func `currency rejection occurs before creation or editing writes`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        let usdLine = try storeLine(currency: .usd)
        await #expect(throws: SaleCalculatorError.incompatibleCurrency(expected: .eur, actual: .usd)) {
            _ = try await store.create(
                id: storeSaleID,
                clientID: nil,
                createdAt: storeCreatedAt,
                lines: [usdLine]
            )
        }
        #expect(try fixture.operations().isEmpty)
        #expect(try fixture.persisted(id: storeSaleID) == nil)
        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: []
        )
        let original = store.draft
        await #expect(throws: SaleCalculatorError.incompatibleCurrency(expected: .eur, actual: .usd)) {
            _ = try await store.addLine(usdLine)
        }
        #expect(store.draft == original)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "0",
            discount: "0",
            base: "0",
            tax: "0",
            total: "0"
        )
        #expect(try fixture.operations().count == 1)
        #expect(try fixture.persisted(id: storeSaleID)?.lines.isEmpty == true)
    }

    @Test
    func `uncalculable creation and quantity edit never persist their candidates`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        let huge = "10000000000000000000000000000000000000e127"
        let overflow = try storeLine(quantity: Int.max, amount: huge, tax: 0)
        await #expect(throws: MoneyError.invalidAmount) {
            _ = try await store.create(
                id: storeSaleID,
                clientID: nil,
                createdAt: storeCreatedAt,
                lines: [overflow]
            )
        }
        #expect(try fixture.operations().isEmpty)
        #expect(try fixture.persisted(id: storeSaleID) == nil)

        let original = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: [storeLine(amount: huge, tax: 0)]
        )
        let calculation = store.calculation
        await #expect(throws: MoneyError.invalidAmount) {
            _ = try await store.setQuantity(Int.max, for: storeLineID(1))
        }
        #expect(store.draft == original)
        #expect(store.calculation == calculation)
        #expect(try fixture.persisted(id: storeSaleID) == original)
        #expect(try fixture.operations().count == 1)
    }

    @Test
    func `invalid recovered currency leaves the current accepted projection intact`() async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let incompatibleID = SaleID(rawValue: storeUUID(998))
        _ = try fixture.seed(id: incompatibleID, lines: [storeLine(currency: .usd)])
        let store = fixture.store()
        _ = try await store.load(id: storeSaleID)
        let before = try fixture.operations()

        await #expect(throws: SaleCalculatorError.incompatibleCurrency(expected: .eur, actual: .usd)) {
            _ = try await store.load(id: incompatibleID)
        }
        #expect(store.draft == original)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
        #expect(try fixture.operations() == before)
        #expect(store.operation == nil)
    }

    @Test
    func `stale rejection preserves presentation and explicit recovery permits editing again`() async throws {
        let fixture = try DraftStoreFixture()
        let original = try fixture.seed(lines: [storeLine()])
        let store = fixture.store()
        _ = try await store.load(id: storeSaleID)
        let external = try await UpdateSaleDraftUseCase(repository: fixture.repository)(
            original,
            clientID: storeClientID,
            lines: [storeLine(quantity: 2)]
        )
        let before = try fixture.operations()

        await #expect(throws: SaleDraftError.staleDraft) {
            _ = try await store.setQuantity(3, for: storeLineID(1))
        }
        #expect(store.draft == original)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
        #expect(try fixture.persisted(id: storeSaleID) == external)
        #expect(try fixture.operations() == before)
        _ = try await store.load(id: storeSaleID)
        _ = try await store.setQuantity(3, for: storeLineID(1))
        try expectStoreAmounts(
            store.calculation,
            subtotal: "36.30",
            discount: "0",
            base: "30",
            tax: "6.30",
            total: "36.30"
        )
        #expect(store.draft?.clientID == storeClientID)
        #expect(store.lastError == nil)
        #expect(try fixture.operations().count == 3)
    }

    @Test
    func `discard removes materialization once and preserves a causal tombstone`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: [storeLine()]
        )
        try await store.discard()
        try await store.discard()

        #expect(store.state == .discarded(storeSaleID))
        #expect(store.draft == nil)
        #expect(store.calculation == nil)
        #expect(try fixture.persisted(id: storeSaleID) == nil)
        let operations = try fixture.operations()
        #expect(operations.count == 2)
        #expect(operations.last?.predecessorOperationID == operations.first?.operationID)
        guard case .discard = try #require(operations.last) else {
            Issue.record("Accepted discard must retain its durable tombstone")
            return
        }
        await #expect(throws: SaleDraftError.alreadyExists) {
            _ = try await store.create(
                id: storeSaleID,
                clientID: nil,
                createdAt: storeCreatedAt,
                lines: []
            )
        }
        #expect(try fixture.operations() == operations)
    }

    @Test
    func `derived draft and calculation getters notify observers on accepted edits`() async throws {
        let fixture = try DraftStoreFixture()
        let store = fixture.store()
        _ = try await store.create(
            id: storeSaleID,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: []
        )

        try await confirmation("Accepted snapshot invalidates consumed getters", expectedCount: 1) { changed in
            withObservationTracking {
                _ = store.draft?.lines
                _ = store.calculation?.total
            } onChange: {
                changed()
            }
            _ = try await store.addLine(storeLine())
        }
        #expect(try fixture.persisted(id: storeSaleID)?.lines.count == 1)
        try expectStoreAmounts(
            store.calculation,
            subtotal: "12.10",
            discount: "0",
            base: "10",
            tax: "2.10",
            total: "12.10"
        )
    }
}

enum DraftStoreMissingLineEdit {
    case remove, quantity, discount

    @MainActor
    fileprivate func apply(to store: SaleDraftStore, id: SaleLineID) async throws {
        switch self {
        case .remove:
            _ = try await store.removeLine(id: id)
        case .quantity:
            _ = try await store.setQuantity(2, for: id)
        case .discount:
            _ = try await store.setDiscount(Discount(percentage: 10), for: id)
        }
    }
}

enum DraftStoreIdleIntention {
    case add, remove, quantity, client, discount, discard

    @MainActor
    fileprivate func apply(to store: SaleDraftStore) async throws {
        switch self {
        case .add:
            _ = try await store.addLine(storeLine())
        case .remove:
            _ = try await store.removeLine(id: storeLineID(1))
        case .quantity:
            _ = try await store.setQuantity(2, for: storeLineID(1))
        case .client:
            _ = try await store.setClient(storeClientID)
        case .discount:
            _ = try await store.setDiscount(Discount(percentage: 10), for: storeLineID(1))
        case .discard:
            try await store.discard()
        }
    }
}

private struct DraftStoreFixture {
    let container: ModelContainer
    let repository: DefaultSaleRepository
    let source = SaleLocalDataSource()

    @MainActor
    func store(currency: Currency = .eur) -> SaleDraftStore {
        SaleDraftStore(
            currency: currency,
            create: CreateSaleDraftUseCase(repository: repository),
            get: GetSaleDraftUseCase(repository: repository),
            update: UpdateSaleDraftUseCase(repository: repository),
            discard: DiscardSaleDraftUseCase(repository: repository)
        )
    }

    func persisted(id: SaleID) throws -> Sale? {
        try source.sale(id: id, in: ModelContext(container))
    }

    func operations() throws -> [SalePendingOperation] {
        try source.pendingOperations(in: ModelContext(container))
    }

    func seed(id: SaleID = storeSaleID, lines: [SaleLine]) throws -> Sale {
        let sale = try Sale.draft(
            id: id,
            clientID: nil,
            createdAt: storeCreatedAt,
            lines: lines
        )
        try source.createDraft(sale, operationID: id.rawValue, in: ModelContext(container))
        return sale
    }
}

private extension DraftStoreFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        self.init(
            container: container,
            repository: DefaultSaleRepository(
                persistenceActor: SalePersistenceActor(modelContainer: container),
                observationSignal: SaleObservationSignal()
            )
        )
    }
}

private func storeLine(
    index: Int = 1,
    currency: Currency = .eur,
    quantity: Int = 1,
    amount: String = "12.10",
    tax: Decimal? = nil
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: storeLineID(index),
        serviceID: ServiceID(rawValue: storeUUID(index == 2 ? 102 : 101)),
        serviceName: index == 2 ? "Captured treatment" : "Captured cut",
        quantity: quantity,
        unitPrice: Money(amount: exactStoreDecimal(amount), currency: currency),
        taxRate: TaxRate(percentage: tax ?? (index == 2 ? 10 : 21)),
        discount: nil,
        linkedProductID: ProductID(rawValue: storeUUID(index == 2 ? 202 : 201))
    )
}

private func expectStoreAmounts(
    _ optional: SaleCalculation?,
    subtotal: String,
    discount: String,
    base: String,
    tax: String,
    total: String
) throws {
    let calculation = try #require(optional)
    let expectedSubtotal = try exactStoreDecimal(subtotal)
    let expectedDiscount = try exactStoreDecimal(discount)
    let expectedBase = try exactStoreDecimal(base)
    let expectedTax = try exactStoreDecimal(tax)
    let expectedTotal = try exactStoreDecimal(total)
    #expect(calculation.subtotal.amount == expectedSubtotal)
    #expect(calculation.discountAmount.amount == expectedDiscount)
    #expect(calculation.taxableBase.amount == expectedBase)
    #expect(calculation.taxAmount.amount == expectedTax)
    #expect(calculation.total.amount == expectedTotal)
}

private let storeCreatedAtInterval = 0.000_000_123_456_789
private let storeCreatedAt = Date(timeIntervalSinceReferenceDate: storeCreatedAtInterval)
private let storeSaleID = SaleID(rawValue: storeUUID(500))
private let storeClientID = ClientID(rawValue: storeUUID(600))

private func storeLineID(_ index: Int) -> SaleLineID { SaleLineID(rawValue: storeUUID(index)) }

private func exactStoreDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}

private func storeUUID(_ index: Int) -> UUID {
    UUID(uuidString: String(format: "11300000-0000-0000-0000-%012d", index))!
}
