import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Recoverable draft document identity")
@MainActor
struct ClientDocumentDraftIdentityTests {
    @Test("Clearing and reopening a signed draft cannot release its old document identity")
    func clearedDraftRejectsRetiredDocumentIdentityAfterReopening() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "draft-identity.store")
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let cleared = try await saveClearedDraft(original, at: url)
        let container = try ClientDocumentPersistenceFixtures.container(at: url)
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let recovered = try #require(try await actor.draft(id: cleared.id))
        #expect(recovered.fields.snapshot == nil)
        let before = try persistedRows(in: container)
        let previousSnapshot = try #require(original.fields.snapshot)
        let replacement = try replacementDraft(recovered, previousSnapshot: previousSnapshot, id: previousSnapshot.id)

        await #expect(throws: ClientDocumentPersistenceError.documentConflict) {
            try await actor.saveDraft(replacement, operationID: UUID())
        }

        #expect(try await actor.draft(id: recovered.id) == recovered)
        #expect(try persistedRows(in: container) == before)
    }

    @Test("A constructed draft cannot replace a persisted signed presentation under the same ID")
    func constructedDraftCannotBypassSignedPresentationIdentity() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let saved = try await actor.saveDraft(original, operationID: UUID())
        let before = try persistedRows(in: container)
        let previousSnapshot = try #require(saved.fields.snapshot)
        let replacement = try replacementDraft(saved, previousSnapshot: previousSnapshot, id: previousSnapshot.id)

        await #expect(throws: ClientDocumentPersistenceError.documentConflict) {
            try await actor.saveDraft(replacement, operationID: UUID())
        }

        #expect(try await actor.draft(id: saved.id) == saved)
        #expect(try persistedRows(in: container) == before)
    }

    @Test("Cancellation after save reports cancellation while the committed draft remains recoverable")
    func cancellationAfterCommitDoesNotReportSuccessOrLoseRows() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let actor = ClientDocumentPersistenceActor(modelContainer: container) { context in
            try context.save()
            withUnsafeCurrentTask { $0?.cancel() }
        }
        let saving = Task {
            try await actor.saveDraft(original, operationID: UUID())
        }

        await #expect(throws: CancellationError.self) {
            try await saving.value
        }

        let reopenedActor = ClientDocumentPersistenceActor(modelContainer: container)
        let recovered = try #require(try await reopenedActor.draft(id: original.id))
        #expect(recovered.fields.revision == 1)
        #expect(recovered.fields.profile == original.fields.profile)
        #expect(recovered.fields.binding == original.fields.binding)
        #expect(recovered.fields.signedAt == original.fields.signedAt)
        let rows = try persistedRows(in: container)
        #expect(rows.clients.count == 1)
        #expect(rows.clients.first?.displayName == original.fields.profile.displayName)
        #expect(rows.drafts.count == 1)
        #expect(rows.upserts.count == 1)
        #expect(rows.upserts.first?.payload.displayName == original.fields.profile.displayName)
    }

    @Test("Two distinct saves at one revision retain one winner and one causal client operation")
    func competingSavesRejectOneStaleRevisionWithoutPartialRows() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let initial = try await actor.saveDraft(ClientDocumentPersistenceFixtures.draft(), operationID: UUID())
        let first = try initial.revising(
            profile: ClientProfile(displayName: initial.fields.profile.displayName, taxIdentifier: "first-edit"),
            snapshot: initial.fields.snapshot
        )
        let second = try initial.revising(
            profile: ClientProfile(displayName: initial.fields.profile.displayName, taxIdentifier: "second-edit"),
            snapshot: initial.fields.snapshot
        )

        async let firstResult = saveDraftOutcome(first, using: actor)
        async let secondResult = saveDraftOutcome(second, using: actor)
        let outcomes = await [firstResult, secondResult]
        let winners = outcomes.compactMap { outcome -> ClientDocumentDraft? in
            guard case let .success(saved) = outcome else { return nil }
            return saved
        }
        let failures = outcomes.compactMap { outcome -> ClientDocumentPersistenceError? in
            guard case let .failure(error) = outcome else { return nil }
            return error as? ClientDocumentPersistenceError
        }
        try #require(winners.count == 1)
        let winner = try #require(winners.first)
        #expect(failures == [.staleDraft])
        #expect(winner.fields.revision == initial.fields.revision + 1)
        #expect(try await actor.draft(id: initial.id) == winner)
        let rows = try persistedRows(in: container)
        #expect(rows.clients.count == 1)
        #expect(rows.clients.first?.taxIdentifier == winner.fields.profile.taxIdentifier)
        #expect(rows.drafts.count == 1)
        #expect(rows.upserts.count == 2)
        let winnerOperation = try #require(rows.upserts.first { $0.payload.taxIdentifier != nil })
        #expect(winnerOperation.payload.taxIdentifier == winner.fields.profile.taxIdentifier)
        let originalOperation = try #require(rows.upserts.first { $0.payload.taxIdentifier == nil })
        #expect(winnerOperation.predecessorOperationID == originalOperation.operationID)
    }

    @Test("A cleared draft recovered from disk accepts a new document identity without reusing old ink")
    func recoveredClearedDraftAcceptsFreshDocumentIdentity() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "draft-identity.store")
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let cleared = try await saveClearedDraft(original, at: url)
        let container = try ClientDocumentPersistenceFixtures.container(at: url)
        let actor = ClientDocumentPersistenceActor(modelContainer: container)
        let recovered = try #require(try await actor.draft(id: cleared.id))
        let previousSnapshot = try #require(original.fields.snapshot)
        let freshID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000089"))
        let replacement = try replacementDraft(recovered, previousSnapshot: previousSnapshot, id: freshID)

        let saved = try await actor.saveDraft(replacement, operationID: UUID())

        #expect(saved.fields.snapshot == replacement.fields.snapshot)
        #expect(saved.fields.binding == nil)
        #expect(saved.fields.signedAt == nil)
        #expect(try await actor.draft(id: saved.id) == saved)
        let rows = try persistedRows(in: container)
        #expect(rows.clients.count == 1)
        #expect(rows.clients.first?.displayName == "Nueva presentación sintética")
        #expect(rows.drafts.count == 1)
        #expect(rows.upserts.count == 2)
        #expect(rows.upserts.filter { $0.payload.displayName == "Nueva presentación sintética" }.count == 1)
    }
}

