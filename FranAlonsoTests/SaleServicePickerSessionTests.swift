import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale service picker session", .timeLimit(.minutes(1)))
@MainActor
struct SaleServicePickerSessionTests {
    @Test
    func `failed local acceptance retries the original line identity and frozen terms once`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.product.service(currency: .eur)
        let services = InMemoryServiceRepository(services: [service])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: services, draft: draft)
        await selection.picker.load()
        await sales.failNextUpdate()
        selection.requestSelection(id: service.id)
        await selection.submitSelection()
        #expect(selection.hasSelectionError)
        #expect(try await sales.sale(id: original.id) == original)
        try await services.saveService(SaleServiceSelectionOffering.product.service(currency: .eur, revised: true))
        await selection.picker.load()
        selection.retrySelection()
        await selection.submitSelection()

        let accepted = try #require(try await sales.sale(id: original.id))
        let line = try #require(accepted.lines.first)
        let attempts = await sales.updateAttempts
        #expect(attempts.count == 2)
        #expect(attempts.first == attempts.last)
        #expect(accepted.lines.count == 1)
        #expect(line.id == SaleLineID(rawValue: viewModelUUID(7_806)))
        #expect(line.serviceName == "Kit original")
        #expect(line.unitPrice.amount == (try viewModelDecimal("43.27")))
        #expect(line.discount?.percentage == 0)
        #expect(line.linkedProductID == ProductID(rawValue: viewModelUUID(7_802)))
        #expect(selection.hasAcceptedSelection)
        #expect(!selection.hasSelectionError)
    }

    @Test
    func `picker navigation writes nothing and finishing preserves the accepted parent session`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = ViewModelSaleRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        #expect(draft.canAddServices)
        draft.presentServicePicker()
        let first = try #require(draft.servicePickerDestination)
        draft.finishServicePicker(first.id)
        #expect(draft.servicePickerDestination == nil)
        #expect(!draft.isClosed)
        #expect(draft.sale == original)
        #expect(await sales.writeCount == 0)
        draft.presentServicePicker()
        let reopened = try #require(draft.servicePickerDestination)
        #expect(reopened.id != first.id)
        draft.finishServicePicker(first.id)
        #expect(draft.servicePickerDestination == reopened)
        draft.close()
        #expect(draft.servicePickerDestination == nil)
        #expect(try await sales.sale(id: original.id) == original)
        #expect(await sales.writeCount == 0)
    }

    @Test
    func `double taps and concurrent submissions append once and retain the task identity while adding`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: InMemoryServiceRepository(services: [service]), draft: draft)
        await selection.loadCatalogue()
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        selection.requestSelection(id: service.id)
        let requestID = try #require(selection.selectionRequestID)
        selection.requestSelection(id: service.id)
        #expect(selection.selectionRequestID == requestID)
        let pending = Task {
            await selection.submitSelection()
        }
        await checkpoint.waitForEntry()
        #expect(selection.isBusy)
        #expect(!selection.canSelectServices)
        #expect(selection.selectionRequestID == requestID)
        selection.requestSelection(id: service.id)
        await selection.submitSelection()
        await checkpoint.release()
        await pending.value
        selection.requestSelection(id: service.id)
        selection.retrySelection()
        await selection.submitSelection()

        #expect(await sales.updateAttempts.count == 1)
        #expect(try await sales.sale(id: original.id)?.lines.count == 1)
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("12.10")))
        #expect(selection.hasAcceptedSelection)
        #expect(selection.selectionRequestID == nil)
    }

    @Test
    func `caller cancellation before acceptance leaves the parent unchanged and offers no failed retry`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: InMemoryServiceRepository(services: [service]), draft: draft)
        await selection.loadCatalogue()
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        selection.requestSelection(id: service.id)
        let pending = Task {
            await selection.submitSelection()
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()
        await pending.value
        selection.retrySelection()
        await selection.submitSelection()

        #expect(selection.canSelectServices)
        #expect(!selection.hasSelectionError)
        #expect(!selection.hasAcceptedSelection)
        #expect(!selection.isBusy)
        #expect(await sales.updateAttempts.count == 1)
        #expect(draft.sale == original)
        #expect(try await sales.sale(id: original.id) == original)
    }

    @Test(arguments: [false, true])
    func `durable acceptance survives cancellation and closed selectors never republish or retry`(
        closed: Bool
    ) async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: InMemoryServiceRepository(services: [service]), draft: draft)
        await selection.loadCatalogue()
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .after)
        selection.requestSelection(id: service.id)
        let pending = Task {
            await selection.submitSelection()
        }
        await checkpoint.waitForEntry()
        if closed {
            selection.close()
        }
        pending.cancel()
        await checkpoint.release()
        await pending.value
        selection.retrySelection()
        await selection.submitSelection()

        #expect(await sales.updateAttempts.count == 1)
        #expect(try await sales.sale(id: original.id)?.lines.count == 1)
        #expect(draft.sale?.lines.count == 1)
        #expect(!draft.isClosed)
        #expect(!selection.hasSelectionError)
        #expect(selection.hasAcceptedSelection == !closed)
        #expect(selection.selectionState == (closed ? .closed : .accepted))
        if closed {
            #expect(selection.observationRequestID == nil)
            #expect(!selection.canSelectServices)
        }
    }

    @Test(arguments: [SaleSelectionInvisibleChoice.unknown, .inactive, .filtered])
    func `identities absent from the current visible catalogue never reach sale acceptance`(
        choice: SaleSelectionInvisibleChoice
    ) async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let inactive = try makeService(id: viewModelUUID(7_809), status: .inactive)
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let services = InMemoryServiceRepository(services: [service, inactive])
        let selection = saleSelectionCoordinator(services: services, draft: draft)
        await selection.loadCatalogue()
        if choice == .filtered {
            selection.picker.filter = .product
        }
        let id: ServiceID
        switch choice {
        case .unknown: id = ServiceID(rawValue: viewModelUUID(7_810))
        case .inactive: id = inactive.id
        case .filtered: id = service.id
        }
        selection.requestSelection(id: id)
        await selection.submitSelection()

        #expect(selection.isSelectionUnavailable)
        #expect(!selection.hasSelectionError)
        #expect(await sales.updateAttempts.isEmpty)
        #expect(try await sales.sale(id: original.id) == original)
    }

    @Test
    func `currency rejection keeps the sale untouched and frozen retry cannot change its terms`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let service = try SaleServiceSelectionOffering.professional.service(currency: .usd)
        let services = InMemoryServiceRepository(services: [service])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let selection = saleSelectionCoordinator(services: services, draft: draft)
        await selection.loadCatalogue()
        selection.requestSelection(id: service.id)
        await selection.submitSelection()
        #expect(selection.hasSelectionError)
        try await services.saveService(SaleServiceSelectionOffering.professional.service(currency: .eur))
        await selection.loadCatalogue()
        selection.retrySelection()
        await selection.submitSelection()

        #expect(selection.hasSelectionError)
        #expect(draft.lastError as? SaleCalculatorError == .incompatibleCurrency(expected: .eur, actual: .usd))
        #expect(await sales.updateAttempts.isEmpty)
        #expect(draft.sale == original)
        #expect(try await sales.sale(id: original.id) == original)
    }

    @Test(arguments: [SaleSelectionUnavailableParent.uncreated, .missing, .inspection, .closed])
    func `unavailable parent sessions cannot present a picker or submit a service`(
        condition: SaleSelectionUnavailableParent
    ) async throws {
        var original = try saleSelectionEmptyDraft()
        if condition == .inspection {
            original = try original.replacingDraft(clientID: nil, lines: [viewModelLine()])
            try original.start()
        }
        let sales = SaleSelectionControlledRepository(
            sales: condition == .missing || condition == .uncreated ? [] : [original]
        )
        let mode: SaleDraftDestination.Mode = switch condition {
        case .uncreated: .create
        case .inspection: .inspect
        case .missing, .closed: .editDraft
        }
        let draft = saleSelectionDraft(repository: sales, mode: mode)
        _ = try await draft.load()
        if condition == .closed {
            draft.close()
        }
        draft.presentServicePicker()
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let selection = saleSelectionCoordinator(services: InMemoryServiceRepository(services: [service]), draft: draft)
        await selection.loadCatalogue()
        selection.requestSelection(id: service.id)
        await selection.submitSelection()

        #expect(!draft.canAddServices)
        #expect(draft.servicePickerDestination == nil)
        #expect(!selection.canSelectServices)
        #expect(selection.isSelectionUnavailable)
        #expect(await sales.updateAttempts.isEmpty)
    }

    @Test(arguments: [false, true])
    func `parent occupancy rejects selection both when requested and when its task begins`(
        alreadyRequested: Bool
    ) async throws {
        let original = try saleSelectionEmptyDraft().replacingDraft(clientID: nil, lines: [viewModelLine()])
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        let selection = saleSelectionCoordinator(services: InMemoryServiceRepository(services: [service]), draft: draft)
        await selection.loadCatalogue()
        if alreadyRequested {
            selection.requestSelection(id: service.id)
        }
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        let updating = Task {
            try await draft.setQuantity(2, for: original.lines[0].id)
        }
        await checkpoint.waitForEntry()
        #expect(!draft.canAddServices)
        draft.presentServicePicker()
        #expect(draft.servicePickerDestination == nil)
        if !alreadyRequested {
            selection.requestSelection(id: service.id)
        }
        await selection.submitSelection()
        await checkpoint.release()
        _ = try await updating.value

        #expect(selection.isSelectionUnavailable)
        #expect(await sales.updateAttempts.count == 1)
        #expect(try await sales.sale(id: original.id)?.lines.count == 1)
        #expect(draft.sale?.lines[0].quantity == 2)
        #expect(draft.canAddServices)
    }

    @Test
    func `closing cancels caller catalogue observation and late choices cannot reopen or write`() async throws {
        let original = try saleSelectionEmptyDraft()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let snapshots = AsyncThrowingStream<[Service], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let services = SaleSelectionCatalogueRepository(stream: snapshots.stream, started: started.continuation)
        let selection = saleSelectionCoordinator(services: services, draft: draft)
        let observing = Task {
            await selection.loadCatalogue()
        }
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
        selection.close()
        observing.cancel()
        let lateService = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        snapshots.continuation.yield([lateService])
        snapshots.continuation.finish()
        await observing.value
        selection.reloadCatalogue()
        await selection.loadCatalogue()
        selection.requestSelection(id: lateService.id)
        await selection.submitSelection()

        #expect(selection.selectionState == .closed)
        #expect(selection.observationRequestID == nil)
        #expect(selection.selectionRequestID == nil)
        #expect(!selection.canSelectServices)
        #expect(!selection.hasSelectionError)
        #expect(selection.picker.visibleServices.isEmpty)
        #expect(await sales.updateAttempts.isEmpty)
        #expect(!draft.isClosed)
        #expect(draft.sale == original)
        #expect(try await sales.sale(id: original.id) == original)
    }
}

enum SaleSelectionInvisibleChoice { case unknown, inactive, filtered }
enum SaleSelectionUnavailableParent { case uncreated, missing, inspection, closed }

private actor SaleSelectionCatalogueRepository: ServiceRepository {
    private let stream: AsyncThrowingStream<[Service], any Error>
    private let started: AsyncStream<Void>.Continuation

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        started.yield(())
        started.finish()
        return stream
    }

    func service(id: ServiceID) async throws -> Service? { nil }
    func saveService(_ service: Service) async throws { throw ServiceError.persistenceUnavailable }
    func createService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        throw ServiceError.persistenceUnavailable
    }
    func updateService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        throw ServiceError.persistenceUnavailable
    }
    func deactivateService(_ id: ServiceID) async throws { throw ServiceError.persistenceUnavailable }

    init(
        stream: AsyncThrowingStream<[Service], any Error>,
        started: AsyncStream<Void>.Continuation
    ) {
        self.stream = stream
        self.started = started
    }
}
