import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Recoverable signed document persistence")
@MainActor
struct ClientDocumentPersistenceTests {
    @Test("A signed draft and its profile survive reopening before rendering")
    func signedDraftSurvivesReopening() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("documents.store")
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let saved = try await ClientDocumentPersistenceFixtures.save(original, at: url)
        let reopened = try ClientDocumentPersistenceFixtures.container(at: url)
        let actor = ClientDocumentPersistenceActor(modelContainer: reopened)
        let restored = try #require(try await actor.draft(id: original.id))
        #expect(restored == saved)
        #expect(restored.fields.signedAt == ClientDocumentTestFixtures.date)
        #expect(restored.fields.binding == original.fields.binding)
        let context = ModelContext(reopened)
        let client = try #require(context.fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(client.status == .draft)
        #expect(client.displayName == original.fields.profile.displayName)
        #expect(try context.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)
    }

    @Test("A failed save leaves no profile, client operation or partial draft")
    func failedSaveRollsBackEveryRow() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container) { _ in
            throw ClientDocumentPersistenceError.persistenceUnavailable
        }
        let original = try await ClientDocumentPersistenceFixtures.draft()
        await #expect(throws: ClientDocumentPersistenceError.persistenceUnavailable) {
            try await actor.saveDraft(original, operationID: UUID())
        }
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<ClientModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 0)
        let recovered = ClientDocumentPersistenceActor(modelContainer: container)
        let saved = try await recovered.saveDraft(original, operationID: UUID())
        #expect(saved.fields.binding == original.fields.binding)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)
    }

    @Test("A stale draft and a render from its old revision cannot replace newer work")
    func staleWorkIsRejected() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let saved = try await actor.saveDraft(original, operationID: UUID())
        let changed = try saved.revising(
            profile: ClientProfile(displayName: saved.fields.profile.displayName, taxIdentifier: "synthetic-tax"),
            snapshot: saved.fields.snapshot
        )
        let latest = try await actor.saveDraft(changed, operationID: UUID())
        await #expect(throws: ClientDocumentPersistenceError.staleDraft) {
            try await actor.saveDraft(saved, operationID: UUID())
        }
        let document = try ClientDocumentPersistenceFixtures.document(saved)
        await #expect(throws: ClientDocumentPersistenceError.staleDraft) {
            try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
        }
        #expect(try await actor.draft(id: saved.id) == latest)
        #expect(try await actor.delivery(id: document.id) == nil)
    }

    @Test("Acceptance retains exact bytes; duplicate is a no-op and different bytes preserve a conflict")
    func duplicateAndPayloadConflict() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let saved = try await actor.saveDraft(ClientDocumentPersistenceFixtures.draft(), operationID: UUID())
        let document = try ClientDocumentPersistenceFixtures.document(saved)
        let accepted = try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
        let repeated = try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
        #expect(repeated == accepted)
        let different = try ClientSignedDocument(.init(
            binding: document.fields.binding,
            signedAt: document.fields.signedAt,
            pdf: Data("%PDF-1.7\nDIFFERENT SYNTHETIC ARTIFACT\n%%EOF\n".utf8)
        ))
        await #expect(throws: ClientDocumentPersistenceError.documentConflict) {
            try await actor.accept(different, draftID: saved.id, revision: saved.fields.revision)
        }
        let retained = try #require(try await actor.delivery(id: document.id))
        #expect(retained.document.fields.pdf == document.fields.pdf)
        #expect(retained.state == .conflict(receipt: nil))
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 1)
    }

    @Test("Accepted artifacts survive reopening and cannot be discarded as editing work")
    func acceptedDocumentSurvivesReopening() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("documents.store")
        let saved = try await ClientDocumentPersistenceFixtures.saveAndAccept(at: url)
        let container = try ClientDocumentPersistenceFixtures.container(at: url)
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let restored = try #require(try await actor.delivery(id: saved.document.id))
        #expect(restored == saved)
        await #expect(throws: ClientDocumentPersistenceError.alreadyAccepted) {
            try await actor.discardDraft(id: ClientDocumentPersistenceFixtures.draftID, revision: 1)
        }
        #expect(try await actor.delivery(id: saved.document.id) == saved)
    }

    @Test("Unsigned editing work can be discarded without deleting the client")
    func discardOnlyEditingWork() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let saved = try await actor.saveDraft(
            ClientDocumentPersistenceFixtures.draft(signed: false),
            operationID: UUID()
        )
        try await actor.discardDraft(id: saved.id, revision: saved.fields.revision)
        #expect(try await actor.draft(id: saved.id) == nil)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientModel>()) == 1)
    }

    @Test("Unknown envelope versions fail closed without removing the stored payload")
    func unknownEnvelopeIsPreserved() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let context = ModelContext(container)
        let model = try ClientDocumentDraftModel(original)
        model.payloadVersion = 42
        let bytes = model.payload
        context.insert(model)
        try context.save()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        await #expect(throws: ClientDocumentPersistenceError.unsupportedPayloadVersion) {
            try await actor.draft(id: original.id)
        }
        #expect(try ModelContext(container).fetch(FetchDescriptor<ClientDocumentDraftModel>()).first?.payload == bytes)
    }

    @Test("Editing unpresented fields preserves ink; changing the presentation invalidates it")
    func editingInvalidatesOnlyPresentedFacts() async throws {
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let samePresentation = try original.revising(
            profile: ClientProfile(displayName: original.fields.profile.displayName, taxIdentifier: "new-tax"),
            snapshot: original.fields.snapshot
        )
        #expect(samePresentation.fields.binding == original.fields.binding)
        #expect(samePresentation.fields.signedAt == original.fields.signedAt)
        let changedProfile = try ClientProfile(displayName: "Nombre revisado sintético")
        let revised = try original.revising(profile: changedProfile, snapshot: nil)
        #expect(revised.fields.binding == nil)
        #expect(revised.fields.signedAt == nil)
        #expect(original.fields.binding != nil)
    }

    @Test("Signing fixes a recoverable date and refuses an unprepared document")
    func signingRequiresPresentedSnapshot() async throws {
        let unsigned = try await ClientDocumentPersistenceFixtures.draft(signed: false)
        let ink = try #require(try await ClientDocumentPersistenceFixtures.draft().fields.binding).signature
        let signed = try unsigned.signing(with: ink, at: ClientDocumentTestFixtures.date)
        #expect(signed.fields.signedAt == ClientDocumentTestFixtures.date)
        #expect(signed.fields.binding?.snapshot == unsigned.fields.snapshot)
        let unprepared = try unsigned.revising(profile: unsigned.fields.profile, snapshot: nil)
        #expect(throws: ClientDocumentPersistenceError.invalidDraft) {
            try unprepared.signing(with: ink, at: ClientDocumentTestFixtures.date)
        }
    }

    @Test("Subsequent authorization preserves activation and the original consent", arguments: [false, true])
    func subsequentDocumentRequiresActiveClient(isActive: Bool) async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot(
            decision: .authorized,
            purpose: .subsequentPhotoAuthorization
        )
        let reference = try ClientConsentReference(rawValue: "legacy/initial-information.pdf")
        let container = try ClientDocumentPersistenceFixtures.container()
        let context = ModelContext(container)
        context.insert(ClientModel(Client(
            id: snapshot.fields.clientID,
            displayName: snapshot.fields.clientName,
            taxIdentifier: nil,
            billingAddress: nil,
            status: isActive ? .active(consentReference: reference) : .draft
        )))
        try context.save()
        let draft = try ClientDocumentDraft(.init(
            id: ClientDocumentPersistenceFixtures.draftID,
            clientID: snapshot.fields.clientID,
            profile: ClientProfile(displayName: snapshot.fields.clientName, taxIdentifier: "updated-tax"),
            snapshot: snapshot,
            binding: ClientDocumentTestFixtures.binding(snapshot),
            signedAt: ClientDocumentTestFixtures.date,
            revision: 0
        ))
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        if isActive {
            let saved = try await actor.saveDraft(draft, operationID: UUID())
            _ = try await actor.accept(
                ClientDocumentPersistenceFixtures.document(saved),
                draftID: saved.id,
                revision: saved.fields.revision
            )
            let client = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first).toDomain()
            #expect(client.status == .active(consentReference: reference))
            #expect(client.taxIdentifier == "updated-tax")
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 1)
        } else {
            await #expect(throws: ClientDocumentPersistenceError.invalidDraft) {
                try await actor.saveDraft(draft, operationID: UUID())
            }
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 0)
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 0)
        }
    }

    @Test("Mismatched indexed identity or revision cannot bypass envelope validation", arguments: [0, 1, 2])
    func mismatchedEnvelopeMetadataIsPreserved(field: Int) async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let model = try await ClientDocumentDraftModel(ClientDocumentPersistenceFixtures.draft())
        switch field {
        case 0: model.id = UUID()
        case 1: model.clientID = UUID()
        default: model.revision += 1
        }
        let lookupID = model.id
        let bytes = model.payload
        let context = ModelContext(container)
        context.insert(model)
        try context.save()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        await #expect(throws: ClientDocumentPersistenceError.invalidPayload) {
            try await actor.draft(id: lookupID)
        }
        #expect(try ModelContext(container).fetch(FetchDescriptor<ClientDocumentDraftModel>()).first?.payload == bytes)
    }

    @Test("A cancelled duplicate reports cancellation and preserves the accepted value")
    func cancelledDuplicateDoesNotChangeAcceptance() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let saved = try await actor.saveDraft(ClientDocumentPersistenceFixtures.draft(), operationID: UUID())
        let document = try ClientDocumentPersistenceFixtures.document(saved)
        let accepted = try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
        let duplicate = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
        }
        await #expect(throws: CancellationError.self) { try await duplicate.value }
        #expect(try await actor.delivery(id: document.id) == accepted)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)
    }

    @Test("A real multipage PDF survives disk recovery with exactly the rendered bytes")
    func longRenderedArtifactSurvivesDiskRecovery() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot(longText: true)
        let document = try await ClientDocumentTestFixtures.render(snapshot)
        let draft = try ClientDocumentDraft(.init(
            id: ClientDocumentPersistenceFixtures.draftID,
            clientID: snapshot.fields.clientID,
            profile: ClientProfile(displayName: snapshot.fields.clientName),
            snapshot: snapshot,
            binding: document.fields.binding,
            signedAt: document.fields.signedAt,
            revision: 0
        ))
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("multipage.store")
        try await ClientDocumentPersistenceFixtures.persist(document, draft: draft, at: url)
        let container = try ClientDocumentPersistenceFixtures.container(at: url)
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let recovered = try #require(try await actor.delivery(id: document.id))
        #expect(recovered.document == document)
        #expect(recovered.document.fields.pdf == document.fields.pdf)
        #expect(recovered.document.fields.binding.snapshot.fields.content.fields.sections.last?.heading ==
                "Sección sintética 80")
    }
}

