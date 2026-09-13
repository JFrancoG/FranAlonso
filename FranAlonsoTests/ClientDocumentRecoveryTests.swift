import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Authorized recoverable document delivery")
@MainActor
struct ClientDocumentRecoveryTests {
    @Test
    func `reopening recovers signing time and reuses the accepted PDF without rendering again`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("recovery.store")
        let original = try await ClientDocumentPersistenceFixtures.draft()
        try await ClientDocumentRecoveryFixtures.save(original, at: url)
        let renderer = RecoveryRenderer()
        let accepted = try await ClientDocumentRecoveryFixtures.render(
            draftID: original.id,
            at: url,
            renderer: renderer
        )
        #expect(accepted.document.fields.pdf == ClientDocumentPersistenceFixtures.bytes)
        #expect(await renderer.dates == [ClientDocumentTestFixtures.date])
        let binding = try #require(original.fields.binding)
        #expect(await renderer.bindings == [binding])

        let repository = try ClientDocumentRecoveryFixtures.repository(at: url)
        let refusingRenderer = RecoveryRenderer(fails: true)
        let recovered = try await RenderAndPersistConsentUseCase(repository: repository, renderer: refusingRenderer)(
            draftID: original.id
        )
        #expect(recovered == accepted)
        #expect(await refusingRenderer.dates.isEmpty)
    }

    @Test
    func `recreated repositories discover recoverable work using only the client identity`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("discovery.store")
        let original = try await ClientDocumentPersistenceFixtures.draft()
        try await ClientDocumentRecoveryFixtures.save(original, at: url)
        let accepted = try await ClientDocumentRecoveryFixtures.render(
            draftID: original.id,
            at: url,
            renderer: RecoveryRenderer()
        )
        let repository = try ClientDocumentRecoveryFixtures.repository(at: url)

        let drafts = try await repository.drafts(clientID: original.fields.clientID)
        let deliveries = try await repository.deliveries(clientID: original.fields.clientID)
        #expect(drafts.map(\.id) == [original.id])
        #expect(drafts.first?.fields.binding == original.fields.binding)
        #expect(deliveries == [accepted])
        let otherID = ClientID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!)
        #expect(try await repository.drafts(clientID: otherID).isEmpty)
        #expect(try await repository.deliveries(clientID: otherID).isEmpty)
    }

    @Test(arguments: [
        (InMemoryClientDocumentStorage.Failure.unavailable, ClientDocumentStorageError.unavailable),
        (.permissionDenied, .permissionDenied)
    ])
    func `offline and denied uploads retain bytes for explicit retry without activating the client`(
        failure: InMemoryClientDocumentStorage.Failure,
        expected: ClientDocumentStorageError
    ) async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let repository = ClientDocumentRecoveryFixtures.repository(container: container)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [failure])
        let upload = ClientDocumentRecoveryFixtures.upload(repository, storage: storage)

        await #expect(throws: expected) {
            try await upload(documentID: accepted.id)
        }
        let failed = try #require(try await repository.delivery(id: accepted.id))
        #expect(failed.state == .failed(expected))
        #expect(failed.attemptCount == 1)
        #expect(failed.lastAttemptAt == ClientDocumentTestFixtures.date)
        #expect(failed.document == accepted.document)
        #expect(await remote.documentCount == 0)

        let receipt = try await upload(documentID: accepted.id)
        let completed = try #require(try await repository.delivery(id: accepted.id))
        #expect(completed.state == .uploaded(receipt))
        #expect(completed.attemptCount == 2)
        let client = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(client.status == .draft)
        #expect(await remote.document(documentID: accepted.id, principalID: "principal-A") == accepted.document)
    }

    @Test
    func `response loss followed by reopening recovers one remote receipt and retains exact bytes`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("lost-response.store")
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let accepted = try await ClientDocumentRecoveryFixtures.loseUploadResponse(at: url, remote: remote)
        let remoteReceipt = try #require(await remote.receipt(documentID: accepted.id, principalID: "principal-A"))
        let repository = try ClientDocumentRecoveryFixtures.repository(at: url)
        let receipt = try await ClientDocumentRecoveryFixtures.upload(
            repository,
            storage: InMemoryClientDocumentStorage(remote: remote)
        )(documentID: accepted.id)

        #expect(receipt == remoteReceipt)
        #expect(try await repository.delivery(id: accepted.id)?.document == accepted.document)
        #expect(try await repository.delivery(id: accepted.id)?.state == .uploaded(remoteReceipt))
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `a failed receipt save leaves pending work that safely retries after repository recreation`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let persistence = ClientDocumentPersistenceActor(modelContainer: container) { context in
            let documents = try context.fetch(FetchDescriptor<ClientSignedDocumentModel>())
            for document in documents {
                if case .uploaded = try document.toDomain().state {
                    throw ClientDocumentPersistenceError.persistenceUnavailable
                }
            }
            try context.save()
        }
        let repository = ClientDocumentRecoveryFixtures.repository(persistence: persistence)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote)

        await #expect(throws: ClientDocumentPersistenceError.persistenceUnavailable) {
            try await ClientDocumentRecoveryFixtures.upload(repository, storage: storage)(documentID: accepted.id)
        }
        #expect(try await repository.delivery(id: accepted.id)?.state == .pending)
        let remoteReceipt = try #require(await remote.receipt(documentID: accepted.id, principalID: "principal-A"))
        let recreated = ClientDocumentRecoveryFixtures.repository(container: container)
        let recovered = try await ClientDocumentRecoveryFixtures.upload(recreated, storage: storage)(
            documentID: accepted.id
        )
        #expect(recovered == remoteReceipt)
        #expect(try await recreated.delivery(id: accepted.id)?.state == .uploaded(remoteReceipt))
        #expect(await remote.documentCount == 1)
    }

    @Test(arguments: [RecoveryReceiptSubstitution.wrongDocument, .wrongPrincipal])
    func `a mismatched remote acknowledgement never becomes a completed local upload`(
        substitution: RecoveryReceiptSubstitution
    ) async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let storage = SubstitutingRecoveryStorage(base: InMemoryClientDocumentStorage(), substitution: substitution)

        await #expect(throws: ClientDocumentStorageError.invalidReceipt) {
            try await ClientDocumentRecoveryFixtures.upload(repository, storage: storage)(documentID: accepted.id)
        }
        #expect(try await repository.delivery(id: accepted.id)?.state == .failed(.invalidReceipt))
        #expect(try await repository.delivery(id: accepted.id)?.document == accepted.document)
    }

    @Test
    func `a remote conflict stops retries and preserves the accepted local document`() async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let original = accepted.document.fields
        let remoteDocument = try ClientSignedDocument(.init(
            binding: original.binding,
            signedAt: original.signedAt,
            pdf: Data("%PDF-1.7\nCompeting synthetic remote artifact\n%%EOF\n".utf8)
        ))
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote)
        _ = try await storage.upload(remoteDocument, principalID: "principal-A")
        let upload = ClientDocumentRecoveryFixtures.upload(repository, storage: storage)

        await #expect(throws: ClientDocumentStorageError.conflict) {
            try await upload(documentID: accepted.id)
        }
        await #expect(throws: ClientDocumentStorageError.conflict) {
            try await upload(documentID: accepted.id)
        }
        let local = try #require(try await repository.delivery(id: accepted.id))
        #expect(local.state == .conflict(receipt: nil))
        #expect(local.attemptCount == 1)
        #expect(local.document == accepted.document)
        #expect(await remote.document(documentID: accepted.id, principalID: "principal-A") == remoteDocument)
    }

    @Test
    func `stale failures cannot replace a newer attempt or a durable receipt`() async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let first = try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        let second = try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        try await repository.recordUploadFailure(id: accepted.id, attempt: first.attemptCount, error: .permissionDenied)
        #expect(try await repository.delivery(id: accepted.id)?.state == .pending)
        #expect(try await repository.delivery(id: accepted.id)?.attemptCount == 2)
        let receipt = try await InMemoryClientDocumentStorage().upload(accepted.document, principalID: "principal-A")
        _ = try await repository.completeUpload(id: accepted.id, receipt: receipt, principalID: "principal-A")
        try await repository.recordUploadFailure(id: accepted.id, attempt: second.attemptCount, error: .conflict)

        #expect(try await repository.delivery(id: accepted.id)?.state == .uploaded(receipt))
    }

    @Test(arguments: [RecoveryLatestAttempt.pending, .unavailable])
    func `an older conflict stops newer unconfirmed attempts without replacing the document`(
        latestAttempt: RecoveryLatestAttempt
    ) async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let first = try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        let second = try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        try await ClientDocumentRecoveryFixtures.apply(latestAttempt, to: second, repository: repository)

        try await repository.recordUploadFailure(id: accepted.id, attempt: first.attemptCount, error: .conflict)

        let retained = try #require(try await repository.delivery(id: accepted.id))
        #expect(retained.state == .conflict(receipt: nil))
        #expect(retained.attemptCount == 2)
        #expect(retained.document == accepted.document)
        #expect(retained.document.fields.pdf == ClientDocumentPersistenceFixtures.bytes)
        await #expect(throws: ClientDocumentStorageError.conflict) {
            try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        }
        #expect(try await repository.delivery(id: accepted.id) == retained)
    }

    @Test
    func `logout while remote acceptance is suspended denies completion and retains retryable work`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let authority = RecoveryAuthorization()
        let repository = ClientDocumentRecoveryFixtures.repository(container: container, authority: authority)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage(remote: remote)) {
            await authority.revoke()
        }

        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await ClientDocumentRecoveryFixtures.upload(repository, storage: storage)(documentID: accepted.id)
        }
        let inspecting = ClientDocumentPersistenceActor(modelContainer: container)
        #expect(try await inspecting.delivery(id: accepted.id)?.state == .pending)
        #expect(await remote.documentCount == 1)
        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await repository.delivery(id: accepted.id)
        }
    }

    @Test
    func `task cancellation after remote acceptance cannot report a completed receipt`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let repository = ClientDocumentRecoveryFixtures.repository(container: container)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let gate = RecoveryOperationGate()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage(remote: remote)) {
            await gate.enter()
        }
        let upload = ClientDocumentRecoveryFixtures.upload(repository, storage: storage)
        let task = Task {
            do {
                let receipt = try await upload(documentID: accepted.id)
                await gate.finish()
                return receipt
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = try await task.value
            Issue.record("Upload completed without reaching the remote acceptance gate")
            return
        }
        task.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) { try await task.value }

        #expect(try await repository.delivery(id: accepted.id)?.state == .pending)
        let remoteReceipt = try #require(await remote.receipt(documentID: accepted.id, principalID: "principal-A"))
        let recovered = try await ClientDocumentRecoveryFixtures.upload(
            repository,
            storage: InMemoryClientDocumentStorage(remote: remote)
        )(documentID: accepted.id)
        #expect(recovered == remoteReceipt)
    }

    @Test(arguments: [LocalPrincipalAuthorizationError.differentPrincipal, .secureStorageUnavailable])
    func `principal binding errors deny repository reads and writes without changing data`(
        error: LocalPrincipalAuthorizationError
    ) async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let authority = RecoveryAuthorization()
        let repository = ClientDocumentRecoveryFixtures.repository(container: container, authority: authority)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(repository)
        await authority.failAuthorization(with: error)

        await #expect(throws: error) { try await repository.delivery(id: accepted.id) }
        await #expect(throws: error) {
            try await repository.beginUpload(id: accepted.id, at: ClientDocumentTestFixtures.date)
        }
        let retained = try await ClientDocumentPersistenceActor(modelContainer: container).delivery(id: accepted.id)
        #expect(retained?.attemptCount == 0)
        #expect(retained?.document == accepted.document)
    }

    @Test
    func `rendering from an older draft revision cannot accept its result`() async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let saved = try await repository.saveDraft(ClientDocumentPersistenceFixtures.draft(), operationID: UUID())
        let gate = RecoveryOperationGate()
        let renderer = GatedRecoveryRenderer(gate: gate)
        let task = Task {
            do {
                let delivery = try await RenderAndPersistConsentUseCase(repository: repository, renderer: renderer)(
                    draftID: saved.id
                )
                await gate.finish()
                return delivery
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = try await task.value
            Issue.record("Rendering completed without reaching its suspension gate")
            return
        }
        let revised = try saved.revising(
            profile: ClientProfile(displayName: saved.fields.profile.displayName, taxIdentifier: "updated-tax"),
            snapshot: saved.fields.snapshot
        )
        let latest = try await repository.saveDraft(revised, operationID: UUID())
        await gate.release()
        await #expect(throws: ClientDocumentPersistenceError.staleDraft) { try await task.value }
        #expect(try await repository.draft(id: saved.id) == latest)
        #expect(try await repository.delivery(id: ClientDocumentTestFixtures.documentID) == nil)
    }

    @Test
    func `later authorization upload leaves the active client and initial reference untouched`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let initialReference = try ClientConsentReference(rawValue: "existing-initial-information")
        let client = Client(
            id: ClientDocumentTestFixtures.clientID,
            displayName: "Cliente sintético Álvarez",
            taxIdentifier: nil,
            billingAddress: nil,
            status: .active(consentReference: initialReference)
        )
        let context = ModelContext(container)
        context.insert(ClientModel(client))
        try context.save()
        let repository = ClientDocumentRecoveryFixtures.repository(container: container)
        let snapshot = try await ClientDocumentTestFixtures.snapshot(
            decision: .authorized,
            purpose: .subsequentPhotoAuthorization
        )
        let draft = try ClientDocumentDraft(.init(
            id: ClientDocumentPersistenceFixtures.draftID,
            clientID: snapshot.fields.clientID,
            profile: ClientProfile(displayName: snapshot.fields.clientName),
            snapshot: snapshot,
            binding: ClientDocumentTestFixtures.binding(snapshot),
            signedAt: ClientDocumentTestFixtures.date,
            revision: 0
        ))
        let saved = try await repository.saveDraft(draft, operationID: UUID())
        let accepted = try await repository.accept(
            ClientDocumentPersistenceFixtures.document(saved),
            draftID: saved.id,
            revision: saved.fields.revision
        )
        _ = try await ClientDocumentRecoveryFixtures.upload(repository, storage: InMemoryClientDocumentStorage())(
            documentID: accepted.id
        )
        let retained = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(retained.status == .active(consentReference: initialReference))
    }

    @Test
    func `client change observers are signalled only after a successful durable draft save`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let signal = RecoveryChangeSignal()
        let failing = ClientDocumentPersistenceActor(modelContainer: container) { _ in
            throw ClientDocumentPersistenceError.persistenceUnavailable
        }
        let repository = ClientDocumentRecoveryFixtures.repository(persistence: failing, signal: signal)
        let original = try await ClientDocumentPersistenceFixtures.draft()
        await #expect(throws: ClientDocumentPersistenceError.persistenceUnavailable) {
            try await repository.saveDraft(original, operationID: UUID())
        }
        #expect(await signal.count == 0)
        let recovered = ClientDocumentRecoveryFixtures.repository(
            persistence: ClientDocumentPersistenceActor(modelContainer: container),
            signal: signal
        )
        _ = try await recovered.saveDraft(original, operationID: UUID())
        #expect(await signal.count == 1)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)
    }

    @Test
    func `reopened uploaded documents return cached receipts without another attempt or network`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("completed.store")
        let receipt = try await ClientDocumentRecoveryFixtures.uploaded(at: url, conflictAfterward: false)
        let repository = try ClientDocumentRecoveryFixtures.repository(at: url)
        let forbiddenStorage = RefusingRecoveryStorage()
        let recovered = try await ClientDocumentRecoveryFixtures.upload(repository, storage: forbiddenStorage)(
            documentID: ClientDocumentTestFixtures.documentID
        )

        #expect(recovered == receipt)
        #expect(await forbiddenStorage.calls == 0)
        let delivery = try #require(try await repository.delivery(id: ClientDocumentTestFixtures.documentID))
        #expect(delivery.attemptCount == 1)
        #expect(delivery.state == .uploaded(receipt))
    }

    @Test
    func `a payload conflict after upload retains the original bytes and receipt across reopening`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("completed-conflict.store")
        let receipt = try await ClientDocumentRecoveryFixtures.uploaded(at: url, conflictAfterward: true)
        let repository = try ClientDocumentRecoveryFixtures.repository(at: url)
        let delivery = try #require(try await repository.delivery(id: ClientDocumentTestFixtures.documentID))

        #expect(delivery.document.fields.pdf == ClientDocumentPersistenceFixtures.bytes)
        #expect(delivery.state == .conflict(receipt: receipt))
        let forbiddenStorage = RefusingRecoveryStorage()
        await #expect(throws: ClientDocumentStorageError.conflict) {
            try await ClientDocumentRecoveryFixtures.upload(repository, storage: forbiddenStorage)(
                documentID: ClientDocumentTestFixtures.documentID
            )
        }
        #expect(await forbiddenStorage.calls == 0)
        #expect(try await repository.delivery(id: ClientDocumentTestFixtures.documentID) == delivery)
    }

    @Test
    func `a second draft cannot reuse an artifact belonging to the first draft`() async throws {
        let repository = ClientDocumentRecoveryFixtures.repository(
            container: try ClientDocumentPersistenceFixtures.container()
        )
        let original = try await ClientDocumentPersistenceFixtures.draft()
        let other = try ClientDocumentDraft(.init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000087")!,
            clientID: original.fields.clientID,
            profile: original.fields.profile,
            snapshot: original.fields.snapshot,
            binding: original.fields.binding,
            signedAt: original.fields.signedAt,
            revision: 0
        ))
        let saved = try await repository.saveDraft(original, operationID: UUID())
        let otherSaved = try await repository.saveDraft(other, operationID: UUID())
        let accepted = try await repository.accept(
            ClientDocumentPersistenceFixtures.document(saved),
            draftID: saved.id,
            revision: saved.fields.revision
        )
        let renderer = RecoveryRenderer(fails: true)

        await #expect(throws: ClientDocumentPersistenceError.documentConflict) {
            try await RenderAndPersistConsentUseCase(repository: repository, renderer: renderer)(draftID: otherSaved.id)
        }
        #expect(await renderer.dates.isEmpty)
        #expect(try await repository.delivery(id: accepted.id)?.document == accepted.document)
    }
}
