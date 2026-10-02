import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Idempotent sale stock consumption")
struct SaleStockMovementTests {
    @Test
    func `captured lines produce separate stable consumptions and omit professional services`() throws {
        let sale = try saleStockFixture()
        let events = try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID)
        let identifiers = events.map { $0.id.rawValue.uuidString.lowercased() }
        #expect(identifiers == [
            "c0969be6-6a1b-8497-8388-e059e9006643",
            "7e23acf3-547b-81ef-a2f2-4920403816ba",
            "137ee4ff-0c65-806e-985d-9658d2041987"
        ])
        #expect(events.map(\.quantityDelta) == [-2, -3, -4])
        #expect(events.map(\.productID) == [saleStockProductID(1), saleStockProductID(1), saleStockProductID(2)])
        #expect(events.allSatisfy { $0.occurredAt == Date(timeIntervalSinceReferenceDate: 100.125) })
        #expect(events.map(\.origin) == sale.lines.prefix(3).map {
            .sale(saleID: sale.id, lineID: $0.id, paymentID: saleStockPaymentID)
        })
    }

    @Test
    func `later document and reversal preserve original consumption without creating compensation`() throws {
        var sale = try saleStockFixture()
        let original = try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID)
        try sale.close(
            documentID: BillingDocumentID(rawValue: saleStockUUID(0xe2, 1)),
            closedAt: Date(timeIntervalSinceReferenceDate: 200)
        )
        #expect(try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID) == original)
        try sale.void(
            reversalID: SaleReversalID(rawValue: saleStockUUID(0xf2, 1)),
            voidedAt: Date(timeIntervalSinceReferenceDate: 300)
        )
        #expect(try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID) == original)
    }

    @Test
    func `ordering and another sale preserve line identity without sharing its movement`() throws {
        let original = try saleStockFixture()
        let reordered = try saleStockFixture(reverse: true)
        let otherSale = try saleStockFixture(saleOrdinal: 2)
        let policy = SaleStockMovementPolicy()
        let events = try policy(sale: original, paymentID: saleStockPaymentID)
        let reorderedEvents = try policy(sale: reordered, paymentID: saleStockPaymentID)
        #expect(reorderedEvents == Array(events.reversed()))
        let otherIDs = try policy(sale: otherSale, paymentID: saleStockPaymentID).map(\.id)
        #expect(Set(events.map(\.id)).isDisjoint(with: otherIDs))
    }

    @Test
    @MainActor
    func `repeated payment accepts one pending movement per linked line without changing sales or products`() async throws {
        let container = try saleStockContainer()
        let repository = try saleStockRepository(in: container)
        let sale = try saleStockFixture()
        let create = CreateSaleStockMovementsUseCase(repository: repository)
        let first = try await create(sale: sale, paymentID: saleStockPaymentID)
        let payloads = try stockPayloads(in: ModelContext(container))
        #expect(try await create(sale: sale, paymentID: saleStockPaymentID) == first)
        #expect(try stockPayloads(in: ModelContext(container)) == payloads)
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
        #expect(rows.count == 3)
        #expect(rows.allSatisfy { $0.payloadVersion == 2 && $0.isPendingSync })
        #expect(try await repository.quantity(for: saleStockProductID(1)) == -5)
        #expect(try await repository.quantity(for: saleStockProductID(2)) == -4)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
        let product = try ProductLocalDataSource().product(id: saleStockProductID(1), in: context)
        #expect(product?.name == "Synthetic stock 1")
    }

    @Test
    @MainActor
    func `unpaid snapshot and mismatched payment reject before any movement`() async throws {
        let container = try saleStockContainer()
        let create = CreateSaleStockMovementsUseCase(repository: try saleStockRepository(in: container))
        let unpaid = try saleStockFixture(paid: false)
        await #expect(throws: SaleError.invalidSaleTransition) {
            try await create(sale: unpaid, paymentID: saleStockPaymentID)
        }
        let paid = try saleStockFixture()
        await #expect(throws: SaleError.conflictingPayment) {
            try await create(sale: paid, paymentID: PaymentID(rawValue: saleStockUUID(0xc2, 2)))
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    @MainActor
    func `another payment for the same sale line conflicts instead of producing another withdrawal`() async throws {
        let container = try saleStockContainer()
        let create = CreateSaleStockMovementsUseCase(repository: try saleStockRepository(in: container))
        _ = try await create(sale: saleStockFixture(), paymentID: saleStockPaymentID)
        let payloads = try stockPayloads(in: ModelContext(container))
        let otherPayment = PaymentID(rawValue: saleStockUUID(0xc2, 2))
        let otherSale = try saleStockFixture(paymentID: otherPayment)
        await #expect(throws: StockError.identityConflict) {
            try await create(sale: otherSale, paymentID: otherPayment)
        }
        #expect(try stockPayloads(in: ModelContext(container)) == payloads)
        #expect(payloads.count == 3)
    }

    @Test
    @MainActor
    func `changed quantity conflicts and preserves every accepted payload`() async throws {
        let container = try saleStockContainer()
        let create = CreateSaleStockMovementsUseCase(repository: try saleStockRepository(in: container))
        _ = try await create(sale: saleStockFixture(), paymentID: saleStockPaymentID)
        let payloads = try stockPayloads(in: ModelContext(container))
        let changed = try saleStockFixture(firstQuantity: 8)
        await #expect(throws: StockError.identityConflict) {
            try await create(sale: changed, paymentID: saleStockPaymentID)
        }
        #expect(try stockPayloads(in: ModelContext(container)) == payloads)
    }

    @Test
    @MainActor
    func `failed second append leaves accepted history and retry completes only missing lines`() async throws {
        let container = try saleStockContainer()
        let base = try saleStockRepository(in: container)
        let interrupted = SaleStockInterruptionRepository(base: base, failOnAppend: 2)
        let create = CreateSaleStockMovementsUseCase(repository: interrupted)
        let sale = try saleStockFixture()
        await #expect(throws: StockError.storageFailure) {
            try await create(sale: sale, paymentID: saleStockPaymentID)
        }
        let before = try stockPayloads(in: ModelContext(container))
        #expect(before.count == 1)
        #expect(try await base.quantity(for: saleStockProductID(1)) == -2)
        #expect(try await create(sale: sale, paymentID: saleStockPaymentID).count == 3)
        let after = try stockPayloads(in: ModelContext(container))
        #expect(after.count == 3)
        #expect(before.allSatisfy { after[$0.key] == $0.value })
        #expect(try await base.quantity(for: saleStockProductID(1)) == -5)
    }

    @Test
    @MainActor
    func `concurrent callers sharing the writer accept a single consumption for each line`() async throws {
        let container = try saleStockContainer()
        let repository = try saleStockRepository(in: container)
        let first = CreateSaleStockMovementsUseCase(repository: repository)
        let second = CreateSaleStockMovementsUseCase(repository: repository)
        let sale = try saleStockFixture()
        async let left = first(sale: sale, paymentID: saleStockPaymentID)
        async let right = second(sale: sale, paymentID: saleStockPaymentID)
        let results = try await [left, right]
        #expect(results[0] == results[1])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(try await repository.quantity(for: saleStockProductID(1)) == -5)
    }

    @Test
    @MainActor
    func `a historical manual payload remains readable and exact retry never rewrites it`() async throws {
        let container = try saleStockContainer()
        let repository = try saleStockRepository(in: container)
        let payload = Data(#"{"id":{"rawValue":"95100000-0000-0000-0000-000000000001"},"productID":{"rawValue":"D2500000-0000-4000-8000-000000000001"},"quantityDelta":10,"reason":"Physical count","occurredAt":12000,"origin":{"manual":{"reference":{"rawValue":"95100000-0000-0000-0000-000000000001"}}}}"#.utf8)
        let id = StockMovementID(rawValue: try #require(UUID(uuidString: "95100000-0000-0000-0000-000000000001")))
        let context = ModelContext(container)
        context.insert(StockMovementModel(
            id: id.rawValue,
            productID: saleStockProductID(1).rawValue,
            payloadVersion: 1,
            payloadData: payload,
            isPendingSync: true
        ))
        try context.save()
        let manual = try #require(try await repository.movement(id: id))
        #expect(manual.quantityDelta == 10)
        #expect(manual.origin == .manual(reference: id))
        #expect(try await repository.append(manual) == manual)
        let create = CreateSaleStockMovementsUseCase(repository: repository)
        _ = try await create(sale: saleStockFixture(), paymentID: saleStockPaymentID)
        #expect(try stockPayloads(in: ModelContext(container))[id.rawValue] == payload)
        #expect(try await repository.quantity(for: saleStockProductID(1)) == 5)
    }
}

let saleStockPaymentID = PaymentID(rawValue: saleStockUUID(0xc2, 1))

func saleStockUUID(_ prefix: UInt8, _ ordinal: UInt8) -> UUID {
    UUID(uuid: (prefix, 0x50, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, ordinal))
}

func saleStockProductID(_ ordinal: UInt8) -> ProductID {
    ProductID(rawValue: saleStockUUID(0xd2, ordinal))
}

func saleStockFixture(
    saleOrdinal: UInt8 = 1,
    paymentID: PaymentID = saleStockPaymentID,
    firstQuantity: Int = 2,
    paid: Bool = true,
    reverse: Bool = false,
    professionalOnly: Bool = false
) throws -> Sale {
    let quantities = [firstQuantity, 3, 4, 9]
    var lines = try quantities.enumerated().map { index, quantity in
        try SaleLine.upcoming(
            id: SaleLineID(rawValue: saleStockUUID(0xb2, UInt8(index + 1))),
            serviceID: ServiceID(rawValue: saleStockUUID(0xe2, UInt8(index + 1))),
            serviceName: "Synthetic sale line",
            quantity: quantity,
            unitPrice: Money(amount: 10, currency: .eur),
            taxRate: TaxRate(percentage: 0),
            discount: nil,
            linkedProductID: professionalOnly || index == 3 ? nil : saleStockProductID(index == 2 ? 2 : 1)
        )
    }
    if reverse {
        lines.reverse()
    }
    var sale = try Sale.draft(
        id: SaleID(rawValue: saleStockUUID(0xa2, saleOrdinal)),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 10),
        lines: lines
    )
    try sale.start()
    for line in lines {
        try sale.startLine(id: line.id)
        try sale.completeLine(id: line.id)
    }
    if paid {
        try sale.registerPayment(id: paymentID, method: .cash, paidAt: Date(timeIntervalSinceReferenceDate: 100.125))
    }
    return sale
}

func saleStockContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

@MainActor
func saleStockRepository(in container: ModelContainer) throws -> DefaultStockRepository {
    let context = ModelContext(container)
    for ordinal: UInt8 in [1, 2] {
        context.insert(ProductModel(Product(
            id: saleStockProductID(ordinal),
            name: "Synthetic stock \(ordinal)",
            status: .active
        )))
    }
    try context.save()
    return DefaultStockRepository(
        persistenceActor: StockPersistenceActor(modelContainer: container),
        observationSignal: ProductObservationSignal()
    )
}

actor SaleStockInterruptionRepository: StockRepository {
    let base: DefaultStockRepository
    private var failOnAppend: Int?
    private var attempts = 0
    private let accepted: @Sendable (Int) -> Void

    func append(_ movement: StockMovement) async throws -> StockMovement {
        attempts += 1
        if attempts == failOnAppend {
            failOnAppend = nil
            throw StockError.storageFailure
        }
        let result = try await base.append(movement)
        accepted(attempts)
        return result
    }

    func movement(id: StockMovementID) async throws -> StockMovement? {
        try await base.movement(id: id)
    }

    func quantity(for productID: ProductID) async throws -> Int {
        try await base.quantity(for: productID)
    }

    func observeQuantity(for productID: ProductID) async -> AsyncThrowingStream<Int, any Error> {
        await base.observeQuantity(for: productID)
    }

    init(
        base: DefaultStockRepository,
        failOnAppend: Int? = nil,
        accepted: @escaping @Sendable (Int) -> Void = { _ in }
    ) {
        self.base = base
        self.failOnAppend = failOnAppend
        self.accepted = accepted
    }
}
