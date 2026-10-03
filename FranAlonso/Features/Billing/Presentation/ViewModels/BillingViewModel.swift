import Foundation
import Observation

/// The presentation facade reads its Store directly, including through Observation tracking.
@Observable @MainActor
final class BillingViewModel<Repository: BillingDocumentReservationRepository> {
    private let store: BillingDocumentStore<Repository>
    private let sale: Sale?
    private let prepareDocument: PrepareBillingDocumentRequestUseCase
    private let getClient: GetClientUseCase?
    private let preparationIsAvailable: @MainActor @Sendable () -> Bool
    private var fiscalInput = BillingFiscalRecipientInput()
    private var selection: BillingDocumentKind = .ticket
    @ObservationIgnored private var prefillGeneration: UUID?
    @ObservationIgnored private var hasAttemptedPrefill = false
    @ObservationIgnored private var hasEditedInput = false
    private(set) var formIssue: BillingFormIssue?
    private(set) var validationID: UUID?
    private(set) var isLoadingRecipient = false

    var selectedKind: BillingDocumentKind { request?.kind ?? selection }
    var isEditing: Bool {
        guard case .selection = state, preparationIsAvailable(),
              let sale, case .awaitingDocument = sale.status else { return false }
        return true
    }

    func fieldValue(_ field: BillingFiscalField) -> String {
        request?.fiscalRecipient?.input[field] ?? fiscalInput[field]
    }

    func selectKind(_ kind: BillingDocumentKind) {
        guard isEditing, kind != selection else { return }
        invalidatePrefill()
        selection = kind
        formIssue = nil
        validationID = nil
        if kind == .ticket {
            fiscalInput = BillingFiscalRecipientInput()
            hasEditedInput = false
            hasAttemptedPrefill = false
        }
    }

    func updateField(_ field: BillingFiscalField, value: String) {
        guard isEditing, selection == .invoice, fiscalInput[field] != value else { return }
        invalidatePrefill()
        hasEditedInput = true
        fiscalInput[field] = value
        formIssue = nil
        validationID = nil
    }

    /// Seals one paid snapshot locally; validation preserves editing and never contacts numbering.
    func prepareSelection() -> BillingDocumentRequest? {
        guard preparationIsAvailable(), let sale else { return reject(.unavailable) }
        if case .closed = state {
            return reject(.unavailable)
        }
        if let request {
            return request
        }
        do {
            let prepared = try prepareDocument(
                sale: sale,
                kind: selection,
                recipientInput: selection == .invoice ? fiscalInput : nil
            )
            try prepare(prepared)
            return prepared
        } catch let BillingFiscalRecipientError.required(field) {
            return reject(.required(field))
        } catch {
            return reject(.unavailable)
        }
    }

    /// Caller-owned local prefill cannot replace manual input or publish into a revoked parent session.
    func loadRecipient() async {
        guard isEditing, selection == .invoice, !hasEditedInput, !hasAttemptedPrefill,
              !Task.isCancelled, let id = sale?.clientID, let getClient else { return }
        hasAttemptedPrefill = true
        let generation = UUID()
        prefillGeneration = generation
        isLoadingRecipient = true
        defer {
            if prefillGeneration == generation {
                prefillGeneration = nil
                isLoadingRecipient = false
            }
        }
        do {
            let client = try await getClient(id)
            guard prefillGeneration == generation, !Task.isCancelled, isEditing,
                  selection == .invoice, !hasEditedInput, client.id == id else { return }
            let input = BillingFiscalRecipientInput(
                displayName: client.displayName,
                taxIdentifier: client.taxIdentifier ?? "",
                streetLine: client.billingAddress?.streetLine ?? "",
                postalCode: client.billingAddress?.postalCode ?? "",
                city: client.billingAddress?.city ?? "",
                province: client.billingAddress?.province ?? ""
            )
            if input != fiscalInput {
                fiscalInput = input
                formIssue = nil
                validationID = nil
            }
        } catch {
            // A missing, failed or cancelled optional prefill leaves manual entry available.
        }
    }

    private func reject(_ issue: BillingFormIssue) -> BillingDocumentRequest? {
        formIssue = issue
        validationID = UUID()
        return nil
    }

    private func invalidatePrefill() {
        prefillGeneration = nil
        isLoadingRecipient = false
    }

    var state: BillingDocumentStoreState { store.state }
    var localState: BillingDocumentLocalState? { store.localState }
    var request: BillingDocumentRequest? { store.request }
    var document: BillingDocument? { store.document }
    var isBusy: Bool { store.isBusy }
    var canReserve: Bool { store.canReserve }
    var failure: BillingDocumentFailure? { store.failure }

    func prepare(_ request: BillingDocumentRequest) throws {
        try store.prepare(request)
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
    }

    func reserve() async throws -> BillingDocument {
        try await store.reserve()
    }

    /// Explicitly retries the same sealed request; generates no new allocation identity.
    func retry() async throws -> BillingDocument {
        try await store.reserve()
    }

    func cancelReservation() {
        store.cancelReservation()
    }

    func close() {
        invalidatePrefill()
        fiscalInput = BillingFiscalRecipientInput()
        formIssue = nil
        validationID = nil
        store.close()
    }

    init(reserve: ReserveBillingDocumentUseCase<Repository>) {
        store = BillingDocumentStore(reserve: reserve)
        sale = nil
        prepareDocument = PrepareBillingDocumentRequestUseCase()
        getClient = nil
        preparationIsAvailable = { false }
    }

    init(
        sale: Sale?,
        reserve: ReserveBillingDocumentUseCase<Repository>,
        prepare: PrepareBillingDocumentRequestUseCase = .init(),
        getClient: GetClientUseCase? = nil,
        canPrepare: @escaping @MainActor @Sendable () -> Bool = { true }
    ) {
        store = BillingDocumentStore(reserve: reserve)
        self.sale = sale
        prepareDocument = prepare
        self.getClient = getClient
        preparationIsAvailable = canPrepare
    }
}
