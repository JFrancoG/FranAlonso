import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale draft lifecycle")
struct SaleDraftLifecycleTests {
    @Test(arguments: [false, true])
    func `created draft is recoverable from an independent context`(withLines: Bool) async throws {
        let fixture = try SaleDraftFixture()
        let lines = withLines ? try draftLines() : []
        let repository = fixture.repository(operation: 1)
        let created = try await CreateSaleDraftUseCase(repository: repository)(
            id: draftSaleID,
            clientID: nil,
            createdAt: draftCreatedAt,
            lines: lines
        )

        #expect(try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID) == created)
        let recovered = try #require(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)))
        #expect(recovered.status == .draft)
        #expect(recovered.lines == lines)
        #expect(recovered.createdAt.timeIntervalSinceReferenceDate.bitPattern == draftCreatedAtInterval.bitPattern)
        let operations = try fixture.operations()
        #expect(operations.map(\.operationID) == [draftOperationID(1)])
        #expect(operations.first?.base == .absent)
    }

    @Test
    func `editing and discarding preserve captured terms and the causal queue`() async throws {
        let fixture = try SaleDraftFixture()
        let originalLines = try draftLines()
        let createRepository = fixture.repository(operation: 1)
        let original = try await CreateSaleDraftUseCase(repository: createRepository)(
            id: draftSaleID,
            clientID: nil,
            createdAt: draftCreatedAt,
            lines: originalLines
        )
        let changedFirst = try draftLine(quantity: 3, discount: Discount(percentage: 15))
        let added = try draftLine(index: 3)
        let editedLines = [originalLines[1], changedFirst, added]
        let editRepository = fixture.repository(operation: 2)
        let edited = try await UpdateSaleDraftUseCase(repository: editRepository)(
            original,
            clientID: draftClientID,
            lines: editedLines
        )

        let persisted = try #require(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)))
        #expect(persisted == edited)
        #expect(persisted.id == draftSaleID)
        #expect(persisted.clientID == draftClientID)
        #expect(persisted.lines == editedLines)
        #expect(persisted.lines.map(\.serviceName) == [
            "Captured service 2", "Captured service 1", "Captured service 3"
        ])
        #expect(persisted.lines[1].quantity == 3)
        #expect(persisted.lines[1].unitPrice == (try Money(amount: 29.95, currency: .eur)))
        #expect(persisted.lines[1].taxRate == (try TaxRate(percentage: 21)))
        #expect(persisted.createdAt.timeIntervalSinceReferenceDate.bitPattern == draftCreatedAtInterval.bitPattern)

        let discardRepository = fixture.repository(operation: 3)
        try await DiscardSaleDraftUseCase(repository: discardRepository)(draftSaleID)
        try await DiscardSaleDraftUseCase(repository: fixture.repository(operation: 4))(draftSaleID)
        #expect(try await GetSaleDraftUseCase(repository: discardRepository)(id: draftSaleID) == nil)
        #expect(try fixture.source.fetchAll(in: ModelContext(fixture.container)).isEmpty)
        let operations = try fixture.operations()
        #expect(operations.map(\.operationID) == [draftOperationID(1), draftOperationID(2), draftOperationID(3)])
        #expect(operations.map(\.predecessorOperationID) == [nil, draftOperationID(1), draftOperationID(2)])
        guard case .discard = try #require(operations.last) else {
            Issue.record("Discard must retain a durable tombstone after its local snapshot disappears")
            return
        }
    }

    @Test
    func `obsolete edit cannot overwrite an accepted draft`() async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        try fixture.source.createDraft(original, operationID: draftOperationID(1), in: ModelContext(fixture.container))
        let repository = fixture.repository(operation: 2)
        let accepted = try await UpdateSaleDraftUseCase(repository: repository)(
            original,
            clientID: draftClientID,
            lines: [draftLine(quantity: 2)]
        )
        let before = try fixture.operations()

        await #expect(throws: SaleDraftError.staleDraft) {
            _ = try await UpdateSaleDraftUseCase(repository: repository)(original, clientID: nil, lines: [])
        }
        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == accepted)
        #expect(try fixture.operations() == before)
    }

    @Test(arguments: [DraftProgressedState.inProgress, .awaitingPayment, .awaitingDocument, .closed, .voided])
    func `progressed sale rejects draft recovery editing and discard`(state: DraftProgressedState) async throws {
        let fixture = try SaleDraftFixture()
        let progressed = try draftSale(progressedTo: state)
        try fixture.source.upsert(progressed, in: ModelContext(fixture.container))
        let repository = fixture.repository(operation: 1)

        await #expect(throws: SaleDraftError.requiresDraft) {
            _ = try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID)
        }
        await #expect(throws: SaleDraftError.requiresDraft) {
            _ = try await UpdateSaleDraftUseCase(repository: repository)(progressed, clientID: nil, lines: [])
        }
        await #expect(throws: SaleDraftError.requiresDraft) {
            try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
        }
        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == progressed)
        #expect(try fixture.operations().isEmpty)
    }

    @Test(arguments: [DraftSnapshotChange.serviceID, .name, .price, .tax, .product])
    func `retained line cannot refresh its captured commercial terms`(change: DraftSnapshotChange) async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        try fixture.source.createDraft(original, operationID: draftOperationID(1), in: ModelContext(fixture.container))
        let before = try fixture.operations()
        let changed = try draftLine(changing: change)

        await #expect(throws: SaleError.invalidDraftState) {
            _ = try await UpdateSaleDraftUseCase(repository: fixture.repository(operation: 2))(
                original,
                clientID: nil,
                lines: [changed]
            )
        }
        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == original)
        #expect(try fixture.operations() == before)
    }

    @Test(arguments: [DraftKnownIdentity.local, .pendingOnly, .remoteOnly, .tombstone, .conflict, .pendingDiscard])
    func `creation refuses every previously known identity`(identity: DraftKnownIdentity) async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        try fixture.seed(identity, sale: original)
        let before = try fixture.storedState()

        await #expect(throws: SaleDraftError.alreadyExists) {
            _ = try await CreateSaleDraftUseCase(repository: fixture.repository(operation: 2))(
                id: draftSaleID,
                clientID: draftClientID,
                createdAt: draftCreatedAt,
                lines: []
            )
        }
        #expect(try fixture.storedState() == before)
    }

    @Test
    func `conflict is retained before editing or repeating an existing discard`() async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        let context = ModelContext(fixture.container)
        try fixture.source.createDraft(original, operationID: draftOperationID(1), in: context)
        try fixture.source.discardDraft(draftSaleID, operationID: draftOperationID(2), in: context)
        let discard = try #require(try fixture.operations().last)
        try fixture.source.recordConflict(
            operation: discard,
            reason: .baseChanged,
            remoteRecord: nil,
            in: context
        )
        let before = try fixture.storedState()
        let repository = fixture.repository(operation: 3)

        await #expect(throws: SaleDraftError.conflict) {
            _ = try await UpdateSaleDraftUseCase(repository: repository)(original, clientID: nil, lines: [])
        }
        await #expect(throws: SaleDraftError.conflict) {
            try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
        }
        #expect(try fixture.storedState() == before)
    }

    @Test
    func `missing draft can be read or discarded but cannot be edited`() async throws {
        let fixture = try SaleDraftFixture()
        let repository = fixture.repository(operation: 1)
        let expected = try draftSale()

        #expect(try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID) == nil)
        try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
        await #expect(throws: SaleDraftError.notFound) {
            _ = try await UpdateSaleDraftUseCase(repository: repository)(expected, clientID: nil, lines: [])
        }
        #expect(try fixture.source.fetchAll(in: ModelContext(fixture.container)).isEmpty)
        #expect(try fixture.operations().isEmpty)
    }

    @Test(arguments: [DraftKnownIdentity.tombstone, .pendingDiscard])
    func `deleted draft cannot be resurrected by editing an older copy`(identity: DraftKnownIdentity) async throws {
        let fixture = try SaleDraftFixture()
        let expected = try draftSale()
        try fixture.seed(identity, sale: expected)
        let before = try fixture.storedState()

        await #expect(throws: SaleDraftError.deleted) {
            _ = try await UpdateSaleDraftUseCase(repository: fixture.repository(operation: 3))(
                expected,
                clientID: draftClientID,
                lines: []
            )
        }
        #expect(try fixture.storedState() == before)
    }

    @Test(arguments: [
        (DraftInvalidInput.duplicateLines, SaleError.invalidDraftState),
        (.progressedLine, .invalidDraftState),
        (.nonfiniteCreationDate, .invalidTimestamp)
    ])
    func `invalid creation has no local effect`(input: DraftInvalidInput, error: SaleError) async throws {
        let fixture = try SaleDraftFixture()
        let lines = try invalidDraftLines(for: input)
        let date = input == .nonfiniteCreationDate ? Date(timeIntervalSinceReferenceDate: .infinity) : draftCreatedAt

        await #expect(throws: error) {
            _ = try await CreateSaleDraftUseCase(repository: fixture.repository(operation: 1))(
                id: draftSaleID,
                clientID: nil,
                createdAt: date,
                lines: lines
            )
        }
        #expect(try fixture.source.fetchAll(in: ModelContext(fixture.container)).isEmpty)
        #expect(try fixture.operations().isEmpty)
    }

    @Test(arguments: [DraftInvalidInput.duplicateLines, .progressedLine])
    func `invalid edit preserves the accepted snapshot and queue`(input: DraftInvalidInput) async throws {
        let fixture = try SaleDraftFixture()
        let expected = try draftSale()
        try fixture.source.createDraft(expected, operationID: draftOperationID(1), in: ModelContext(fixture.container))
        let before = try fixture.storedState()
        let lines = try invalidDraftLines(for: input)

        await #expect(throws: SaleError.invalidDraftState) {
            _ = try await UpdateSaleDraftUseCase(repository: fixture.repository(operation: 2))(
                expected,
                clientID: draftClientID,
                lines: lines
            )
        }
        #expect(try fixture.storedState() == before)
    }

    @Test
    func `replacing a removed line with a new identity accepts new captured terms`() async throws {
        let fixture = try SaleDraftFixture()
        let expected = try draftSale()
        try fixture.source.createDraft(expected, operationID: draftOperationID(1), in: ModelContext(fixture.container))
        let replacement = try draftLine(index: 5, changing: .name)

        let edited = try await UpdateSaleDraftUseCase(repository: fixture.repository(operation: 2))(
            expected,
            clientID: nil,
            lines: [replacement]
        )

        #expect(edited.lines == [replacement])
        #expect(edited.lines.first?.serviceName == "Current catalogue name")
        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == edited)
        #expect(try fixture.operations().map(\.operationID) == [draftOperationID(1), draftOperationID(2)])
    }

    @Test(arguments: [DraftMutation.create, .update, .discard])
    func `failed local acceptance rolls back materialization and pending operation`(mutation: DraftMutation) throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        let context = ModelContext(fixture.container)
        if mutation != .create {
            try fixture.source.createDraft(original, operationID: draftOperationID(1), in: context)
        }
        let poison = try SaleModel(
            Sale.draft(
                id: SaleID(rawValue: draftUUID(999)),
                clientID: nil,
                createdAt: draftCreatedAt,
                lines: []
            )
        )
        poison.linesPayloadVersion = 3
        #expect(throws: SaleModelPayloadError.unsupportedLinesVersion(3)) {
            _ = try poison.toDomain()
        }
        context.insert(poison)
        try context.save()
        let beforeOperations = try fixture.operations()
        let beforeCount = try ModelContext(fixture.container).fetchCount(FetchDescriptor<SaleModel>())

        #expect(throws: SaleDraftError.persistenceUnavailable) {
            try applyDraftMutation(mutation, original: original, source: fixture.source, in: context)
        }
        #expect(!context.hasChanges)
        let verification = ModelContext(fixture.container)
        #expect(try verification.fetchCount(FetchDescriptor<SaleModel>()) == beforeCount)
        #expect(try fixture.operations() == beforeOperations)
        #expect(try fixture.source.sale(id: draftSaleID, in: verification) == (mutation == .create ? nil : original))
    }

    @Test
    func `colliding operation identity cannot leave a new draft behind`() throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        let context = ModelContext(fixture.container)
        try fixture.source.createDraft(original, operationID: draftOperationID(1), in: context)
        let second = try Sale.draft(
            id: SaleID(rawValue: draftUUID(101)),
            clientID: nil,
            createdAt: draftCreatedAt,
            lines: []
        )

        #expect(throws: SaleDraftError.persistenceUnavailable) {
            try fixture.source.createDraft(second, operationID: draftOperationID(1), in: context)
        }
        #expect(try fixture.source.fetchAll(in: ModelContext(fixture.container)) == [original])
        #expect(try fixture.operations().map(\.operationID) == [draftOperationID(1)])
        #expect(!context.hasChanges)
    }

    @Test(arguments: [DraftCommand.create, .get, .update, .discard])
    func `cancelled use case does not accept local work`(command: DraftCommand) async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        if command != .create {
            try fixture.source.createDraft(
                original,
                operationID: draftOperationID(1),
                in: ModelContext(fixture.container)
            )
        }
        let before = try fixture.storedState()
        let repository = fixture.repository(operation: 2)
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            try await applyDraftCommand(command, original: original, repository: repository)
        }
        task.cancel()
        gate.continuation.yield(())
        gate.continuation.finish()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try fixture.storedState() == before)
    }

    @Test(arguments: [DraftMutation.create, .update, .discard])
    func `cancelled task is rejected inside the persistence actor after the hop`(mutation: DraftMutation) async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        if mutation != .create {
            try fixture.source.createDraft(
                original,
                operationID: draftOperationID(1),
                in: ModelContext(fixture.container)
            )
        }
        let before = try fixture.storedState()
        let actor = fixture.actor
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            switch mutation {
            case .create:
                try await actor.createDraft(original, operationID: draftOperationID(2))
            case .update:
                _ = try await actor.updateDraft(
                    original,
                    clientID: draftClientID,
                    lines: [],
                    operationID: draftOperationID(2)
                )
            case .discard:
                try await actor.discardDraft(draftSaleID, operationID: draftOperationID(2))
            }
        }
        task.cancel()
        gate.continuation.yield(())
        gate.continuation.finish()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try fixture.storedState() == before)
    }

    @Test
    @MainActor
    func `contextual commands commit the same draft lifecycle as the actor route`() async throws {
        let fixture = try SaleDraftFixture()
        let original = try draftSale()
        let context = ModelContext(fixture.container)
        let createAdapter = SaleContextualPersistenceAdapter(
            observationSignal: SaleObservationSignal(),
            operationID: { draftOperationID(1) }
        )
        try await createAdapter.createDraft(original, in: context)
        let updateAdapter = SaleContextualPersistenceAdapter(
            observationSignal: SaleObservationSignal(),
            operationID: { draftOperationID(2) }
        )
        let edited = try await updateAdapter.updateDraft(
            original,
            clientID: draftClientID,
            lines: [],
            in: context
        )

        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == edited)
        #expect(try await GetSaleDraftUseCase(repository: fixture.repository(operation: 3))(id: draftSaleID) == edited)
        let discardAdapter = SaleContextualPersistenceAdapter(
            observationSignal: SaleObservationSignal(),
            operationID: { draftOperationID(3) }
        )
        try await discardAdapter.discardDraft(draftSaleID, in: context)
        try await discardAdapter.discardDraft(draftSaleID, in: context)

        #expect(try fixture.source.sale(id: draftSaleID, in: ModelContext(fixture.container)) == nil)
        #expect(try fixture.operations().map(\.operationID) == [
            draftOperationID(1), draftOperationID(2), draftOperationID(3)
        ])
        #expect(!context.hasChanges)
    }

    @Test
    func `in memory repository preserves stale protection and discarded identity`() async throws {
        let repository = InMemorySaleRepository()
        let created = try await CreateSaleDraftUseCase(repository: repository)(
            id: draftSaleID,
            clientID: nil,
            createdAt: draftCreatedAt,
            lines: draftLines()
        )
        let edited = try await UpdateSaleDraftUseCase(repository: repository)(
            created,
            clientID: draftClientID,
            lines: []
        )
        await #expect(throws: SaleDraftError.staleDraft) {
            _ = try await UpdateSaleDraftUseCase(repository: repository)(created, clientID: nil, lines: [])
        }
        #expect(try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID) == edited)
        try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
        try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
        #expect(try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID) == nil)
        await #expect(throws: SaleDraftError.alreadyExists) {
            try await repository.createDraft(created)
        }
        let stream = await ObserveSalesUseCase(repository: repository)()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == [])
    }
}

