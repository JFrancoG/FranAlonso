import Foundation
import Testing
@testable import FranAlonso

@Suite("Service picker snapshots", .timeLimit(.minutes(1)))
@MainActor
struct ServicePickerViewModelTests {
    @Test(arguments: [Currency.eur, .usd])
    func `selection resolves visible current identity and retains the complete independent snapshot`(
        currency: Currency
    ) async throws {
        let original = try makeService(
            id: UUID(),
            name: "Corté kit",
            type: .product,
            linkedProductID: UUID(),
            priceAmount: 43.27,
            currency: currency,
            taxPercentage: 7.5,
            discountPercentage: nil
        )
        let professional = try makeService(id: UUID(), name: "Corte profesional")
        let inactive = try makeService(id: UUID(), name: "Corte inactivo", status: .inactive)
        let repository = InMemoryServiceRepository(services: [original, inactive, professional])
        let model = ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        #expect(model.selectService(id: original.id) == nil)
        await model.load()
        model.query = "  CORTE  "
        model.filter = .product
        #expect(model.visibleServices == [original])
        #expect(model.selectService(id: professional.id) == nil)
        #expect(model.selectService(id: inactive.id) == nil)
        #expect(model.selectService(id: ServiceID(rawValue: UUID())) == nil)
        let retained = try #require(model.selectService(id: original.id))
        #expect(retained == original)
        let revised = try makeService(
            id: original.id.rawValue,
            name: "Corte kit revised",
            type: .product,
            linkedProductID: UUID(),
            priceAmount: 51.09,
            currency: currency,
            taxPercentage: 10,
            discountPercentage: 0
        )
        try await repository.saveService(revised)
        await model.load()
        #expect(model.selectService(id: original.id) == revised)
        #expect(retained == original)
        #expect(retained.discount == nil)
        #expect(model.selectService(id: original.id)?.discount?.percentage == 0)
        model.query = "professional"
        #expect(model.selectService(id: original.id) == nil)
        model.query = ""
        try await repository.deactivateService(original.id)
        await model.load()
        #expect(model.selectService(id: original.id) == nil)
        #expect(model.hasNoSearchResults)
        model.filter = .all
        #expect(model.visibleServices == [professional])
        #expect(!model.hasNoSearchResults)
    }

    @Test
    func `empty catalogue differs from a query or type with no results`() async throws {
        let service = try makeService(id: UUID(), name: "Trim")
        let repository = InMemoryServiceRepository(services: [service])
        let model = ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        await model.load()
        model.query = "missing"
        #expect(model.state == .content([service]))
        #expect(model.hasNoSearchResults)
        model.query = ""
        model.filter = .product
        #expect(model.hasNoSearchResults)
        try await repository.deactivateService(service.id)
        await model.load()
        #expect(model.state == .empty)
        #expect(!model.hasNoSearchResults)
        #expect(model.visibleServices.isEmpty)
    }

    @Test(arguments: [ServicePickerTerminal.content, .empty, .finished, .failed, .cancelled])
    func `loading and terminal states prevent stale selection and retain retry filters`(
        _ terminal: ServicePickerTerminal
    ) async throws {
        let service = try makeService(id: UUID(), name: "Corte")
        let pair = AsyncThrowingStream<[Service], any Error>.makeStream()
        let started = AsyncStream<Int>.makeStream()
        let repository = ServicePickerStreamRepository(
            streams: [finishedServiceSnapshot([service]), pair.stream, finishedServiceSnapshot([service])],
            started: started.continuation
        )
        let model = ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        await model.load()
        model.query = "CORTE"
        model.filter = .professional
        var iterator = started.stream.makeAsyncIterator()
        _ = await iterator.next()
        let loading = Task {
            defer { started.continuation.finish() }
            await model.load()
        }
        let didStart = await iterator.next() == 2
        #expect(model.state == .loading)
        #expect(model.selectService(id: service.id) == nil)
        #expect(model.visibleServices.isEmpty)
        finishServicePickerStream(
            pair.continuation,
            terminal: terminal,
            service: service,
            task: loading
        )
        await loading.value
        #expect(didStart)
        switch terminal {
        case .content: #expect(model.state == .content([service]))
        case .empty: #expect(model.state == .empty)
        case .finished, .failed: #expect(model.state == .failed)
        case .cancelled: #expect(model.state == .idle)
        }
        if terminal != .content {
            #expect(model.selectService(id: service.id) == nil)
            #expect(model.visibleServices.isEmpty)
            #expect(!model.hasNoSearchResults)
        }
        await model.load()
        #expect(model.query == "CORTE")
        #expect(model.filter == .professional)
        #expect(model.selectService(id: service.id) == service)
    }

