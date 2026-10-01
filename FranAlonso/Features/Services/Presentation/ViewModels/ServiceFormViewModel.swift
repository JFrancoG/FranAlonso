import Foundation
import Observation
import SwiftData

/// Coordinates one commercial service draft through caller-context local mutation capabilities.
@Observable
@MainActor
final class ServiceFormViewModel {
    typealias SaveOperation = @MainActor (ServiceID, ServiceProfile, ModelContext) async throws -> Service
    typealias DeactivateOperation = @MainActor (ServiceID, ModelContext) async throws -> Void

    enum Operation: Equatable {
        case load
        case save
        case deactivate
    }

    /// Failed reads stay noneditable; failed mutations retain the draft for retry.
    enum State: Equatable {
        case idle
        case loading
        case editing
        case saving
        case deactivating
        case saved(Service)
        case deactivated
        case failed(Operation, ServiceFormError)
        case closed
    }

    /// Availability is independent of the editable draft and mutation feedback.
    enum LinkableProductsState: Equatable {
        case idle
        case loading
        case loaded([Product])
        case failed
    }

    let destination: ServiceFormDestination
    /// Correction clears local validation feedback only; persistence errors remain until retry.
    var draft = ServiceFormDraft() {
        didSet {
            if draft != oldValue {
                clearAssistant(clearInput: true)
            }
            guard draft != oldValue, case .failed(.save, let error) = state,
                  error.isLocalValidation, (try? draft.prepareProfile(locale: locale)) != nil else { return }
            state = .editing
        }
    }
    private(set) var linkableProductsState: LinkableProductsState = .idle
    private let observeLinkableProducts: ObserveLinkableProductsUseCase
    private(set) var loadedService: Service?
    private(set) var state: State
    private let getService: GetServiceUseCase
    private let create: SaveOperation
    private let update: SaveOperation
    private let deactivateService: DeactivateOperation
    private let locale: Locale
    @ObservationIgnored private var operationGeneration = UUID()
    @ObservationIgnored private var productObservationGeneration = UUID()
    private var baseline = ServiceFormDraft()
    var assistantInput = "" {
        didSet {
            guard assistantInput != oldValue else { return }
            clearAssistant(clearInput: false)
        }
    }
    private(set) var assistantState: ServiceDraftAssistantState = .idle
    private(set) var assistantRequestID: UUID?
    private let assistant: (any ServiceDraftInterpreter)?
    @ObservationIgnored private var assistantUndoDraft: ServiceFormDraft?

    /// Captures the numeric locale for the session without retaining a persistent context.
    init(
        destination: ServiceFormDestination,
        getService: GetServiceUseCase,
        observeLinkableProducts: ObserveLinkableProductsUseCase,
        create: @escaping SaveOperation,
        update: @escaping SaveOperation,
        deactivate: @escaping DeactivateOperation,
        locale: Locale = .current,
        assistant: (any ServiceDraftInterpreter)? = nil
    ) {
        self.destination = destination
        self.getService = getService
        self.observeLinkableProducts = observeLinkableProducts
        self.create = create
        self.update = update
        deactivateService = deactivate
        self.locale = locale
        self.assistant = assistant
        state = destination.mode == .create ? .editing : .idle
    }

    /// Failed mutations permit retry; unread services and terminal sessions never permit writes.
    var canEdit: Bool {
        switch state {
        case .editing, .failed(.save, _), .failed(.deactivate, _): true
        default: false
        }
    }

    var canDeactivate: Bool { destination.mode == .edit && loadedService?.status == .active && canEdit }

    /// Raw input participates in dirty tracking, including currently invalid numeric text.
    var hasUnsavedChanges: Bool { canEdit && draft != baseline }

    var canUseAssistant: Bool { assistant != nil && destination.mode == .create && draft.type == .professional }

