import Foundation
import Testing
@testable import FranAlonso

@Suite("Service list and form sessions", .timeLimit(.minutes(1)))
@MainActor
struct ServiceListViewModelTests {
    @Test
    func `search retains inactive offerings and follows current snapshots`() async throws {
        let active = try makeService(name: "Corté", type: .professional)
        let inactive = try makeService(
            id: UUID(),
            name: "Shampoo",
            type: .product,
            linkedProductID: UUID(),
            status: .inactive
        )
        let repository = InMemoryServiceRepository(services: [active, inactive])
        let model = ServiceListViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        await model.load()
        #expect(model.state == .content([active, inactive]))
        model.query = "CORTE"
        #expect(model.visibleServices == [active])
        model.query = "shampoo"
        #expect(model.visibleServices == [inactive])
        model.query = "Absent"
        #expect(model.hasNoSearchResults)
        let newer = try makeService(id: UUID(), name: "Absent before")
        try await repository.saveService(newer)
        await model.load()
        #expect(model.visibleServices == [newer])
        #expect(!model.hasNoSearchResults)
    }

    @Test(arguments: [ServiceListTerminal.empty, .finished, .failed, .cancelled])
    func `empty completion error and cancellation remain distinguishable`(_ terminal: ServiceListTerminal) async {
        let pair = AsyncThrowingStream<[Service], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceListStreamStub(first: pair.stream, started: started.continuation, current: [])
        let model = ServiceListViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        let loading = Task {
            defer {
                started.continuation.finish()
            }
            await model.load()
        }
        var iterator = started.stream.makeAsyncIterator()
        #expect(await iterator.next() != nil)
        switch terminal {
        case .empty:
            pair.continuation.yield([])
            pair.continuation.finish()
        case .finished:
            pair.continuation.finish()
        case .failed:
            pair.continuation.finish(throwing: ServiceError.persistenceUnavailable)
        case .cancelled:
            loading.cancel()
            pair.continuation.finish()
        }
        await loading.value
        switch terminal {
        case .empty, .finished: #expect(model.state == .empty)
        case .failed: #expect(model.state == .failed)
        case .cancelled: #expect(model.state == .idle)
        }
        #expect(!model.hasNoSearchResults)
    }

    @Test(arguments: [ServiceListTerminal.empty, .finished, .failed, .cancelled])
    func `obsolete observations cannot replace the current catalogue or its state`(
        _ terminal: ServiceListTerminal
    ) async throws {
        let current = try makeService(name: "Current", status: .inactive)
        let pair = AsyncThrowingStream<[Service], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceListStreamStub(first: pair.stream, started: started.continuation, current: [current])
        let model = ServiceListViewModel(observeServices: ObserveServicesUseCase(repository: repository))
        let old = Task {
            defer {
                started.continuation.finish()
            }
            await model.load()
        }
        var iterator = started.stream.makeAsyncIterator()
        let didStart = await iterator.next() != nil
        if didStart {
            await model.load()
        }
        switch terminal {
        case .empty:
            pair.continuation.yield([])
            pair.continuation.finish()
        case .finished:
            pair.continuation.finish()
        case .failed:
            pair.continuation.finish(throwing: ServiceError.persistenceUnavailable)
        case .cancelled:
            old.cancel()
            pair.continuation.finish()
        }
        await old.value
        #expect(didStart)
        #expect(model.state == .content([current]))
        #expect(model.visibleServices == [current])
    }

    @Test
    func `session identity survives repeated opening and delayed dismissal`() throws {
        let ids = (0..<4).map { _ in UUID() }
        var remaining = ids
        let model = ServiceListViewModel(
            observeServices: ObserveServicesUseCase(repository: InMemoryServiceRepository()),
            makeID: {
                remaining.removeFirst()
            }
        )
        model.beginCreatingService()
        let first = try #require(model.formDestination)
        model.beginCreatingService()
        #expect(model.formDestination == first)
        #expect(first.id == ids[0])
        #expect(first.serviceID == ServiceID(rawValue: ids[1]))
        model.finishFormSession(first.id)
        model.beginCreatingService()
        let second = try #require(model.formDestination)
        model.finishFormSession(first.id)
        #expect(model.formDestination == second)
        #expect(second.id == ids[2])
        #expect(second.serviceID == ServiceID(rawValue: ids[3]))
    }

    @Test
    func `editing requires a visible identity and cannot replace an open form`() async throws {
        let service = try makeService(name: "Visible", status: .inactive)
        let model = ServiceListViewModel(
            observeServices: ObserveServicesUseCase(repository: InMemoryServiceRepository(services: [service]))
        )
        model.beginEditingService(service.id)
        #expect(model.formDestination == nil)
        await model.load()
        model.query = "No match"
        model.beginEditingService(service.id)
        #expect(model.formDestination == nil)
        model.query = "Visible"
        model.beginEditingService(service.id)
        let destination = try #require(model.formDestination)
        #expect(destination.serviceID == service.id)
        #expect(destination.mode == .edit)
        model.beginCreatingService()
        #expect(model.formDestination == destination)
    }
}

enum ServiceListTerminal { case empty, finished, failed, cancelled }

private actor ServiceListStreamStub: ServiceRepository {
    private let first: AsyncThrowingStream<[Service], any Error>
    private let started: AsyncStream<Void>.Continuation
    private let current: [Service]
    private var count = 0

    init(
        first: AsyncThrowingStream<[Service], any Error>,
        started: AsyncStream<Void>.Continuation,
        current: [Service]
    ) {
        self.first = first
        self.started = started
        self.current = current
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        count += 1
        if count == 1 {
            started.yield(())
            return first
        }
        return AsyncThrowingStream {
            $0.yield(current)
            $0.finish()
        }
    }
    func service(id: ServiceID) async throws -> Service? { nil }
    func saveService(_ service: Service) async throws {
        throw ServiceError.persistenceUnavailable
    }
    func createService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        throw ServiceError.persistenceUnavailable
    }
    func updateService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        throw ServiceError.persistenceUnavailable
    }
    func deactivateService(_ id: ServiceID) async throws {
        throw ServiceError.persistenceUnavailable
    }
}
