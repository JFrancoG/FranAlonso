import Foundation
import Observation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct SaleDraftViewModelTests {
    @Test
    func `facade quantity edits are accepted locally and publish the recalculated captured price`() async throws {
        let original = try viewModelSale()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        try source.createDraft(original, operationID: original.id.rawValue, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let model = makeSaleDraftViewModel(repository: repository, saleID: original.id, mode: .editDraft)
        _ = try await model.load()
        _ = try await model.setQuantity(2, for: original.lines[0].id)

        let persisted = try #require(try source.sale(id: original.id, in: ModelContext(container)))
        let calculation = try #require(model.calculation)
        let expectedTotal = try viewModelDecimal("24.20")
        let expectedBase = try viewModelDecimal("20.00")
        let expectedTax = try viewModelDecimal("4.20")
        #expect(persisted.lines[0].quantity == 2)
        #expect(model.sale == persisted)
        #expect(calculation.total.amount == expectedTotal)
        #expect(calculation.taxableBase.amount == expectedBase)
        #expect(calculation.taxAmount.amount == expectedTax)
    }

    @Test
    func `creation retries retain the session identity and exact creation date`() async throws {
        let repository = ViewModelSaleRepository()
        let model = makeSaleDraftViewModel(repository: repository)
        await repository.failNextCreate()

        await #expect(throws: ViewModelRepositoryError.unavailable) {
            _ = try await model.create(lines: [viewModelLine()])
        }
        #expect(model.sale == nil)
        #expect(model.lastError as? ViewModelRepositoryError == .unavailable)
        let accepted = try await model.create(lines: [viewModelLine()])
        let attempts = await repository.creationAttempts

        #expect(attempts.count == 2)
        #expect(attempts.map(\.id) == [SaleID(rawValue: viewModelUUID(1)), SaleID(rawValue: viewModelUUID(1))])
        #expect(attempts.map(\.createdAt) == [Date(timeIntervalSince1970: 100), Date(timeIntervalSince1970: 100)])
        #expect(model.sale == accepted)
        #expect(try await repository.sale(id: accepted.id) == accepted)
        #expect(model.lastError == nil)
    }

    @Test
    func `draft loading reads once and forwards errors from the retained Store`() async throws {
        let original = try viewModelSale()
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)
        _ = try await model.load()
        #expect(await repository.readCount == 1)

        await #expect(throws: SaleLineError.invalidQuantity) {
            _ = try await model.setQuantity(0, for: original.lines[0].id)
        }

        #expect(model.lastError as? SaleLineError == .invalidQuantity)
        #expect(model.sale == original)
        #expect(await repository.writeCount == 0)
        _ = try await model.setQuantity(2, for: original.lines[0].id)
        #expect(model.lastError == nil)
        #expect(model.sale?.lines[0].quantity == 2)
        #expect(await repository.readCount == 1)
    }

    @Test
    func `computed facade getters invalidate observation after accepted edits`() async throws {
        let repository = ViewModelSaleRepository()
        let model = makeSaleDraftViewModel(repository: repository)
        _ = try await model.create()
        try await confirmation("Store acceptance invalidates facade getters", expectedCount: 1) { changed in
            withObservationTracking {
                _ = model.sale?.lines
                _ = model.calculation?.total
            } onChange: {
                changed()
            }
            _ = try await model.addLine(viewModelLine())
        }
        let total = try viewModelDecimal("12.10")
        #expect(model.calculation?.total.amount == total)
        #expect(try await repository.sale(id: model.destination.saleID)?.lines.count == 1)
    }

    @Test
    func `client line discount removal and discard are delegated through the accepted draft`() async throws {
        let repository = ViewModelSaleRepository()
        let model = makeSaleDraftViewModel(repository: repository)
        _ = try await model.create(lines: [viewModelLine()])
        let lineID = SaleLineID(rawValue: viewModelUUID(100))
        let clientID = ClientID(rawValue: viewModelUUID(600))
        _ = try await model.setClient(clientID)
        _ = try await model.setDiscount(Discount(percentage: 10), for: lineID)
        let discounted = try viewModelDecimal("10.89")
        #expect(model.calculation?.total.amount == discounted)
        #expect(model.sale?.clientID == clientID)
        _ = try await model.removeLine(id: lineID)
        #expect(model.sale?.lines.isEmpty == true)
        #expect(model.calculation?.total.amount == 0)
        try await model.discard()
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(try await repository.sale(id: model.destination.saleID) == nil)
        #expect(await repository.writeCount == 5)
    }

    @Test(arguments: [ViewModelSaleStage.inProgress, .awaitingPayment, .awaitingDocument])
    func `operational inspection reads neutrally and calculates without persistence`(
        stage: ViewModelSaleStage
    ) async throws {
        let original = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)

        let inspected = try await model.load()

        let total = try viewModelDecimal("12.10")
        #expect(inspected == original)
        #expect(model.sale == original)
        #expect(model.calculation?.total.amount == total)
        #expect(model.isReadOnly)
        #expect(await repository.readCount == 1)
        #expect(await repository.writeCount == 0)
    }

    @Test(arguments: [ViewModelSaleStage.draft, .closed, .voided])
    func `nonoperational inspection is unavailable and may be explicitly reloaded`(
        stage: ViewModelSaleStage
    ) async throws {
        let original = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)

        #expect(try await model.load() == nil)
        #expect(model.inspectionState == .unavailable)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(model.lastError == nil)
        let working = try viewModelSale(stage: .inProgress)
        await repository.saveSale(working)
        _ = try await model.load()
        #expect(model.sale == working)
        #expect(await repository.readCount == 2)
        #expect(await repository.writeCount == 1)
    }

    @Test
    func `valid inspection absence clears prior content without making the session editable`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale(stage: .inProgress)])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        _ = try await model.load()
        await repository.removeFixture(id: model.destination.saleID)

        #expect(try await model.load() == nil)
        #expect(model.inspectionState == .unavailable)
        #expect(model.isReadOnly)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(await repository.writeCount == 0)
    }

    @Test(arguments: [SaleFacadeIntention.create, .add, .remove, .quantity, .client, .discount, .discard])
    func `inspection rejects every mutation before reaching persistence`(intention: SaleFacadeIntention) async throws {
        let original = try viewModelSale(stage: .awaitingDocument)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        _ = try await model.load()

        await #expect(throws: SaleDraftViewModelError.readOnly) {
            try await intention.apply(to: model)
        }

        #expect(model.sale == original)
        #expect(try await repository.sale(id: original.id) == original)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `a draft destination that progresses before loading fails closed without granting inspection`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale(stage: .inProgress)])
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)

        await #expect(throws: SaleDraftError.requiresDraft) {
            _ = try await model.load()
        }

        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(!model.isReadOnly)
        #expect(model.lastError as? SaleDraftError == .requiresDraft)
        #expect(await repository.readCount == 1)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `inspection read errors support explicit retry and clear their error on success`() async throws {
        let original = try viewModelSale(stage: .awaitingPayment)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        await repository.failNextRead()

        await #expect(throws: ViewModelRepositoryError.unavailable) {
            _ = try await model.load()
        }
        #expect(model.inspectionState == .failed)
        #expect(model.lastError as? ViewModelRepositoryError == .unavailable)
        _ = try await model.load()
        #expect(model.sale == original)
        #expect(model.lastError == nil)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `closing an accepted draft ends presentation without discarding persisted data`() async throws {
        let repository = ViewModelSaleRepository()
        let model = makeSaleDraftViewModel(repository: repository)
        let accepted = try await model.create(lines: [viewModelLine()])

        model.close()

        #expect(model.isClosed)
        #expect(model.sale == nil)
        #expect(model.calculation == nil)
        #expect(model.lastError == nil)
        #expect(try await repository.sale(id: accepted.id) == accepted)
        #expect(await repository.writeCount == 1)
        await #expect(throws: SaleDraftViewModelError.closed) {
            _ = try await model.load()
        }
        await #expect(throws: SaleDraftViewModelError.closed) {
            _ = try await model.setQuantity(2, for: accepted.lines[0].id)
        }
        #expect(await repository.writeCount == 1)
    }
}

