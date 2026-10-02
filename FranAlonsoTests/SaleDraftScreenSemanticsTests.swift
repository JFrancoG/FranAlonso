import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale draft screen semantics", .timeLimit(.minutes(1)))
@MainActor
struct SaleDraftScreenSemanticsTests {
    @Test
    func `quantity controls accept one step and reject the minimum before persistence`() async throws {
        let original = try viewModelSale()
        let repository = InMemorySaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)
        let lineID = original.lines[0].id
        _ = try await model.load()

        #expect(model.canIncrease(for: lineID))
        #expect(!model.canDecrease(for: lineID))
        _ = try await model.increaseQuantity(for: lineID)
        #expect(model.sale?.lines[0].quantity == 2)
        #expect(model.calculation?.total.amount == (try viewModelDecimal("24.20")))
        #expect(model.canDecrease(for: lineID))
        _ = try await model.decreaseQuantity(for: lineID)
        await #expect(throws: SaleDraftViewModelError.quantityLimit) {
            _ = try await model.decreaseQuantity(for: lineID)
        }
        #expect(try await repository.sale(id: original.id)?.lines[0].quantity == 1)
        #expect(model.calculation?.total.amount == (try viewModelDecimal("12.10")))
    }

    @Test
    func `maximum quantity disables increase without overflow and still permits decreasing`() async throws {
        let line = try viewModelLine(quantity: Int.max)
        let original = try Sale.draft(
            id: SaleID(rawValue: viewModelUUID(1)),
            clientID: nil,
            createdAt: Date(timeIntervalSince1970: 100),
            lines: [line]
        )
        let repository = InMemorySaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)
        _ = try await model.load()

        #expect(!model.canIncrease(for: line.id))
        #expect(model.canDecrease(for: line.id))
        await #expect(throws: SaleDraftViewModelError.quantityLimit) {
            _ = try await model.increaseQuantity(for: line.id)
        }
        _ = try await model.decreaseQuantity(for: line.id)

        #expect(model.sale?.lines[0].quantity == Int.max - 1)
        #expect(try await repository.sale(id: original.id)?.lines[0].quantity == Int.max - 1)
    }

    @Test
    func `editable reads expose loading then ready and resolve the associated client name`() async throws {
        let client = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Cliente de prueba")
        let original = try viewModelSale(clientID: client.id)
        let checkpoint = SaleDraftScreenCheckpoint()
        let repository = SaleDraftScreenReadRepository(sales: [original], checkpoint: checkpoint)
        let model = SaleDraftViewModel(
            destination: SaleDraftDestination(id: viewModelUUID(500), saleID: original.id, mode: .editDraft),
            createdAt: Date(timeIntervalSince1970: 100),
            currency: .eur,
            create: CreateSaleDraftUseCase(repository: repository),
            getDraft: GetSaleDraftUseCase(repository: repository),
            update: UpdateSaleDraftUseCase(repository: repository),
            discard: DiscardSaleDraftUseCase(repository: repository),
            getSale: GetSaleUseCase(repository: repository),
            getClient: GetClientUseCase(repository: InMemoryClientRepository(clients: [client]))
        )
        let loading = Task {
            try await model.load()
        }
        await checkpoint.waitForEntry()
        #expect(model.contentState == .loading)
        await checkpoint.release()
        _ = try await loading.value
        await model.resolveClientName()

        #expect(model.contentState == .ready)
        #expect(model.clientDisplayName == "Cliente de prueba")
        #expect(model.sale == original)
    }

    @Test
    func `new sessions are ready without creating while missing edits remain unavailable`() async throws {
        let repository = ViewModelSaleRepository()
        let creating = makeSaleDraftViewModel(repository: repository)

        #expect(try await creating.load() == nil)
        #expect(creating.contentState == .ready)
        #expect(creating.canCreate)
        #expect(await repository.writeCount == 0)
        _ = try await creating.create()
        #expect(!creating.canCreate)
        #expect(creating.contentState == .ready)
        creating.close()
        #expect(creating.contentState == .closed)
        #expect(!creating.canCreate)
        let missing = makeSaleDraftViewModel(
            repository: repository,
            saleID: SaleID(rawValue: viewModelUUID(999)),
            mode: .editDraft
        )
        #expect(try await missing.load() == nil)
        #expect(missing.contentState == .unavailable)
        #expect(!missing.canCreate)
        #expect(await repository.writeCount == 1)
    }

    @Test
    func `an editable read failure publishes a retry state and successful reload restores controls`() async throws {
        let original = try viewModelSale()
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)
        await repository.failNextRead()

        await #expect(throws: ViewModelRepositoryError.unavailable) {
            _ = try await model.load()
        }
        #expect(model.contentState == .failed)
        #expect(!model.canIncrease(for: original.lines[0].id))
        _ = try await model.load()
        #expect(model.contentState == .ready)
        #expect(model.canIncrease(for: original.lines[0].id))
        #expect(model.lastError == nil)
    }

    @Test(arguments: [false, true])
    func `quantity screen intentions reject read-only and closed modes before limit checks`(closed: Bool) async throws {
        let original = try viewModelSale(stage: .awaitingPayment)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = makeSaleDraftViewModel(repository: repository, mode: .inspect)
        _ = try await model.load()
        if closed {
            model.close()
        }
        let expected: SaleDraftViewModelError = closed ? .closed : .readOnly
        let missingID = SaleLineID(rawValue: viewModelUUID(999))

        await #expect(throws: expected) {
            _ = try await model.increaseQuantity(for: missingID)
        }
        await #expect(throws: expected) {
            _ = try await model.decreaseQuantity(for: missingID)
        }
        #expect(!model.canIncrease(for: original.lines[0].id))
        #expect(!model.canDecrease(for: original.lines[0].id))
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `quantity intentions persist locally and publish the observed calculation`() async throws {
        let original = try viewModelSale()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        try source.createDraft(original, operationID: original.id.rawValue, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let model = makeSaleDraftViewModel(repository: repository, mode: .editDraft)
        _ = try await model.load()

        _ = try await model.increaseQuantity(for: original.lines[0].id)

        let persisted = try #require(try source.sale(id: original.id, in: ModelContext(container)))
        #expect(persisted.lines[0].quantity == 2)
        #expect(model.sale == persisted)
        #expect(model.calculation?.total.amount == (try viewModelDecimal("24.20")))
    }

    @Test(arguments: [ScreenClientReadInterruption.changedClient, .cancelled, .closed])
    func `late client labels cannot replace a new association or publish after cancellation and close`(
        _ interruption: ScreenClientReadInterruption
    ) async throws {
        let oldClient = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Nombre anterior")
        let newClient = Client.draft(id: ClientID(rawValue: viewModelUUID(601)), displayName: "Nombre actual")
        let original = try viewModelSale(clientID: oldClient.id)
        let repository = InMemorySaleRepository(sales: [original])
        let clients = ScreenClientReadRepository(clients: [oldClient, newClient])
        let model = makeScreenSaleDraftViewModel(repository: repository, clients: clients)
        _ = try await model.load()
        let checkpoint = SaleDraftScreenCheckpoint()
        await clients.holdNextRead(at: checkpoint)
        let pending = Task {
            await model.resolveClientName()
        }
        await checkpoint.waitForEntry()
        do {
            switch interruption {
            case .changedClient:
                _ = try await model.setClient(newClient.id)
                await model.resolveClientName()
            case .cancelled:
                pending.cancel()
            case .closed:
                model.close()
            }
        } catch {
            await checkpoint.release()
            await pending.value
            throw error
        }
        await checkpoint.release()
        await pending.value

        #expect(model.clientDisplayName == (interruption == .changedClient ? "Nombre actual" : nil))
        #expect(model.lastError == nil)
        #expect(try await repository.sale(id: original.id)?.clientID ==
                (interruption == .changedClient ? newClient.id : oldClient.id))
    }

    @Test
    func `unavailable and failed client reads do not hide the sale and explicit resolution can retry`() async throws {
        let client = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Nombre disponible")
        let original = try viewModelSale(clientID: client.id)
        let repository = InMemorySaleRepository(sales: [original])
        let clients = ScreenClientReadRepository(clients: [])
        let model = makeScreenSaleDraftViewModel(repository: repository, clients: clients)
        _ = try await model.load()
        await model.resolveClientName()
        #expect(model.clientDisplayName == nil)
        #expect(model.sale == original)
        #expect(model.contentState == .ready)
        try await clients.saveClient(client)
        await clients.failNextRead()
        await model.resolveClientName()
        #expect(model.clientDisplayName == nil)
        #expect(model.lastError == nil)
        await model.resolveClientName()
        #expect(model.clientDisplayName == "Nombre disponible")
        #expect(model.sale == original)
    }
}

