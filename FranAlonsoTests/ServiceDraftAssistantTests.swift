import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service draft assistant coordination", .timeLimit(.minutes(1)))
@MainActor
struct ServiceDraftAssistantTests {
    @Test
    func `proposal applies only present fields and never writes before manual save`() async throws {
        let proposal = try ServiceDraftProposal(name: "Corte y peinado", price: Money(amount: 35, currency: .eur))
        let fixture = try ServiceFormFixture(mode: .create, assistant: DraftAssistantStub(proposal: proposal))
        fixture.model.draft = ServiceFormDraft(name: "Manual", taxText: "21", discountText: "5")
        let manual = fixture.model.draft
        fixture.model.assistantInput = "Corte y peinado, precio 35 euros"
        fixture.model.requestAssistantProposal()
        let request = try #require(fixture.model.assistantRequestID)
        await fixture.model.generateAssistantProposal(for: request)
        #expect(fixture.model.assistantState == .proposed(proposal))
        #expect(fixture.model.draft == manual)
        #expect(fixture.writes.ids.isEmpty)

        fixture.model.applyAssistantProposal()

        #expect(fixture.model.draft.name == "Corte y peinado")
        #expect(fixture.model.draft.priceText == "35")
        #expect(fixture.model.draft.taxText == "21")
        #expect(fixture.model.draft.discountText == "5")
        #expect(fixture.model.assistantInput.isEmpty)
        #expect(fixture.writes.ids.isEmpty)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.ids == [fixture.id])
        #expect(fixture.writes.profiles.first?.price.amount == 35)
    }

    @Test
    func `reject and undo preserve the manual draft without persistence`() async throws {
        let proposal = try ServiceDraftProposal(name: "Corte", taxRate: TaxRate(percentage: 0))
        let fixture = try ServiceFormFixture(mode: .create, assistant: DraftAssistantStub(proposal: proposal))
        fixture.model.draft = serviceEditingDraft()
        let manual = fixture.model.draft
        try await generate(fixture.model)
        fixture.model.rejectAssistantProposal()
        #expect(fixture.model.draft == manual)
        #expect(fixture.model.assistantInput.isEmpty)
        #expect(fixture.model.assistantState == .idle)
        try await generate(fixture.model)
        fixture.model.applyAssistantProposal()
        #expect(fixture.model.draft.taxText == "0")
        fixture.model.undoAssistantApplication()
        #expect(fixture.model.draft == manual)
        #expect(fixture.writes.ids.isEmpty)
    }

    @Test
    func `edits invalidate a pending proposal even when the draft returns to its former value`() async throws {
        let fixture = try ServiceFormFixture(
            mode: .create,
            assistant: DraftAssistantStub(proposal: ServiceDraftProposal(name: "Corte"))
        )
        let manual = fixture.model.draft
        try await generate(fixture.model)
        fixture.model.draft.name = "Changed"
        fixture.model.draft = manual
        fixture.model.applyAssistantProposal()
        #expect(fixture.model.draft == manual)
        #expect(fixture.model.assistantState == .idle)
        #expect(fixture.writes.ids.isEmpty)
    }

    @Test
    func `background clears interpretation while leaving manual input editable`() async throws {
        let fixture = try ServiceFormFixture(
            mode: .create,
            assistant: DraftAssistantStub(proposal: ServiceDraftProposal(name: "Corte"))
        )
        fixture.model.draft = serviceEditingDraft()
        let manual = fixture.model.draft
        try await generate(fixture.model)
        fixture.model.interruptAssistant()
        #expect(fixture.model.assistantInput.isEmpty)
        #expect(fixture.model.assistantState == .idle)
        #expect(fixture.model.assistantRequestID == nil)
        #expect(fixture.model.draft == manual)
        #expect(fixture.model.canEdit)
    }