enum DraftProgressedState {
    case inProgress, awaitingPayment, awaitingDocument, closed, voided
}

enum DraftSnapshotChange {
    case serviceID, name, price, tax, product
}

enum DraftKnownIdentity {
    case local, pendingOnly, remoteOnly, tombstone, conflict, pendingDiscard
}

enum DraftInvalidInput {
    case duplicateLines, progressedLine, nonfiniteCreationDate
}

enum DraftMutation {
    case create, update, discard
}

enum DraftCommand {
    case create, get, update, discard
}

private let draftCreatedAtInterval = 0.000_000_123_456_789
private let draftCreatedAt = Date(timeIntervalSinceReferenceDate: draftCreatedAtInterval)
private let draftSaleID = SaleID(rawValue: draftUUID(100))
private let draftClientID = ClientID(rawValue: draftUUID(200))

private struct SaleDraftFixture {
    let container: ModelContainer
    let actor: SalePersistenceActor
    let source = SaleLocalDataSource()

    func repository(operation: Int) -> DefaultSaleRepository {
        DefaultSaleRepository(
            persistenceActor: actor,
            observationSignal: SaleObservationSignal(),
            operationID: { draftOperationID(operation) }
        )
    }

    func operations() throws -> [SalePendingOperation] {
        try source.pendingOperations(in: ModelContext(container))
    }