    var canRequestAssistant: Bool {
        canUseAssistant && canEdit && assistantState != .generating
            && !assistantInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var assistantProposalName: String? { assistantProposal?.name }

    var assistantProposalPrice: String? {
        guard let price = assistantProposal?.price else { return nil }
        return ServiceDecimalInput(locale: locale).format(price.amount) + " " + price.currency.rawValue
    }

    var assistantProposalTax: String? {
        assistantProposal?.taxRate.map { ServiceDecimalInput(locale: locale).format($0.percentage) + "%" }
    }

    var assistantProposalDiscount: String? {
        assistantProposal?.discount.map { ServiceDecimalInput(locale: locale).format($0.percentage) + "%" }
    }

    private var assistantProposal: ServiceDraftProposal? {
        guard case .proposed(let proposal) = assistantState else { return nil }
        return proposal
    }

    /// Starts an explicit interpretation owned by the caller's structured task.
    /// Replacing an identity invalidates earlier work, even when input later returns to its original value.
    func requestAssistantProposal() {
        guard canUseAssistant, canEdit else { return }
        clearAssistant(clearInput: false)
        let input = assistantInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            assistantState = .failed(.clarification)
            return
        }
        guard input.count <= 1_000 else {
            assistantState = .failed(.inputTooLong)
            return
        }
        assistantRequestID = UUID()
        assistantState = .generating
    }

    /// Availability and responses never change the editable draft or invoke a persistence capability.
    /// Cancellation or invalidation discards late responses without claiming to stop the model's physical work.
    func generateAssistantProposal(for requestID: UUID) async {
        guard assistantRequestID == requestID, let assistant, canUseAssistant, canEdit else { return }
        let input = assistantInput
        do {
            try Task.checkCancellation()
            let availability = await assistant.availability(locale: locale)
            try Task.checkCancellation()
            guard assistantRequestID == requestID else { return }
            guard availability == .available else {
                assistantState = .unavailable(availability)
                assistantRequestID = nil
                return
            }
            let proposal = try await assistant.interpret(input, locale: locale)
            try Task.checkCancellation()
            guard assistantRequestID == requestID, canUseAssistant, canEdit else { return }
            assistantState = .proposed(proposal)
            assistantRequestID = nil
        } catch {
            guard assistantRequestID == requestID else { return }
            if error is CancellationError || Task.isCancelled {
                clearAssistant(clearInput: true)
            } else {
                assistantState = .failed((error as? ServiceDraftAssistantError) ?? .generationFailed)
                assistantRequestID = nil
            }
        }
    }

    /// Copies only reviewed, present fields. The existing Save action remains the sole persistence entry point.
    func applyAssistantProposal() {
        guard canUseAssistant, canEdit, let proposal = assistantProposal else { return }
        let previousDraft = draft
        var edited = draft
        let numbers = ServiceDecimalInput(locale: locale)
        if let name = proposal.name {
            edited.name = name
        }
        if let price = proposal.price {
            edited.priceText = numbers.format(price.amount)
            edited.currency = price.currency
        }
        if let tax = proposal.taxRate {
            edited.taxText = numbers.format(tax.percentage)
        }
        if let discount = proposal.discount {
            edited.discountText = numbers.format(discount.percentage)
        }
        clearAssistant(clearInput: true)
        draft = edited
        assistantUndoDraft = previousDraft
        assistantState = .applied
    }

    func rejectAssistantProposal() {
        clearAssistant(clearInput: true)
    }

    func cancelAssistant() {
        clearAssistant(clearInput: true)
    }

    /// Drops inference state on background or loss of the active scene, preserving manual edits.
    func interruptAssistant() {
        clearAssistant(clearInput: true)
    }

    /// Undo is available only until the next manual edit, interpretation or lifecycle interruption.
    func undoAssistantApplication() {
        guard canUseAssistant, canEdit, let previous = assistantUndoDraft else { return }
        clearAssistant(clearInput: true)
        draft = previous
    }

    private func clearAssistant(clearInput: Bool) {
        assistantRequestID = nil
        assistantState = .idle
        assistantUndoDraft = nil
        if clearInput, !assistantInput.isEmpty {
            assistantInput = ""
        }
    }

