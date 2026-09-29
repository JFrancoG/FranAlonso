import Foundation
import Observation
import SwiftData

/// Owns a single client form session and coordinates validated, caller-context local mutations.
@Observable
@MainActor
final class ClientFormViewModel {
    typealias SaveOperation = @MainActor (ClientID, ClientProfile, ModelContext) async throws -> Client
    typealias DeactivateOperation = @MainActor (ClientID, ModelContext) async throws -> Void

    enum Operation: Equatable {
        case load
        case save
        case deactivate
    }

    /// Failure retains the operation so a failed initial read cannot become a writable blank edit.
    enum State: Equatable {
        case idle
        case loading
        case editing
        case saving
        case deactivating
        case saved(Client)
        case deactivated
        case failed(Operation, ClientError)
        case closed
    }

    let destination: ClientFormDestination
    let consentStore: ClientConsentStore?
    let consentUnavailable: Bool
    private(set) var loadedClient: Client?
    private(set) var savedFields = ClientFormFields()

    /// Clears only a rejected name's validation error when editing makes that name valid, without saving.
    var fields = ClientFormFields() {
        didSet {
            if fields.displayName != oldValue.displayName {
                consentStore?.invalidatePresentation(clientName: fields.displayName)
            }
            guard fields.displayName != oldValue.displayName,
                  state == .failed(.save, .invalidDisplayName),
                  (try? ClientProfile(displayName: fields.displayName)) != nil else { return }
            state = .editing
        }
    }

    private(set) var state: State

    private let getClient: GetClientUseCase
    private let prepareProfile = PrepareClientProfileUseCase()
    private let create: SaveOperation
    private let update: SaveOperation
    private let deactivateClient: DeactivateOperation
    @ObservationIgnored private var operationGeneration = UUID()

    /// Receives contextual capabilities composed by App; no persistent context is retained.
    init(
        destination: ClientFormDestination,
        getClient: GetClientUseCase,
        create: @escaping SaveOperation,
        update: @escaping SaveOperation,
        deactivate: @escaping DeactivateOperation,
        consentServices: ClientConsentServices? = nil,
        consentUnavailable: Bool = false
    ) {
        self.destination = destination
        consentStore = consentServices.map { ClientConsentStore(clientID: destination.clientID, services: $0) }
        self.consentUnavailable = consentUnavailable
        self.getClient = getClient
        self.create = create
        self.update = update
        deactivateClient = deactivate
        state = destination.mode == .create ? .editing : .idle
    }

    /// Allows editing after a rejected mutation, but never before an existing profile has loaded.
    var canEdit: Bool {
        guard consentStore?.isBusy != true else { return false }
        return switch state {
        case .editing, .failed(.save, _), .failed(.deactivate, _): true
        default: false
        }
    }