    func storedState() throws -> DraftStoredState {
        let context = ModelContext(container)
        return try DraftStoredState(
            sales: source.fetchAll(in: context),
            operations: source.pendingOperations(in: context),
            remoteRecords: context.fetch(FetchDescriptor<SaleRemoteStateModel>()).map { try $0.decodeRecord() },
            conflicts: context.fetch(FetchDescriptor<SaleSyncConflictModel>()).map { try $0.decodeOperation() }
        )
    }

    func seed(_ identity: DraftKnownIdentity, sale: Sale) throws {
        let context = ModelContext(container)
        let operation = SalePendingOperation.upsert(
            SalePendingUpsert(
                saleID: sale.id.rawValue,
                operationID: draftOperationID(1),
                predecessorOperationID: nil,
                base: .absent,
                sale: try SaleDTO(sale)
            )
        )
        switch identity {
        case .local:
            context.insert(try SaleModel(sale))
        case .pendingOnly:
            context.insert(
                try SalePendingUpsertModel(
                    saleID: sale.id.rawValue,
                    operationID: draftOperationID(1),
                    base: .absent,
                    payload: SaleDTO(sale)
                )
            )
        case .remoteOnly:
            context.insert(
                try SaleRemoteStateModel(
                    record: SaleRemoteRecord(sale: SaleDTO(sale), version: .versioned(
                        revision: 1,
                        lastOperationID: draftOperationID(1)
                    ))
                )
            )
        case .tombstone:
            context.insert(
                try SaleRemoteStateModel(
                    record: SaleRemoteRecord(
                        content: .tombstone(saleID: sale.id.rawValue),
                        version: .versioned(revision: 1, lastOperationID: draftOperationID(1)),
                        changeSequence: 1
                    )
                )
            )
        case .conflict:
            context.insert(try SaleSyncConflictModel(operation: operation, reason: .baseChanged, remoteRecord: nil))
        case .pendingDiscard:
            context.insert(
                try SalePendingDiscardModel(
                    saleID: sale.id.rawValue,
                    operationID: draftOperationID(1),
                    predecessorOperationID: nil,
                    base: .absent
                )
            )
        }
        try context.save()
    }
}

