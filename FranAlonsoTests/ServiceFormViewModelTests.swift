import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service form coordination", .timeLimit(.minutes(1)))
@MainActor
struct ServiceFormViewModelTests {
    @Test
    func `invalid input does not write and retry preserves identity and the complete draft`() async throws {
        let fixture = try ServiceFormFixture(mode: .create)
        fixture.model.draft = serviceEditingDraft()
        fixture.model.draft.priceText = "19,95garbage"
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .invalidPriceInput))
        #expect(fixture.writes.profiles.isEmpty)
        fixture.model.draft.priceText = "19,95"
        #expect(fixture.model.state == .editing)
        fixture.writes.failure = ServiceError.conflict
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .service(.conflict)))
        #expect(fixture.model.draft == serviceEditingDraft())
        fixture.model.draft.name = "Retry"
        #expect(fixture.model.state == .failed(.save, .service(.conflict)))
        fixture.writes.failure = nil
        await fixture.model.save(in: fixture.context)
        let expected = try serviceFormExpected(id: fixture.id, name: "Retry")
        #expect(fixture.model.state == .saved(expected))
        #expect(fixture.model.loadedService == expected)
        #expect(fixture.writes.ids == [fixture.id, fixture.id])
        #expect(fixture.writes.profiles.map(\.name) == ["Offering", "Retry"])
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.ids.count == 2)
    }

    @Test
    func `missing and failed reads cannot write and retry does not overwrite an editable draft`() async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .service(.notFound)))
        fixture.model.draft = serviceEditingDraft()
        await fixture.model.save(in: fixture.context)
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.writes.ids.isEmpty)
        #expect(fixture.writes.deactivated.isEmpty)
        await fixture.reads.setFailure(ServiceFormTestFailure.expected)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .service(.persistenceUnavailable)))
        await fixture.reads.setFailure(nil)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Loaded", status: .inactive))
        await fixture.model.load()
        #expect(fixture.model.state == .editing)
        #expect(fixture.model.draft.name == "Loaded")
        #expect(!fixture.model.canDeactivate)
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.draft.discountText = "invalid"
        #expect(fixture.model.hasUnsavedChanges)
        await fixture.model.load()
        #expect(fixture.model.draft.discountText == "invalid")
    }

    @Test
    func `dirty tracking includes every commercial field and can return to its baseline`() async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Loaded"))
        await fixture.model.load()
        let baseline = fixture.model.draft
        let edits: [(inout ServiceFormDraft) -> Void] = [
            {
                $0.name = "Changed"
            },
            {
                $0.type = .product
            },
            {
                $0.linkedProductID = ProductID(rawValue: UUID())
            },
            {
                $0.priceText = "wrong"
            },
            {
                $0.currency = .usd
            },
            {
                $0.taxText = "4"
            },
            {
                $0.discountText = ""
            }
        ]
        for edit in edits {
            edit(&fixture.model.draft)
            #expect(fixture.model.hasUnsavedChanges)
            fixture.model.draft = baseline
            #expect(!fixture.model.hasUnsavedChanges)
        }
    }

    @Test
    func `a suspended save captures all fields and excludes overlapping writes`() async throws {
        let fixture = try ServiceFormFixture(mode: .create)
        fixture.model.draft = serviceEditingDraft()
        let gate = ServiceFormTestGate()
        fixture.writes.gate = gate
        let saving = Task {
            defer {
                gate.finishRequest()
            }
            await fixture.model.save(in: fixture.context)
        }
        let entered = await gate.waitForEntry()
        #expect(fixture.model.state == .saving)
        fixture.model.draft = ServiceFormDraft()
        await fixture.model.save(in: fixture.context)
        await fixture.model.deactivate(in: fixture.context)
        gate.release()
        await saving.value
        #expect(entered)
        #expect(fixture.writes.profiles.count == 1)
        #expect(fixture.writes.deactivated.isEmpty)
        #expect(fixture.model.state == .saved(try serviceFormExpected(id: fixture.id, name: "Offering")))
    }

    @Test
    func `deactivation ignores an invalid unsaved draft and preserves retry capability`() async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Persisted"))
        await fixture.model.load()
        fixture.model.draft = ServiceFormDraft()
        #expect(fixture.model.canDeactivate)
        fixture.writes.failure = ServiceError.conflict
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.model.state == .failed(.deactivate, .service(.conflict)))
        fixture.writes.failure = nil
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.model.state == .deactivated)
        await fixture.model.deactivate(in: fixture.context)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.deactivated == [fixture.id, fixture.id])
        #expect(fixture.writes.profiles.isEmpty)
    }

    @Test
    func `unknown write failures are neutral while an unavailable product keeps its meaning`() async throws {
        let fixture = try ServiceFormFixture(mode: .create)
        fixture.model.draft = serviceEditingDraft()
        fixture.writes.failure = ServiceFormTestFailure.expected
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .service(.persistenceUnavailable)))
        fixture.writes.failure = ServiceError.linkedProductUnavailable
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductUnavailable)))
        fixture.model.draft.name = "Changed"
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductUnavailable)))
        #expect(fixture.model.canEdit)
    }

    @Test
    func `pre cancelled mutations do not invoke their capabilities`() async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Stored"))
        await fixture.model.load()
        let task = Task {
            await fixture.model.save(in: fixture.context)
            await fixture.model.deactivate(in: fixture.context)
        }
        task.cancel()
        await task.value
        #expect(fixture.writes.ids.isEmpty)
        #expect(fixture.writes.deactivated.isEmpty)
        #expect(fixture.model.state == .editing)
    }

    @Test(arguments: [ServiceFormInterruption.cancelled, .cooperative, .closed], [false, true])
    func `write completion distinguishes local success cancellation and a closed session`(
        interruption: ServiceFormInterruption,
        deactivation: Bool
    ) async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Stored"))
        await fixture.model.load()
        fixture.model.draft = serviceEditingDraft()
        let gate = ServiceFormTestGate()
        fixture.writes.gate = gate
        let task = Task {
            defer {
                gate.finishRequest()
            }
            if deactivation {
                await fixture.model.deactivate(in: fixture.context)
            } else {
                await fixture.model.save(in: fixture.context)
            }
        }
        let entered = await gate.waitForEntry()
        switch interruption {
        case .cancelled: task.cancel()
        case .cooperative: fixture.writes.failure = CancellationError()
        case .closed: fixture.model.close()
        }
        gate.release()
        await task.value
        #expect(entered)
        switch interruption {
        case .cancelled:
            let expected: ServiceFormViewModel.State = deactivation
                ? .deactivated : .saved(try serviceFormExpected(id: fixture.id, name: "Offering"))
            #expect(fixture.model.state == expected)
        case .cooperative:
            #expect(fixture.model.state == .editing)
            #expect(fixture.model.draft == serviceEditingDraft())
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.draft == ServiceFormDraft())
            #expect(fixture.model.loadedService == nil)
        }
    }

    @Test(arguments: [ServiceFormReadInterruption.replaced, .cancelled, .closed])
    func `late reads cannot overwrite a replaced cancelled or closed session`(
        _ interruption: ServiceFormReadInterruption
    ) async throws {
        let fixture = try ServiceFormFixture(mode: .edit)
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Old"))
        let current = try serviceFormExpected(id: fixture.id, name: "Current")
        let gate = ServiceFormTestGate()
        await fixture.reads.hold(gate)
        let task = Task {
            defer {
                gate.finishRequest()
            }
            await fixture.model.load()
        }
        let entered = await gate.waitForEntry()
        switch interruption {
        case .replaced:
            await fixture.reads.set(current)
            await fixture.model.load()
        case .cancelled:
            task.cancel()
        case .closed:
            fixture.model.close()
        }
        gate.release()
        await task.value
        #expect(entered)
        switch interruption {
        case .replaced:
            #expect(fixture.model.state == .editing)
            #expect(fixture.model.draft.name == "Current")
        case .cancelled:
            #expect(fixture.model.state == .idle)
            #expect(fixture.model.loadedService == nil)
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.draft == ServiceFormDraft())
        }
    }
}