    /// Observes active choices for the caller task without changing the draft or write feedback.
    /// A finite snapshot remains usable; completion without a snapshot requires an explicit retry.
    /// Replaced, cancelled and closed observations cannot publish into the current catalogue.
    func observeProducts() async {
        guard state != .closed else { return }
        let generation = UUID()
        productObservationGeneration = generation
        linkableProductsState = .loading
        var receivedSnapshot = false
        do {
            try Task.checkCancellation()
            let products = await observeLinkableProducts()
            try Task.checkCancellation()
            guard productObservationGeneration == generation else { return }
            for try await snapshot in products {
                try Task.checkCancellation()
                guard productObservationGeneration == generation else { return }
                receivedSnapshot = true
                linkableProductsState = .loaded(snapshot)
            }
            try Task.checkCancellation()
            guard productObservationGeneration == generation else { return }
            if !receivedSnapshot {
                linkableProductsState = .failed
            }
        } catch {
            guard productObservationGeneration == generation else { return }
            linkableProductsState = error is CancellationError || Task.isCancelled ? .idle : .failed
        }
    }

    /// Converting to professional deliberately clears the link; converting back never chooses a product.
    func changeType(_ type: ServiceType) {
        guard canEdit else { return }
        var changed = draft
        changed.type = type
        if type == .professional {
            changed.linkedProductID = nil
        }
        draft = changed
    }

    /// Accepts only currently observed choices; an explicit nil clears the draft even when availability is unknown.
    /// Selection does not reserve a product: local save acceptance revalidates its current availability.
    func selectLinkedProduct(_ id: ProductID?) {
        guard canEdit, draft.type == .product else { return }
        if let id {
            guard case .loaded(let products) = linkableProductsState,
                  products.contains(where: { $0.id == id }) else { return }
        }
        draft.linkedProductID = id
    }

    /// Retries reads without replacing an editable draft or consulting current product availability.
    /// Cancelled, replaced and closed loads cannot publish late results into this session.
    func load() async {
        guard destination.mode == .edit else { return }
        switch state {
        case .idle, .loading, .failed(.load, _): break
        default: return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .loading
        do {
            try Task.checkCancellation()
            let service = try await getService(destination.serviceID)
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            guard let service else {
                state = .failed(.load, .service(.notFound))
                return
            }
            loadedService = service
            baseline = ServiceFormDraft(service: service, locale: locale)
            draft = baseline
            state = .editing
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError || Task.isCancelled ? .idle : .failed(.load, formError(error))
        }
    }

    /// Captures and validates every field before submitting one caller-context mutation.
    /// An accepted write remains successful when cancellation arrives during persistence.
    func save(in context: ModelContext) async {
        guard canEdit, !Task.isCancelled else { return }
        clearAssistant(clearInput: true)
        let profile: ServiceProfile
        do {
            profile = try draft.prepareProfile(locale: locale)
        } catch {
            state = .failed(.save, formError(error))
            return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .saving
        do {
            let service: Service
            switch destination.mode {
            case .create:
                service = try await create(destination.serviceID, profile, context)
            case .edit:
                service = try await update(destination.serviceID, profile, context)
            }
            guard operationGeneration == generation else { return }
            loadedService = service
            state = .saved(service)
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.save, formError(error))
        }
    }

    /// Deactivates the loaded identity without saving or validating unsaved commercial fields.
    /// Completion means local acceptance, not remote convergence.
    func deactivate(in context: ModelContext) async {
        guard canDeactivate, !Task.isCancelled else { return }
        let generation = UUID()
        operationGeneration = generation
        state = .deactivating
        do {
            try await deactivateService(destination.serviceID, context)
            guard operationGeneration == generation else { return }
            state = .deactivated
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.deactivate, formError(error))
        }
    }

    /// Clears presentation and fences responses without claiming to undo an accepted write.
    func close() {
        clearAssistant(clearInput: true)
        operationGeneration = UUID()
        productObservationGeneration = UUID()
        linkableProductsState = .idle
        draft = ServiceFormDraft()
        baseline = ServiceFormDraft()
        loadedService = nil
        state = .closed
    }

    private func formError(_ error: any Error) -> ServiceFormError {
        if let error = error as? ServiceFormError {
            return error
        }
        return .service((error as? ServiceError) ?? .persistenceUnavailable)
    }
}
