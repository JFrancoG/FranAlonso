import Foundation
import SwiftData

/// Owns atomic local acceptance of profile, causal client work, draft and definitive documents.
/// Repositories sharing a container must share this owner so document transitions remain serialized.
@ModelActor
actor ClientDocumentPersistenceActor {
    private var saveChanges: @Sendable (ModelContext) throws -> Void = { try $0.save() }

    /// Allows deterministic storage failures while retaining the real transaction and rollback path.
    init(
        modelContainer: ModelContainer,
        saveChanges: @escaping @Sendable (ModelContext) throws -> Void
    ) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.saveChanges = saveChanges
    }

    /// Saves profile, causal work and editing state together, incrementing the optimistic revision once.
    /// An unchanged draft is idempotent; stale edits, retired document identities and accepted drafts are rejected.
    func saveDraft(_ draft: ClientDocumentDraft, operationID: UUID) throws -> ClientDocumentDraft {
        try transaction {
            guard try acceptedModel(draftID: draft.id) == nil else {
                throw ClientDocumentPersistenceError.alreadyAccepted
            }
            let model = try draftModel(id: draft.id)
            if let existing = try model?.toDomain() {
                guard existing.fields.clientID == draft.fields.clientID else {
                    throw ClientDocumentPersistenceError.invalidDraft
                }
                if try atRevision(draft, existing.fields.revision) == existing {
                    return existing
                }
                guard existing.fields.revision == draft.fields.revision else {
                    throw ClientDocumentPersistenceError.staleDraft
                }
            } else {
                guard draft.fields.revision == 0 else { throw ClientDocumentPersistenceError.staleDraft }
            }
            guard draft.fields.revision < Int.max else { throw ClientDocumentPersistenceError.invalidDraft }
            let updated = try atRevision(draft, draft.fields.revision + 1)
            let clients = ClientLocalDataSource()
            let existingClient = try clients.client(id: draft.fields.clientID, in: modelContext)
            if draft.fields.snapshot?.fields.context.purpose == .subsequentPhotoAuthorization {
                guard case .active = existingClient?.status else {
                    throw ClientDocumentPersistenceError.invalidDraft
                }
            }
            let client = Client(
                id: draft.fields.clientID,
                displayName: draft.fields.profile.displayName,
                taxIdentifier: draft.fields.profile.taxIdentifier,
                billingAddress: draft.fields.profile.billingAddress,
                status: existingClient?.status ?? .draft
            )
            try clients.stagePendingUpsert(client, operationID: operationID, in: modelContext)
            if let model {
                try model.update(updated)
            } else {
                modelContext.insert(try ClientDocumentDraftModel(updated))
            }
            return updated
        }
    }

    func draft(id: UUID) throws -> ClientDocumentDraft? {
        try Task.checkCancellation()
        return try draftModel(id: id)?.toDomain()
    }

    /// Finds recoverable editing work from a client identity after the caller has lost its ephemeral draft ID.
    func drafts(clientID: ClientID) throws -> [ClientDocumentDraft] {
        try Task.checkCancellation()
        let rawClientID = clientID.rawValue
        let descriptor = FetchDescriptor<ClientDocumentDraftModel>(
            predicate: #Predicate { $0.clientID == rawClientID }
        )
        return try modelContext.fetch(descriptor)
            .map { try $0.toDomain() }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// Finds durable artifacts and pending deliveries without relying on a previous process's document IDs.
    func deliveries(clientID: ClientID) throws -> [ClientDocumentDelivery] {
        try Task.checkCancellation()
        let rawClientID = clientID.rawValue
        let descriptor = FetchDescriptor<ClientSignedDocumentModel>(
            predicate: #Predicate { $0.clientID == rawClientID }
        )
        return try modelContext.fetch(descriptor)
            .map { try $0.toDomain() }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// Reuses an identical artifact; a competing payload becomes a durable conflict without replacing the original.
    /// A new artifact must match the current signed draft revision, binding and pre-render signing date.
    func accept(_ document: ClientSignedDocument, draftID: UUID, revision: Int) throws -> ClientDocumentDelivery {
        if let existing = try documentModel(id: document.id) {
            let retained = try existing.toDomain()
            guard retained.document == document, existing.draftID == draftID else {
                let receipt: ClientDocumentUploadReceipt?
                switch retained.state {
                case .uploaded(let value), .conflict(.some(let value)):
                    receipt = value
                default:
                    receipt = nil
                }
                try transaction { try existing.setState(.conflict(receipt: receipt)) }
                throw ClientDocumentPersistenceError.documentConflict
            }
            try Task.checkCancellation()
            return retained
        }
        return try transaction {
            guard try acceptedModel(draftID: draftID) == nil else {
                throw ClientDocumentPersistenceError.alreadyAccepted
            }
            guard let draft = try draftModel(id: draftID)?.toDomain() else {
                throw ClientDocumentPersistenceError.notFound
            }
            guard draft.fields.revision == revision else { throw ClientDocumentPersistenceError.staleDraft }
            guard draft.fields.binding == document.fields.binding,
                  draft.fields.signedAt == document.fields.signedAt
            else { throw ClientDocumentPersistenceError.invalidDraft }
            let model = try ClientSignedDocumentModel(draftID: draftID, document: document)
            modelContext.insert(model)
            return try model.toDomain()
        }
    }

    func delivery(id: UUID) throws -> ClientDocumentDelivery? {
        try Task.checkCancellation()
        return try documentModel(id: id)?.toDomain()
    }

    /// Discards only current unaccepted editing work; the client and its causal queue remain durable.
    func discardDraft(id: UUID, revision: Int) throws {
        try transaction {
            guard try acceptedModel(draftID: id) == nil else { throw ClientDocumentPersistenceError.alreadyAccepted }
            guard let model = try draftModel(id: id) else { return }
            let draft = try model.toDomain()
            guard draft.fields.revision == revision else { throw ClientDocumentPersistenceError.staleDraft }
            modelContext.delete(model)
        }
    }

    /// Commits one synchronous unit of work. Other methods of this actor share this save/rollback boundary.
    func transaction<Value>(_ operation: () throws -> Value) throws -> Value {
        try Task.checkCancellation()
        modelContext.autosaveEnabled = false
        guard !modelContext.hasChanges else { throw ClientDocumentPersistenceError.persistenceUnavailable }
        do {
            let value = try operation()
            try Task.checkCancellation()
            if modelContext.hasChanges {
                try saveChanges(modelContext)
            }
            // Cancellation after the durable boundary reports no success; rollback cannot undo that commit.
            try Task.checkCancellation()
            return value
        } catch {
            modelContext.rollback()
            switch error {
            case let error as ClientDocumentPersistenceError:
                throw error
            case let error as ClientError:
                throw error
            case let error as ClientDocumentStorageError:
                throw error
            case is CancellationError:
                throw CancellationError()
            case ClientLocalDataSourceError.syncConflictPending:
                throw ClientError.conflict
            case ClientLocalDataSourceError.restoreRequiresExplicitResolution:
                throw ClientError.deactivated
            default:
                throw ClientDocumentPersistenceError.persistenceUnavailable
            }
        }
    }

    private func atRevision(_ draft: ClientDocumentDraft, _ revision: Int) throws -> ClientDocumentDraft {
        try ClientDocumentDraft(.init(
            id: draft.id,
            clientID: draft.fields.clientID,
            profile: draft.fields.profile,
            snapshot: draft.fields.snapshot,
            binding: draft.fields.binding,
            signedAt: draft.fields.signedAt,
            revision: revision
        ))
    }

    private func draftModel(id: UUID) throws -> ClientDocumentDraftModel? {
        var descriptor = FetchDescriptor<ClientDocumentDraftModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func documentModel(id: UUID) throws -> ClientSignedDocumentModel? {
        var descriptor = FetchDescriptor<ClientSignedDocumentModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func acceptedModel(draftID: UUID) throws -> ClientSignedDocumentModel? {
        var descriptor = FetchDescriptor<ClientSignedDocumentModel>(predicate: #Predicate { $0.draftID == draftID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