@MainActor
private func saveClearedDraft(_ original: ClientDocumentDraft, at url: URL) async throws -> ClientDocumentDraft {
    let container = try ClientDocumentPersistenceFixtures.container(at: url)
    let actor = ClientDocumentPersistenceActor(modelContainer: container)
    let saved = try await actor.saveDraft(original, operationID: UUID())
    let cleared = try saved.revising(profile: saved.fields.profile, snapshot: nil)
    return try await actor.saveDraft(cleared, operationID: UUID())
}

private func replacementDraft(
    _ current: ClientDocumentDraft,
    previousSnapshot: ClientDocumentSnapshot,
    id: UUID
) throws -> ClientDocumentDraft {
    let fields = previousSnapshot.fields
    let profile = try ClientProfile(displayName: "Nueva presentación sintética")
    let snapshot = try ClientDocumentSnapshot(.init(
        id: id,
        clientID: fields.clientID,
        clientName: profile.displayName,
        context: fields.context,
        content: fields.content
    ))
    return try ClientDocumentDraft(.init(
        id: current.id,
        clientID: current.fields.clientID,
        profile: profile,
        snapshot: snapshot,
        binding: nil,
        signedAt: nil,
        revision: current.fields.revision
    ))
}

private struct DraftIdentityPersistedRows: Equatable {
    let clients: [Client]
    let drafts: [Data]
    let upserts: [DraftIdentityStoredUpsert]
}

private struct DraftIdentityStoredUpsert: Equatable {
    let operationID: UUID
    let predecessorOperationID: UUID?
    let baseVersion: Int?
    let baseData: Data?
    let payloadVersion: Int
    let payloadData: Data
    let payload: ClientDTO
}

private func persistedRows(in container: ModelContainer) throws -> DraftIdentityPersistedRows {
    let context = ModelContext(container)
    let clients = try context.fetch(FetchDescriptor<ClientModel>())
    let drafts = try context.fetch(FetchDescriptor<ClientDocumentDraftModel>())
    let upserts = try context.fetch(FetchDescriptor<ClientPendingUpsertModel>())
    try #require(clients.count == 1)
    try #require(drafts.count == 1)
    try #require(!upserts.isEmpty)
    return try DraftIdentityPersistedRows(
        clients: clients.map { try $0.toDomain() },
        drafts: drafts.map(\.payload),
        upserts: upserts.sorted { $0.operationID.uuidString < $1.operationID.uuidString }.map { row in
            DraftIdentityStoredUpsert(
                operationID: row.operationID,
                predecessorOperationID: row.predecessorOperationID,
                baseVersion: row.baseVersion,
                baseData: row.baseData,
                payloadVersion: row.payloadVersion,
                payloadData: row.payloadData,
                payload: try row.decodePayload()
            )
        }
    )
}

private func saveDraftOutcome(
    _ draft: ClientDocumentDraft,
    using actor: ClientDocumentPersistenceActor
) async -> Result<ClientDocumentDraft, any Error> {
    do {
        let saved = try await actor.saveDraft(draft, operationID: UUID())
        return .success(saved)
    } catch {
        return .failure(error)
    }
}