private extension SaleDraftFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        self.init(container: container, actor: SalePersistenceActor(modelContainer: container))
    }
}

private struct DraftStoredState: Equatable {
    let sales: [Sale]
    let operations: [SalePendingOperation]
    let remoteRecords: [SaleRemoteRecord]
    let conflicts: [SalePendingOperation]
}

private func draftLines() throws -> [SaleLine] {
    try [draftLine(), draftLine(index: 2)]
}

private func draftLine(
    index: Int = 1,
    quantity: Int = 1,
    discount: Discount? = nil,
    changing change: DraftSnapshotChange? = nil
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: draftUUID(index)),
        serviceID: ServiceID(rawValue: draftUUID(change == .serviceID ? 999 : 10 + index)),
        serviceName: change == .name ? "Current catalogue name" : "Captured service \(index)",
        quantity: quantity,
        unitPrice: Money(amount: change == .price ? 99 : 29.95, currency: .eur),
        taxRate: TaxRate(percentage: change == .tax ? 10 : 21),
        discount: discount,
        linkedProductID: ProductID(rawValue: draftUUID(change == .product ? 998 : 20 + index))
    )
}

private func draftSale(progressedTo state: DraftProgressedState? = nil) throws -> Sale {
    let line = try draftLine()
    var sale = try Sale.draft(
        id: draftSaleID,
        clientID: nil,
        createdAt: draftCreatedAt,
        lines: [line]
    )
    guard let state else { return sale }
    try sale.start()
    try sale.startLine(id: line.id)
    guard state != .inProgress else { return sale }
    try sale.completeLine(id: line.id)
    guard state != .awaitingPayment else { return sale }
    try sale.registerPayment(id: PaymentID(rawValue: draftUUID(300)), method: .card, paidAt: draftCreatedAt)
    guard state != .awaitingDocument else { return sale }
    try sale.close(documentID: BillingDocumentID(rawValue: draftUUID(301)), closedAt: draftCreatedAt)
    guard state != .closed else { return sale }
    try sale.void(reversalID: SaleReversalID(rawValue: draftUUID(302)), voidedAt: draftCreatedAt)
    return sale
}