    /// Loads an existing client or retries its failed read without overwriting an editable draft.
    /// The caller owns cancellation; a newer load or closing the session fences obsolete responses.
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
            let client = try await getClient(destination.clientID)
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            loadedClient = client
            fields = ClientFormFields(client)
            savedFields = fields
            if let consentStore {
                await consentStore.recover(profile: try normalizedProfile())
                guard operationGeneration == generation else { return }
                if consentStore.failure == .authorization {
                    close()
                    return
                }
                guard consentStore.failure == nil else {
                    state = .failed(.load, .persistenceUnavailable)
                    return
                }
            }
            state = .editing
        } catch {
            guard operationGeneration == generation else { return }
            if error is CancellationError || Task.isCancelled {
                state = .idle
            } else {
                state = .failed(.load, clientError(error))
            }
        }
    }

    /// Validates a captured draft and delegates exactly one local write using the ephemeral caller context.
    /// Concurrent submissions are ignored. A successful durable response remains success after cancellation.
    func save(in context: ModelContext) async {
        guard canEdit, !Task.isCancelled else { return }
        let profile: ClientProfile
        do {
            profile = try prepareProfile(
                displayName: fields.displayName,
                taxIdentifier: fields.taxIdentifier,
                streetLine: fields.streetLine,
                postalCode: fields.postalCode,
                city: fields.city,
                province: fields.province
            )
        } catch {
            state = .failed(.save, clientError(error))
            return
        }

        let generation = UUID()
        operationGeneration = generation
        state = .saving
        if let consentStore, consentStore.hasPendingDraft {
            let accepted = await consentStore.saveProfile(profile)
            guard operationGeneration == generation else { return }
            if accepted {
                finishDocumentProfile(profile)
                if let loadedClient {
                    state = .saved(loadedClient)
                }
            } else if consentStore.failure == .authorization {
                close()
            } else {
                state = .failed(.save, .persistenceUnavailable)
            }
            return
        }
        if consentStore?.phase == .choosing || consentStore?.requiresReconciliation == true {
            state = .failed(.save, .conflict)
            return
        }
        do {
            let client: Client
            if loadedClient != nil || destination.mode == .edit {
                client = try await update(destination.clientID, profile, context)
            } else {
                client = try await create(destination.clientID, profile, context)
            }
            guard operationGeneration == generation else { return }
            loadedClient = client
            savedFields = fields
            state = .saved(client)
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.save, clientError(error))
        }
    }

    /// Accepts an already-confirmed deactivation of a loaded client, excluding overlapping or repeated requests.
    /// Confirmation presentation belongs to the caller; success means local acceptance, not remote convergence.
    func deactivate(in context: ModelContext) async {
        guard destination.mode == .edit, canEdit, !Task.isCancelled else { return }
        let generation = UUID()
        operationGeneration = generation
        state = .deactivating
        do {
            try await deactivateClient(destination.clientID, context)
            guard operationGeneration == generation else { return }
            state = .deactivated
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.deactivate, clientError(error))
        }
    }

    /// Closes presentation and ignores later responses without claiming to roll back accepted writes.
    func close() {
        operationGeneration = UUID()
        consentStore?.close()
        fields = ClientFormFields()
        savedFields = fields
        loadedClient = nil
        state = .closed
    }

    /// Ends the document presentation; the caller cancels its task and later recovery reconciles durable work.
    func dismissConsentPresentation() {
        operationGeneration = UUID()
        consentStore?.dismiss()
    }

    /// Serializes document intentions and adopts activation only from its durable receipt-backed operation.
    func performConsent(_ action: ConsentAction) async {
        guard state != .closed, consentStore?.isBusy != true, let consentStore else { return }
        switch state {
        case .saving, .deactivating, .loading: return
        default: break
        }
        let generation = UUID()
        operationGeneration = generation
        let submittedFields = fields
        let hadUnsavedChanges = hasUnsavedChanges
        var persistedProfile: ClientProfile?
        switch action {
        case .information:
            await consentStore.showInformation()
        case .backToForm:
            consentStore.dismiss()
        case .captured(let result, let id):
            await consentStore.completeCapture(result, id: id)
        case .accept:
            await consentStore.accept()
        case .upload:
            let activated = await consentStore.upload()
            guard operationGeneration == generation, !Task.isCancelled else { return }
            if consentStore.failure != .authorization {
                do {
                    let current: Client
                    if let activated {
                        current = activated
                    } else {
                        current = try await getClient(destination.clientID)
                    }
                    guard operationGeneration == generation, !Task.isCancelled else { return }
                    loadedClient = current
                    savedFields = ClientFormFields(current)
                    if !hadUnsavedChanges, fields == submittedFields {
                        fields = savedFields
                    }
                } catch {
                    // The document failure remains actionable; a later reopen reconciles the client snapshot.
                }
            }
        case .discard:
            await consentStore.discard()
        case .selectDelivery(let id):
            consentStore.selectDelivery(id: id)
        case .recover:
            persistedProfile = await recoverConsent(store: consentStore, generation: generation)
        default:
            persistedProfile = await performProfileConsent(action, store: consentStore)
        }
        guard operationGeneration == generation else { return }
        if consentStore.failure == .authorization {
            close()
        } else if let persistedProfile, fields == submittedFields {
            finishDocumentProfile(persistedProfile)
        }
    }

    private func performProfileConsent(_ action: ConsentAction, store: ClientConsentStore) async -> ClientProfile? {
        let profile: ClientProfile
        do {
            if action == .useCurrentProfile, let loadedClient {
                profile = try consentProfile(loadedClient)
            } else {
                profile = try normalizedProfile()
            }
        } catch {
            state = .failed(.save, clientError(error))
            return nil
        }
        switch action {
        case .review, .currentContent:
            guard canReviewConsent else { return nil }
            state = .editing
            return await store.review(profile: profile, currentContent: action == .currentContent) ? profile : nil
        case .selectDraft(let id):
            store.selectDraft(id: id, profile: profile)
            if store.phase == .review {
                return await store.review(profile: profile) ? profile : nil
            }
        case .useCurrentProfile:
            return await store.resolveProfile(useDraft: false, current: profile)
        case .authorizePhoto:
            await store.choosePhoto(.authorized)
        case .declinePhoto:
            await store.choosePhoto(.declined)
        case .removePhoto:
            await store.choosePhoto(.notSelected)
        default:
            break
        }
        return nil
    }

    /// Reloads the durable profile after a conflict while retaining unsubmitted edits until an explicit choice.
    private func recoverConsent(store: ClientConsentStore, generation: UUID) async -> ClientProfile? {
        do {
            var current = try normalizedProfile()
            if loadedClient != nil || destination.mode == .edit {
                let latest = try await getClient(destination.clientID)
                try Task.checkCancellation()
                guard operationGeneration == generation else { return nil }
                current = try consentProfile(latest)
                let preservesEdits = hasUnsavedChanges
                loadedClient = latest
                savedFields = ClientFormFields(latest)
                if !preservesEdits {
                    fields = savedFields
                }
            }
            await store.recover(profile: current)
            let submitted = try normalizedProfile()
            return await store.review(profile: submitted) ? submitted : nil
        } catch {
            guard operationGeneration == generation else { return nil }
            if !(error is CancellationError) {
                state = .failed(.save, clientError(error))
            }
            return nil
        }
    }

    private func consentProfile(_ client: Client) throws -> ClientProfile {
        try ClientProfile(
            displayName: client.displayName,
            taxIdentifier: client.taxIdentifier,
            billingAddress: client.billingAddress
        )
    }

    private func normalizedProfile() throws -> ClientProfile {
        try prepareProfile(
            displayName: fields.displayName,
            taxIdentifier: fields.taxIdentifier,
            streetLine: fields.streetLine,
            postalCode: fields.postalCode,
            city: fields.city,
            province: fields.province
        )
    }

    private func finishDocumentProfile(_ profile: ClientProfile) {
        let client = Client(
            id: destination.clientID,
            displayName: profile.displayName,
            taxIdentifier: profile.taxIdentifier,
            billingAddress: profile.billingAddress,
            status: loadedClient?.status ?? .draft
        )
        loadedClient = client
        fields = ClientFormFields(client)
        savedFields = fields
    }

    private func clientError(_ error: any Error) -> ClientError {
        error as? ClientError ?? .persistenceUnavailable
    }
}