enum ScreenClientReadInterruption { case changedClient, cancelled, closed }

@MainActor
private func makeScreenSaleDraftViewModel(
    repository: any SaleRepository,
    clients: any ClientRepository
) -> SaleDraftViewModel {
    SaleDraftViewModel(
        destination: SaleDraftDestination(
            id: viewModelUUID(500),
            saleID: SaleID(rawValue: viewModelUUID(1)),
            mode: .editDraft
        ),
        createdAt: Date(timeIntervalSince1970: 100),
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: repository),
        getDraft: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository),
        getSale: GetSaleUseCase(repository: repository),
        getClient: GetClientUseCase(repository: clients)
    )
}

actor ScreenClientReadRepository: ClientRepository {
    private let backing: InMemoryClientRepository
    private var readCheckpoint: SaleDraftScreenCheckpoint?
    private var readShouldFail = false

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        await backing.observeClients()
    }

    func client(id: ClientID) async throws -> Client? {
        let held = readCheckpoint
        let shouldFail = readShouldFail
        readCheckpoint = nil
        readShouldFail = false
        let captured = try await backing.client(id: id)
        await held?.block()
        if shouldFail {
            throw ClientError.persistenceUnavailable
        }
        return captured
    }

    func saveClient(_ client: Client) async throws {
        try await backing.saveClient(client)
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        try await backing.createClient(id: id, profile: profile)
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        try await backing.updateClient(id: id, profile: profile)
    }

    func deactivateClient(_ id: ClientID) async throws {
        try await backing.deactivateClient(id)
    }

    func holdNextRead(at checkpoint: SaleDraftScreenCheckpoint) {
        readCheckpoint = checkpoint
    }

    func failNextRead() {
        readShouldFail = true
    }

    init(clients: [Client]) {
        backing = InMemoryClientRepository(clients: clients)
    }
}

private actor SaleDraftScreenReadRepository: SaleRepository {
    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        throw SalePaymentError.persistenceUnavailable
    }

    private let backing: InMemorySaleRepository
    private let checkpoint: SaleDraftScreenCheckpoint

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await backing.observeSales()
    }

    func sale(id: SaleID) async throws -> Sale? {
        let captured = try await backing.sale(id: id)
        await checkpoint.block()
        return captured
    }

    func saveSale(_ sale: Sale) async throws {
        try await backing.saveSale(sale)
    }

    func createDraft(_ draft: Sale) async throws {
        try await backing.createDraft(draft)
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        try await backing.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount
        )
    }

    func discardDraft(_ id: SaleID) async throws {
        try await backing.discardDraft(id)
    }

    init(sales: [Sale], checkpoint: SaleDraftScreenCheckpoint) {
        backing = InMemorySaleRepository(sales: sales)
        self.checkpoint = checkpoint
    }
}

actor SaleDraftScreenCheckpoint {
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