enum SaleFacadeIntention {
    case create, add, remove, quantity, client, discount, discard

    @MainActor
    func apply(to model: SaleDraftViewModel) async throws {
        switch self {
        case .create:
            _ = try await model.create()
        case .add:
            _ = try await model.addLine(viewModelLine())
        case .remove:
            _ = try await model.removeLine(id: SaleLineID(rawValue: viewModelUUID(100)))
        case .quantity:
            _ = try await model.setQuantity(2, for: SaleLineID(rawValue: viewModelUUID(100)))
        case .client:
            _ = try await model.setClient(ClientID(rawValue: viewModelUUID(600)))
        case .discount:
            _ = try await model.setDiscount(Discount(percentage: 10), for: SaleLineID(rawValue: viewModelUUID(100)))
        case .discard:
            try await model.discard()
        }
    }
}

enum ViewModelRepositoryError: Error, Equatable {
    case unavailable
}

@MainActor
func makeSaleDraftViewModel(
    repository: any SaleRepository,
    saleID: SaleID = SaleID(rawValue: viewModelUUID(1)),
    mode: SaleDraftDestination.Mode = .create
) -> SaleDraftViewModel {
    SaleDraftViewModel(
        destination: SaleDraftDestination(id: viewModelUUID(500), saleID: saleID, mode: mode),
        createdAt: Date(timeIntervalSince1970: 100),
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: repository),
        getDraft: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository),
        getSale: GetSaleUseCase(repository: repository)
    )
}