enum ServiceFormInterruption { case cancelled, cooperative, closed }
enum ServiceFormReadInterruption { case replaced, cancelled, closed }
enum ServiceFormTestFailure: Error { case expected }

@MainActor
struct ServiceFormFixture {
    let container: ModelContainer
    let reads: ServiceFormReadStub
    let writes: ServiceFormWriteStub
    let model: ServiceFormViewModel
    var context: ModelContext { container.mainContext }
    var id: ServiceID { model.destination.serviceID }
}

extension ServiceFormFixture {
    init(
        mode: ServiceFormDestination.Mode,
        products: any ProductRepository = InMemoryProductRepository(),
        assistant: (any ServiceDraftInterpreter)? = nil
    ) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let reads = ServiceFormReadStub()
        let writes = ServiceFormWriteStub()
        self.init(
            container: container,
            reads: reads,
            writes: writes,
            model: ServiceFormViewModel(
                destination: ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: mode),
                getService: GetServiceUseCase(repository: reads),
                observeLinkableProducts: ObserveLinkableProductsUseCase(repository: products),
                create: { id, profile, _ in
                    try await writes.save(id, profile)
                },
                update: { id, profile, _ in
                    try await writes.save(id, profile)
                },
                deactivate: { id, _ in
                    try await writes.deactivate(id)
                },
                locale: Locale(identifier: "es_ES"),
                assistant: assistant
            )
        )
    }
}