struct ClientDocumentPersistenceFixtures {
    static let draftID = UUID(uuidString: "00000000-0000-0000-0000-000000000086")!
    static let bytes = Data("%PDF-1.7\nSYNTHETIC RETAINED ARTIFACT\n%%EOF\n".utf8)

    static func draft(signed: Bool = true) async throws -> ClientDocumentDraft {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        return try ClientDocumentDraft(.init(
            id: draftID,
            clientID: snapshot.fields.clientID,
            profile: ClientProfile(displayName: snapshot.fields.clientName),
            snapshot: snapshot,
            binding: signed ? ClientDocumentTestFixtures.binding(snapshot) : nil,
            signedAt: signed ? ClientDocumentTestFixtures.date : nil,
            revision: 0
        ))
    }

    static func document(_ draft: ClientDocumentDraft) throws -> ClientSignedDocument {
        try ClientSignedDocument(.init(
            binding: #require(draft.fields.binding),
            signedAt: #require(draft.fields.signedAt),
            pdf: bytes
        ))
    }

    static func container(at url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: ClientDocumentsSchema.self)
        guard let url else { return try ModelContainer.inMemory(for: schema) }
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func save(_ draft: ClientDocumentDraft, at url: URL) async throws -> ClientDocumentDraft {
        let actor = try ClientDocumentPersistenceActor(modelContainer: container(at: url))
        return try await actor.saveDraft(draft, operationID: UUID())
    }

    static func saveAndAccept(at url: URL) async throws -> ClientDocumentDelivery {
        let actor = try ClientDocumentPersistenceActor(modelContainer: container(at: url))
        let saved = try await actor.saveDraft(draft(), operationID: UUID())
        return try await actor.accept(document(saved), draftID: saved.id, revision: saved.fields.revision)
    }

    static func persist(_ document: ClientSignedDocument, draft: ClientDocumentDraft, at url: URL) async throws {
        let actor = try ClientDocumentPersistenceActor(modelContainer: container(at: url))
        let saved = try await actor.saveDraft(draft, operationID: UUID())
        _ = try await actor.accept(document, draftID: saved.id, revision: saved.fields.revision)
    }
}