    @Test(arguments: [ServicePickerTerminal.content, .empty, .finished, .failed, .cancelled])
    func `replaced observations cannot overwrite the new selection or state`(
        _ terminal: ServicePickerTerminal
    ) async throws {
        let current = try makeService(id: UUID(), name: "Current")
        let obsolete = try makeService(id: UUID(), name: "Obsolete")
        let pair = AsyncThrowingStream<[Service], any Error>.makeStream()
        let started = AsyncStream<Int>.makeStream()
        let repository = ServicePickerStreamRepository(
            streams: [pair.stream, finishedServiceSnapshot([current])], started: started.continuation
        )
        let model = ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        let old = Task {
            defer { started.continuation.finish() }
            await model.load()
        }
        var iterator = started.stream.makeAsyncIterator()
        let didStart = await iterator.next() == 1
        if didStart {
            await model.load()
        }
        finishServicePickerStream(
            pair.continuation,
            terminal: terminal,
            service: obsolete,
            task: old
        )
        await old.value
        #expect(didStart)
        #expect(model.state == .content([current]))
        #expect(model.selectService(id: current.id) == current)
        #expect(model.selectService(id: obsolete.id) == nil)
    }

    @Test
    func `live emissions replace choices before selection without altering an earlier returned value`() async throws {
        let first = try makeService(id: UUID(), name: "Withdrawn")
        let second = try makeService(id: UUID(), name: "Retained")
        let requests = AsyncStream<Int>.makeStream()
        let channel = ServicePickerSnapshotChannel(requests: requests.continuation)
        let stream = AsyncThrowingStream<[Service], any Error>(unfolding: { await channel.next() })
        let started = AsyncStream<Int>.makeStream()
        let repository = ServicePickerStreamRepository(streams: [stream], started: started.continuation)
        let model = ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        let observation = Task {
            await model.load()
            requests.continuation.finish()
            started.continuation.finish()
        }
        var iterator = requests.stream.makeAsyncIterator()
        let firstRequest = await iterator.next()
        await channel.emit([first, second])
        let secondRequest = await iterator.next()
        let selected = model.selectService(id: first.id)
        let firstChoices = model.visibleServices
        await channel.emit([second])
        let thirdRequest = await iterator.next()
        let withdrawnSelection = model.selectService(id: first.id)
        let retainedSelection = model.selectService(id: second.id)
        let currentChoices = model.visibleServices
        await channel.finish()
        await observation.value
        #expect(firstRequest == 1 && secondRequest == 2 && thirdRequest == 3)
        #expect(firstChoices == [first, second])
        #expect(selected == first)
        #expect(currentChoices == [second])
        #expect(withdrawnSelection == nil)
        #expect(retainedSelection == second)
    }
}

private actor ServicePickerSnapshotChannel {
    private let requests: AsyncStream<Int>.Continuation
    private var waiter: CheckedContinuation<[Service]?, Never>?
    private var buffered: [[Service]] = []
    private var requestCount = 0
    private var finished = false

    init(requests: AsyncStream<Int>.Continuation) {
        self.requests = requests
    }

    func next() async -> [Service]? {
        requestCount += 1
        requests.yield(requestCount)
        if !buffered.isEmpty {
            return buffered.removeFirst()
        }
        guard !finished else { return nil }
        return await withCheckedContinuation { waiter = $0 }
    }

    func emit(_ services: [Service]) {
        if let waiter {
            self.waiter = nil
            waiter.resume(returning: services)
        } else {
            buffered.append(services)
        }
    }

    func finish() {
        finished = true
        waiter?.resume(returning: nil)
        waiter = nil
    }
}

enum ServicePickerTerminal { case content, empty, finished, failed, cancelled }

private func finishedServiceSnapshot(_ services: [Service]) -> AsyncThrowingStream<[Service], any Error> {
    AsyncThrowingStream {
        $0.yield(services)
        $0.finish()
    }
}

private func finishServicePickerStream(
    _ continuation: AsyncThrowingStream<[Service], any Error>.Continuation,
    terminal: ServicePickerTerminal,
    service: Service,
    task: Task<Void, Never>
) {
    switch terminal {
    case .content:
        continuation.yield([service])
        continuation.finish()
    case .empty:
        continuation.yield([])
        continuation.finish()
    case .finished:
        continuation.finish()
    case .failed:
        continuation.finish(throwing: ServiceError.persistenceUnavailable)
    case .cancelled:
        task.cancel()
        continuation.finish()
    }
}

private actor ServicePickerStreamRepository: ServiceRepository {
    private var streams: [AsyncThrowingStream<[Service], any Error>]
    private let started: AsyncStream<Int>.Continuation
    private var count = 0

    init(streams: [AsyncThrowingStream<[Service], any Error>], started: AsyncStream<Int>.Continuation) {
        self.streams = streams
        self.started = started
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        count += 1
        started.yield(count)
        guard !streams.isEmpty else { return finishedServiceSnapshot([]) }
        return streams.removeFirst()
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
}