@MainActor
final class ServiceFormWriteStub {
    var failure: (any Error)?
    var gate: ServiceFormTestGate?
    var ids: [ServiceID] = []
    var profiles: [ServiceProfile] = []
    var deactivated: [ServiceID] = []

    func save(_ id: ServiceID, _ profile: ServiceProfile) async throws -> Service {
        ids.append(id)
        profiles.append(profile)
        await gate?.block()
        if let failure {
            throw failure
        }
        return try Service(
            id: id,
            name: profile.name,
            type: profile.type,
            linkedProductID: profile.linkedProductID,
            price: profile.price,
            taxRate: profile.taxRate,
            discount: profile.discount,
            status: .active
        )
    }

    func deactivate(_ id: ServiceID) async throws {
        deactivated.append(id)
        await gate?.block()
        if let failure {
            throw failure
        }
    }
}

actor ServiceFormReadStub: ServiceRepository {
    private var stored: Service?
    private var failure: (any Error)?
    private var gate: ServiceFormTestGate?
    func set(_ service: Service) {
        stored = service
    }
    func setFailure(_ failure: (any Error)?) {
        self.failure = failure
    }
    func hold(_ gate: ServiceFormTestGate) {
        self.gate = gate
    }

    func service(id: ServiceID) async throws -> Service? {
        let snapshot = stored
        let heldGate = gate
        gate = nil
        await heldGate?.block()
        if let failure {
            throw failure
        }
        return snapshot
    }
    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        AsyncThrowingStream {
            $0.finish()
        }
    }
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

@MainActor
final class ServiceFormTestGate {
    private let entered = AsyncStream<Void>.makeStream()
    private let released = AsyncStream<Void>.makeStream()
    private var didBlock = false

    func block() async {
        guard !didBlock else { return }
        didBlock = true
        entered.continuation.yield(())
        var iterator = released.stream.makeAsyncIterator()
        _ = await iterator.next()
    }
    func waitForEntry() async -> Bool {
        var iterator = entered.stream.makeAsyncIterator()
        return await iterator.next() != nil
    }
    func finishRequest() {
        entered.continuation.finish()
    }
    func release() {
        released.continuation.finish()
    }
}

func serviceEditingDraft() -> ServiceFormDraft {
    ServiceFormDraft(
        name: "  Offering  ",
        type: .professional,
        linkedProductID: nil,
        priceText: "19,95",
        currency: .eur,
        taxText: "21,125",
        discountText: "2,375"
    )
}

func serviceFormExpected(id: ServiceID, name: String, status: ServiceStatus = .active) throws -> Service {
    try Service(
        id: id,
        name: name,
        type: .professional,
        price: Money(amount: Decimal(string: "19.95")!, currency: .eur),
        taxRate: TaxRate(percentage: Decimal(string: "21.125")!),
        discount: Discount(percentage: Decimal(string: "2.375")!),
        status: status
    )
}