    @Test(arguments: DraftAssistantInterruption.allCases)
    func `late responses cannot survive editing cancellation replacement or lifecycle changes`(
        _ interruption: DraftAssistantInterruption
    ) async throws {
        let late = try ServiceDraftProposal(name: "Late")
        let current = try ServiceDraftProposal(name: "Current")
        let interpreter = ControlledDraftAssistant(late: late, current: current)
        let fixture = try ServiceFormFixture(mode: .create, assistant: interpreter)
        fixture.model.draft = serviceEditingDraft()
        let manual = fixture.model.draft
        fixture.model.assistantInput = "Late"
        fixture.model.requestAssistantProposal()
        let request = try #require(fixture.model.assistantRequestID)
        let pending = Task { await fixture.model.generateAssistantProposal(for: request) }
        await interpreter.waitForEntry()
        switch interruption {
        case .edit:
            fixture.model.draft.name = "New manual name"
        case .editAndReturn:
            fixture.model.draft.name = "Temporary"
            fixture.model.draft = manual
        case .input:
            fixture.model.assistantInput = "New description"
        case .type:
            fixture.model.changeType(.product)
        case .cancel:
            fixture.model.cancelAssistant()
        case .taskCancellation:
            pending.cancel()
        case .background:
            fixture.model.interruptAssistant()
        case .close:
            fixture.model.close()
        case .replace:
            fixture.model.assistantInput = "Current"
            fixture.model.requestAssistantProposal()
            let replacement = try #require(fixture.model.assistantRequestID)
            await fixture.model.generateAssistantProposal(for: replacement)
        case .save:
            await fixture.model.save(in: fixture.context)
        }
        let expectedDraft = fixture.model.draft
        await interpreter.release()
        await pending.value
        #expect(fixture.model.draft == expectedDraft)
        #expect(fixture.model.assistantState == (interruption == .replace ? .proposed(current) : .idle))
        #expect(fixture.writes.ids.count == (interruption == .save ? 1 : 0))
        if interruption == .close {
            #expect(fixture.model.state == .closed)
        }
    }

    @Test(arguments: [
        ServiceDraftAvailability.deviceNotEligible, .intelligenceDisabled, .modelNotReady,
        .unsupportedLanguage, .unavailable
    ])
    func `unavailability never calls inference and preserves the manual form`(
        _ availability: ServiceDraftAvailability
    ) async throws {
        let interpreter = UnavailableDraftAssistant(result: availability)
        let fixture = try ServiceFormFixture(mode: .create, assistant: interpreter)
        fixture.model.draft = serviceEditingDraft()
        let manual = fixture.model.draft
        try await generate(fixture.model)
        #expect(fixture.model.assistantState == .unavailable(availability))
        #expect(fixture.model.draft == manual)
        #expect(await interpreter.requests == 0)
        #expect(fixture.writes.ids.isEmpty)
        #expect(fixture.model.canEdit)
    }

    @Test(arguments: [ServiceDraftAssistantError.clarification, .generationFailed])
    func `provider errors preserve the draft and explicit retry can recover`(
        _ error: ServiceDraftAssistantError
    ) async throws {
        let proposal = try ServiceDraftProposal(name: "Recovered")
        let interpreter = RecoveringDraftAssistant(error: error, proposal: proposal)
        let fixture = try ServiceFormFixture(mode: .create, assistant: interpreter)
        fixture.model.draft = serviceEditingDraft()
        let manual = fixture.model.draft
        try await generate(fixture.model)
        #expect(fixture.model.assistantState == .failed(error))
        #expect(fixture.model.draft == manual)
        try await generate(fixture.model)
        #expect(fixture.model.assistantState == .proposed(proposal))
        #expect(fixture.writes.ids.isEmpty)
    }

    @Test
    func `manual edits after application prevent undo from overwriting later work`() async throws {
        let fixture = try ServiceFormFixture(
            mode: .create,
            assistant: DraftAssistantStub(proposal: ServiceDraftProposal(name: "Corte"))
        )
        try await generate(fixture.model)
        fixture.model.applyAssistantProposal()
        fixture.model.draft.name = "Reviewed manually"
        let reviewed = fixture.model.draft
        fixture.model.undoAssistantApplication()
        #expect(fixture.model.draft == reviewed)
        #expect(fixture.model.assistantState == .idle)
    }