actor ViewModelSaleRepository: SaleRepository {
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        throw SalePaymentError.persistenceUnavailable
    }

    private var sales: [SaleID: Sale]
    private var observationShouldFail = false
    private var readShouldFail = false
    private var createShouldFail = false
    private(set) var readCount = 0
    private(set) var writeCount = 0
    private(set) var creationAttempts: [Sale] = []

    func observeSales() -> AsyncThrowingStream<[Sale], any Error> {
        let shouldFail = observationShouldFail
        observationShouldFail = false
        return AsyncThrowingStream { continuation in
            if shouldFail {
                continuation.finish(throwing: ViewModelRepositoryError.unavailable)
                return
            }
            continuation.yield(Array(sales.values))
            continuation.finish()
        }
    }

    func sale(id: SaleID) throws -> Sale? {
        readCount += 1
        if readShouldFail {
            readShouldFail = false
            throw ViewModelRepositoryError.unavailable
        }
        return sales[id]
    }

    func saveSale(_ sale: Sale) {
        writeCount += 1
        sales[sale.id] = sale
    }

    func createDraft(_ draft: Sale) throws {
        creationAttempts.append(draft)
        if createShouldFail {
            createShouldFail = false
            throw ViewModelRepositoryError.unavailable
        }
        guard sales[draft.id] == nil else { throw SaleDraftError.alreadyExists }
        writeCount += 1
        sales[draft.id] = draft
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) throws -> Sale {
        guard let current = sales[expected.id] else { throw SaleDraftError.notFound }
        guard current == expected else { throw SaleDraftError.staleDraft }
        let updated = try current.replacingDraft(clientID: clientID, lines: lines, globalDiscount: globalDiscount)
        writeCount += 1
        sales[updated.id] = updated
        return updated
    }

    func discardDraft(_ id: SaleID) throws {
        guard let sale = sales[id] else { return }
        guard sale.status == .draft else { throw SaleDraftError.requiresDraft }
        writeCount += 1
        sales[id] = nil
    }

    func failNextObservation() {
        observationShouldFail = true
    }

    func failNextRead() {
        readShouldFail = true
    }

    func failNextCreate() {
        createShouldFail = true
    }

    func removeFixture(id: SaleID) {
        sales[id] = nil
    }

    init(sales: [Sale] = []) {
        self.sales = Dictionary(uniqueKeysWithValues: sales.map { ($0.id, $0) })
    }
}