private func invalidDraftLines(for input: DraftInvalidInput) throws -> [SaleLine] {
    var line = try draftLine()
    switch input {
    case .duplicateLines:
        return [line, line]
    case .progressedLine:
        try line.start()
        return [line]
    case .nonfiniteCreationDate:
        return []
    }
}

private func applyDraftMutation(
    _ mutation: DraftMutation,
    original: Sale,
    source: SaleLocalDataSource,
    in context: ModelContext
) throws {
    switch mutation {
    case .create:
        try source.createDraft(original, operationID: draftOperationID(2), in: context)
    case .update:
        _ = try source.updateDraft(
            original,
            clientID: draftClientID,
            lines: [],
            operationID: draftOperationID(2),
            in: context
        )
    case .discard:
        try source.discardDraft(draftSaleID, operationID: draftOperationID(2), in: context)
    }
}

private func applyDraftCommand(_ command: DraftCommand, original: Sale, repository: any SaleRepository) async throws {
    switch command {
    case .create:
        _ = try await CreateSaleDraftUseCase(repository: repository)(
            id: draftSaleID,
            clientID: nil,
            createdAt: draftCreatedAt,
            lines: []
        )
    case .get:
        _ = try await GetSaleDraftUseCase(repository: repository)(id: draftSaleID)
    case .update:
        _ = try await UpdateSaleDraftUseCase(repository: repository)(original, clientID: draftClientID, lines: [])
    case .discard:
        try await DiscardSaleDraftUseCase(repository: repository)(draftSaleID)
    }
}

private func draftOperationID(_ value: Int) -> UUID { draftUUID(1_000 + value) }

private func draftUUID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "11000000-0000-0000-0000-%012d", value))!
}
