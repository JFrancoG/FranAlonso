import Foundation
import Observation

/// Owns recoverable document work and receipt-backed activation independently of form navigation.
@Observable @MainActor
final class ClientConsentStore {
    enum Phase: Equatable {
        case idle, information, choosing, profileConflict, review, capture, signatureReview, retained, closed
    }

    enum Operation: Equatable {
        case information, recover, save, signature, render, upload, activate, discard
    }

    enum Failure: Equatable {
        case catalog, persistence, rendering, authorization, conflict, photoDecision, unavailable, permission
        case activation
    }

    let clientID: ClientID
    let services: ClientConsentServices
    private(set) var phase: Phase = .idle
    private(set) var operation: Operation?
    private(set) var failure: Failure?
    private(set) var information: ClientDocumentContent?
    private(set) var draft: ClientDocumentDraft?
    private(set) var delivery: ClientDocumentDelivery?
    private(set) var pendingDrafts: [ClientDocumentDraft] = []
    private(set) var deliveries: [ClientDocumentDelivery] = []
    private(set) var captureID: UUID?
    private(set) var isPresented = false
    private(set) var isRecovered = false
    private(set) var requiresReconciliation = false
    private(set) var presentationIsStale = false
    private(set) var isActivated = false

    var isBusy: Bool { operation != nil }
    var snapshot: ClientDocumentSnapshot? { delivery?.document.fields.binding.snapshot ?? draft?.fields.snapshot }
    var content: ClientDocumentContent? { phase == .information ? information : snapshot?.fields.content }
    var signature: ClientSignature? {
        guard !presentationIsStale else { return nil }
        return delivery?.document.fields.binding.signature ?? draft?.fields.binding?.signature
    }
    var hasPendingDraft: Bool { draft != nil && delivery == nil }
    var canCapture: Bool {
        !isBusy && !requiresReconciliation && !presentationIsStale && failure == nil && phase == .review
            && snapshot?.fields.context.photoDecision != .undecided && snapshot != nil && delivery == nil
    }

    var canAccept: Bool {
        !isBusy && !requiresReconciliation && !presentationIsStale
            && phase == .signatureReview && signature != nil && delivery == nil
    }

    /// Keeps the retry control present while its operation runs; execution is gated separately.
    var hasUploadAction: Bool {
        guard !requiresReconciliation, !isActivated, phase == .retained, let delivery else { return false }
        switch delivery.state {
        case .pending, .failed: return true
        case .uploaded: return delivery.document.fields.binding.snapshot.fields.context.purpose == .initialInformation
        case .conflict: return false
        }
    }

    var canUpload: Bool { !isBusy && hasUploadAction }

    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var phaseBeforeInformation: Phase?

    init(clientID: ClientID, services: ClientConsentServices) {
        self.clientID = clientID
        self.services = services
    }

    /// Loads public information without requiring a personal snapshot or performing a client write.
    func showInformation() async {
        guard !isBusy, phase != .closed else { return }
        isPresented = true
        await perform(.information) { token in
            let text = try await services.catalog.content(
                variant: .dataInformation,
                version: services.version,
                language: services.language
            )
            try check(token)
            information = text
            if phase != .information {
                phaseBeforeInformation = phase
            }
            phase = .information
        }
    }

    /// Resolves durable work by client identity; UUID ordering never chooses between competing drafts.
    func recover(profile: ClientProfile) async {
        guard !isBusy, phase != .closed else { return }
        await perform(.recover) { token in
            let drafts = try await services.repository.drafts(clientID: clientID)
            let retained = try await services.repository.deliveries(clientID: clientID)
            try check(token)
            let acceptedIDs = Set(retained.map(\.id))
            pendingDrafts = drafts.filter { value in
                value.fields.snapshot.map { !acceptedIDs.contains($0.id) } ?? true
            }
            deliveries = retained
            isActivated = false
            draft = nil
            delivery = nil
            captureID = nil
            isRecovered = true
            requiresReconciliation = false
            if pendingDrafts.count + retained.count > 1 {
                phase = .choosing
            } else if let pending = pendingDrafts.first {
                restore(pending, profile: profile)
            } else if let accepted = retained.first {
                delivery = accepted
                phase = .retained
            } else {
                phase = .idle
            }
        }
    }

    /// Saves a reviewed presentation before capture and reuses unchanged signed content on return.
    @discardableResult
    func review(
        profile: ClientProfile,
        context: ClientDocumentContext? = nil,
        currentContent: Bool = false
    ) async -> Bool {
        guard !isBusy, phase != .closed else { return false }
        isPresented = true
        if phase == .information {
            phase = phaseBeforeInformation ?? .idle
        }
        if !isRecovered || requiresReconciliation {
            await recover(profile: profile)
            guard failure == nil, !requiresReconciliation else { return false }
        }
        if delivery != nil {
            phase = .retained
            return false
        }
        guard phase != .choosing, phase != .profileConflict else { return false }
        await perform(.save) { token in
            let context = context ?? draft?.fields.snapshot?.fields.context
                ?? ClientDocumentContext(purpose: .initialInformation, photoDecision: .notSelected)
            let snapshot = try await preparedSnapshot(
                profile: profile,
                context: context,
                currentContent: currentContent
            )
            try check(token)
            try await persist(profile: profile, snapshot: snapshot, token: token)
            phase = draft?.fields.binding == nil ? .review : .signatureReview
        }
        return failure == nil && !requiresReconciliation && draft?.fields.profile == profile
    }