    @Test
    func `incomplete and oversized input cannot bypass manual validation`() async throws {
        let fixture = try ServiceFormFixture(
            mode: .create,
            assistant: DraftAssistantStub(proposal: ServiceDraftProposal(name: "Corte"))
        )
        fixture.model.assistantInput = String(repeating: "a", count: 1_001)
        fixture.model.requestAssistantProposal()
        #expect(fixture.model.assistantRequestID == nil)
        #expect(fixture.model.assistantState == .failed(.inputTooLong))
        try await generate(fixture.model)
        fixture.model.applyAssistantProposal()
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .invalidPriceInput))
        #expect(fixture.writes.ids.isEmpty)
    }

    @Test
    func `actual contextual persistence occurs only after review and normal save`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let services = ServicePersistenceActor(modelContainer: container)
        let proposal = try ServiceDraftProposal(
            name: "Corte",
            price: Money(amount: 35, currency: .eur),
            taxRate: TaxRate(percentage: 21)
        )
        let factory = AppDependencies.serviceFormFactory(
            persistenceActor: services,
            observationSignal: ServiceObservationSignal(),
            productRepository: InMemoryProductRepository(),
            assistant: DraftAssistantStub(proposal: proposal)
        )
        let model = factory(
            ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: .create),
            Locale(identifier: "es_ES")
        )
        try await generate(model)
        model.applyAssistantProposal()
        #expect(try await services.pendingOperations().isEmpty)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        model.draft.name = "Corte revisado"
        await model.save(in: container.mainContext)
        let saved = try #require(try ModelContext(container).fetch(FetchDescriptor<ServiceModel>()).first)
        let service = try saved.toDomain()
        #expect(service.name == "Corte revisado")
        #expect(service.price.amount == 35)
        #expect(service.taxRate.percentage == 21)
        #expect(try await services.pendingOperations().count == 1)
    }

    @Test
    func `preview and plain form factories cannot start real inference`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        let model = dependencies.makeServiceForm(
            ServiceFormDestination(id: UUID(), serviceID: ServiceID(rawValue: UUID()), mode: .create),
            .current
        )
        model.assistantInput = "Corte, precio 35 euros"
        model.requestAssistantProposal()
        #expect(!model.canUseAssistant)
        #expect(model.assistantRequestID == nil)
    }

    private func generate(_ model: ServiceFormViewModel) async throws {
        model.assistantInput = "Corte, IVA 0%"
        model.requestAssistantProposal()
        let request = try #require(model.assistantRequestID)
        await model.generateAssistantProposal(for: request)
    }
}

private struct DraftAssistantStub: ServiceDraftInterpreter {
    let proposal: ServiceDraftProposal

    func availability(locale: Locale) async -> ServiceDraftAvailability { .available }

    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal { proposal }
}

enum DraftAssistantInterruption: CaseIterable {
    case edit, editAndReturn, input, type, cancel, taskCancellation, background, close, replace, save
}

private actor ControlledDraftAssistant: ServiceDraftInterpreter {
    let late: ServiceDraftProposal
    let current: ServiceDraftProposal
    private let entry = AsyncStream<Void>.makeStream()
    private var continuation: CheckedContinuation<ServiceDraftProposal, Never>?
    private var requestCount = 0

    init(late: ServiceDraftProposal, current: ServiceDraftProposal) {
        self.late = late
        self.current = current
    }

    func availability(locale: Locale) async -> ServiceDraftAvailability { .available }

    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal {
        requestCount += 1
        guard requestCount == 1 else { return current }
        return await withCheckedContinuation {
            continuation = $0
            entry.continuation.yield(())
        }
    }

    func waitForEntry() async {
        var iterator = entry.stream.makeAsyncIterator()
        _ = await iterator.next()
    }

    func release() {
        continuation?.resume(returning: late)
        continuation = nil
        entry.continuation.finish()
    }
}

private actor UnavailableDraftAssistant: ServiceDraftInterpreter {
    let result: ServiceDraftAvailability
    private(set) var requests = 0

    init(result: ServiceDraftAvailability) { self.result = result }

    func availability(locale: Locale) async -> ServiceDraftAvailability { result }

    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal {
        requests += 1
        throw ServiceDraftAssistantError.generationFailed
    }
}

private actor RecoveringDraftAssistant: ServiceDraftInterpreter {
    let error: ServiceDraftAssistantError
    let proposal: ServiceDraftProposal
    private var attempts = 0

    init(error: ServiceDraftAssistantError, proposal: ServiceDraftProposal) {
        self.error = error
        self.proposal = proposal
    }

    func availability(locale: Locale) async -> ServiceDraftAvailability { .available }

    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal {
        attempts += 1
        if attempts == 1 {
            throw error
        }
        return proposal
    }
}