    func selectDraft(id: UUID, profile: ClientProfile) {
        guard !isBusy, phase == .choosing, let selected = pendingDrafts.first(where: { $0.id == id }) else { return }
        failure = nil
        delivery = nil
        restore(selected, profile: profile)
    }

    func selectDelivery(id: UUID) {
        guard !isBusy, phase == .choosing, let selected = deliveries.first(where: { $0.id == id }) else { return }
        failure = nil
        draft = nil
        delivery = selected
        isActivated = false
        phase = .retained
    }

    /// An explicit choice adopts the current client profile; dismissing leaves the older work untouched.
    func resolveProfile(useDraft: Bool, current: ClientProfile) async -> ClientProfile? {
        guard !isBusy, phase == .profileConflict, !useDraft else { return nil }
        phase = .review
        return await review(profile: current) ? current : nil
    }

    /// Changing the optional decision produces a new presentation; undecided ink is never accepted.
    func choosePhoto(_ decision: ClientDocumentPhotoDecision) async {
        guard !isBusy, delivery == nil, let draft, phase == .review || phase == .signatureReview else { return }
        await review(
            profile: draft.fields.profile,
            context: .init(purpose: .initialInformation, photoDecision: decision)
        )
    }

    func startCapture() -> UUID? {
        guard canCapture else { return nil }
        let id = UUID()
        captureID = id
        phase = .capture
        return id
    }

    /// Correlates one terminal capture with its presentation and durably fixes ink/date before rendering.
    func completeCapture(_ result: ClientSignatureCaptureViewModel.Completion, id: UUID) async {
        guard !isBusy, phase == .capture, captureID == id, let draft else { return }
        captureID = nil
        switch result {
        case .cancelled:
            phase = draft.fields.binding == nil ? .review : .signatureReview
        case .captured(let signature):
            await perform(.signature) { token in
                let signed = try draft.signing(with: signature, at: services.now())
                self.draft = signed
                phase = .signatureReview
                let saved = try await services.repository.saveDraft(signed, operationID: services.newID())
                try check(token)
                self.draft = saved
                phase = .signatureReview
            }
        }
    }

    /// Accepts only the signed revision retained before rendering; output remains immutable thereafter.
    func accept() async {
        guard canAccept, let draft else { return }
        await perform(.render) { token in
            let saved = try await services.repository.saveDraft(draft, operationID: services.newID())
            try check(token)
            self.draft = saved
            let accepted = try await RenderAndPersistConsentUseCase(
                repository: services.repository,
                renderer: services.renderer
            )(draftID: draft.id)
            try check(token)
            delivery = accepted
            phase = .retained
        }
    }

    /// Resumes initial activation from its durable receipt; later documents keep their independent upload path.
    @discardableResult
    func upload() async -> Client? {
        guard !isBusy, !requiresReconciliation, phase == .retained, let delivery else { return nil }
        if case .conflict = delivery.state {
            return nil
        }
        let isInitial = delivery.document.fields.binding.snapshot.fields.context.purpose == .initialInformation
        var activatedClient: Client?
        await perform(isInitial ? .activate : .upload) { token in
            do {
                let upload = UploadConsentUseCase(
                    repository: services.repository,
                    storage: services.storage,
                    now: services.now
                )
                if isInitial {
                    let client = try await ActivateClientUseCase(
                        repository: services.activationRepository,
                        upload: upload,
                        makeOperationID: services.newID
                    )(clientID: clientID, documentID: delivery.id)
                    try check(token)
                    activatedClient = client
                } else {
                    _ = try await upload(documentID: delivery.id)
                }
            } catch {
                let errorToReport = error
                let retained = try await services.repository.delivery(id: delivery.id)
                try check(token)
                self.delivery = retained
                throw errorToReport
            }
            let retained = try await services.repository.delivery(id: delivery.id)
            try check(token)
            self.delivery = retained
            isActivated = activatedClient != nil
        }
        return failure == nil && !requiresReconciliation && phase != .closed ? activatedClient : nil
    }

    func discard() async {
        guard !isBusy, !requiresReconciliation, delivery == nil, let draft else { return }
        await perform(.discard) { token in
            try await services.repository.discardDraft(id: draft.id, revision: draft.fields.revision)
            try check(token)
            self.draft = nil
            pendingDrafts.removeAll { $0.id == draft.id }
            phase = .idle
            isPresented = false
            isRecovered = false
        }
    }

    /// Routes later form edits through the same atomic document write instead of a second CRUD path.
    func saveProfile(_ profile: ClientProfile) async -> Bool {
        guard !isBusy, !requiresReconciliation, hasPendingDraft, phase != .profileConflict else { return false }
        let wasPresented = isPresented
        let saved = await review(profile: profile)
        isPresented = wasPresented
        return saved
    }

    /// Leaves valid durable work recoverable. An interrupted operation must be reloaded before retrying.
    func dismiss() {
        guard phase != .closed else { return }
        if isBusy {
            requiresReconciliation = true
            phase = .idle
        } else if phase == .information {
            phase = phaseBeforeInformation ?? .idle
        } else if phase == .capture {
            phase = draft?.fields.binding == nil ? .review : .signatureReview
        }
        generation = UUID()
        operation = nil
        captureID = nil
        isPresented = false
    }

    /// Invalidates a capture immediately when an included editable fact changes, before another async intent.
    func invalidatePresentation(clientName: String) {
        guard delivery == nil, let snapshot,
              snapshot.fields.clientName != clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return }
        presentationIsStale = true
        captureID = nil
        if phase == .capture {
            phase = .review
        }
    }

    /// Revokes presentation copies without deleting durable work owned by the authorized repository.
    func close() {
        generation = UUID()
        operation = nil
        captureID = nil
        information = nil
        draft = nil
        delivery = nil
        pendingDrafts = []
        deliveries = []
        failure = nil
        phase = .closed
        isPresented = false
        requiresReconciliation = true
        presentationIsStale = false
        isActivated = false
    }

    private func restore(_ value: ClientDocumentDraft, profile: ClientProfile) {
        draft = value
        presentationIsStale = value.fields.profile.displayName != profile.displayName
        if value.fields.profile != profile {
            phase = .profileConflict
        } else {
            phase = value.fields.binding == nil ? .review : .signatureReview
        }
    }

    private func preparedSnapshot(
        profile: ClientProfile,
        context: ClientDocumentContext,
        currentContent: Bool
    ) async throws -> ClientDocumentSnapshot {
        guard context.purpose == .initialInformation else { throw ClientDocumentError.invalidContext }
        if let previous = draft?.fields.snapshot,
           previous.fields.clientName == profile.displayName,
           previous.fields.context == context {
            if !currentContent {
                return previous
            }
            let content = try await services.catalog.content(
                variant: context.variant,
                version: services.version,
                language: services.language
            )
            if content == previous.fields.content {
                return previous
            }
        }
        return try await PrepareClientDocumentUseCase(catalog: services.catalog, newID: services.newID)(
            clientID: clientID,
            clientName: profile.displayName,
            context: context,
            version: services.version,
            language: services.language
        )
    }

    private func persist(profile: ClientProfile, snapshot: ClientDocumentSnapshot, token: UUID) async throws {
        let value: ClientDocumentDraft
        if let draft {
            value = try draft.revising(profile: profile, snapshot: snapshot)
        } else {
            value = try ClientDocumentDraft(.init(
                id: services.newID(),
                clientID: clientID,
                profile: profile,
                snapshot: snapshot,
                binding: nil,
                signedAt: nil,
                revision: 0
            ))
        }
        let saved = try await services.repository.saveDraft(value, operationID: services.newID())
        try check(token)
        draft = saved
        presentationIsStale = false
        captureID = nil
    }

    private func check(_ token: UUID) throws {
        try Task.checkCancellation()
        guard generation == token, phase != .closed else { throw CancellationError() }
    }

    private func perform(
        _ operation: Operation,
        body: @MainActor (UUID) async throws -> Void
    ) async {
        guard !isBusy, phase != .closed, !Task.isCancelled else { return }
        let token = UUID()
        generation = token
        self.operation = operation
        failure = nil
        defer {
            if generation == token {
                self.operation = nil
            }
        }
        do {
            try await body(token)
        } catch {
            guard generation == token, phase != .closed else { return }
            if error is CancellationError || Task.isCancelled {
                requiresReconciliation = true
                captureID = nil
                phase = .idle
            } else if error is ClientDocumentAccessError || error is LocalPrincipalAuthorizationError {
                close()
                failure = .authorization
            } else {
                failure = failure(for: error, operation: operation)
                if failure == .conflict {
                    requiresReconciliation = true
                    captureID = nil
                }
                if phase == .capture {
                    phase = .review
                }
            }
        }
    }

    private func failure(for error: any Error, operation: Operation) -> Failure {
        if let activation = error as? ClientActivationError {
            return activation == .uploadRequired ? .activation : .conflict
        }
        if let client = error as? ClientError, client == .conflict || client == .deactivated || client == .notFound {
            return .conflict
        }
        if let storage = error as? ClientDocumentStorageError {
            switch storage {
            case .conflict: return .conflict
            case .permissionDenied: return .permission
            default: return .unavailable
            }
        }
        if let persistence = error as? ClientDocumentPersistenceError {
            switch persistence {
            case .staleDraft, .documentConflict, .alreadyAccepted: return .conflict
            default: return operation == .activate && delivery?.state.isUploaded == true ? .activation : .persistence
            }
        }
        if let error = error as? ClientDocumentError {
            switch error {
            case .photoDecisionRequired: return .photoDecision
            case .renderingFailed, .invalidArtifact: return .rendering
            default: return .catalog
            }
        }
        return operation == .render ? .rendering : .persistence
    }
}
