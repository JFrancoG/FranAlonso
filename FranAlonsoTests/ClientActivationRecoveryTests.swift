import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct ClientActivationRecoveryTests {
    @Test
    func `reopening after upload activates from the durable receipt without network`() async throws {
        let directory = try ClientDocumentPersistenceFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("activation.store")
        let receipt = try await ClientActivationFixtures.uploaded(at: url)
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container(at: url))
        let storage = RefusingRecoveryStorage()
        #expect(try fixtures.client().status == .consentPendingUpload)

        let result = try await fixtures.useCase(storage: storage)(
            clientID: ClientDocumentTestFixtures.clientID,
            documentID: ClientDocumentTestFixtures.documentID
        )

        #expect(result.status == .active(consentReference: receipt.reference))
        #expect(try fixtures.client() == result)
        #expect(await storage.calls == 0)
        #expect(try ModelContext(fixtures.container).fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 1)
        #expect(try fixtures.pending().count == 3)
    }

    @Test
    func `activation save failure retains the receipt and rolls back profile and causal work`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let persistence = ClientDocumentPersistenceActor(modelContainer: container) { context in
            for model in try context.fetch(FetchDescriptor<ClientModel>()) {
                if case .active = try model.toDomain().status {
                    throw ClientDocumentPersistenceError.persistenceUnavailable
                }
            }
            try context.save()
        }
        let fixtures = ClientActivationFixtures(container: container, persistence: persistence)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let remote = InMemoryClientDocumentStorage.RemoteStore()

        await #expect(throws: ClientDocumentPersistenceError.persistenceUnavailable) {
            try await fixtures.useCase(storage: InMemoryClientDocumentStorage(remote: remote))(
                clientID: ClientDocumentTestFixtures.clientID,
                documentID: accepted.id
            )
        }

        let receipt = try #require(await remote.receipt(documentID: accepted.id, principalID: "principal-A"))
        #expect(try fixtures.client().status == .consentPendingUpload)
        #expect(try fixtures.pending().count == 2)
        #expect(try await fixtures.documents.delivery(id: accepted.id)?.state == .uploaded(receipt))
        let pending = try await fixtures.activation.prepareActivation(
            clientID: ClientDocumentTestFixtures.clientID,
            documentID: accepted.id,
            operationID: UUID()
        )
        #expect(pending.status == .consentPendingUpload)
        let recovered = ClientActivationFixtures(container: container)
        let storage = RefusingRecoveryStorage()
        let result = try await recovered.useCase(storage: storage)(clientID: pending.id, documentID: accepted.id)

        #expect(result.status == .active(consentReference: receipt.reference))
        #expect(try recovered.client() == result)
        #expect(try recovered.pending().count == 3)
        #expect(await storage.calls == 0)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `preparation save failure cannot upload or leave partial pending work`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let original = ClientActivationFixtures(container: container)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(original.documents)
        let before = try original.client()
        let operations = try original.pending()
        let persistence = ClientDocumentPersistenceActor(modelContainer: container) { _ in
            throw ClientDocumentPersistenceError.persistenceUnavailable
        }
        let failing = ClientActivationFixtures(container: container, persistence: persistence)
        let storage = RefusingRecoveryStorage()

        await #expect(throws: ClientDocumentPersistenceError.persistenceUnavailable) {
            try await failing.useCase(storage: storage)(clientID: before.id, documentID: accepted.id)
        }

        #expect(try failing.client() == before)
        #expect(try failing.pending() == operations)
        #expect(await storage.calls == 0)
        #expect(try await failing.documents.delivery(id: accepted.id)?.attemptCount == 0)
    }

    @Test
    func `activation preserves the profile saved from another context while upload is suspended`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let gate = RecoveryOperationGate()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage()) { await gate.enter() }
        let activate = fixtures.useCase(storage: storage)
        let task = Task {
            do {
                let result = try await activate(clientID: ClientDocumentTestFixtures.clientID, documentID: accepted.id)
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = try await task.value
            Issue.record("Activation did not reach the upload suspension gate")
            return
        }
        let edited = try ClientLocalDataSource().updateClient(
            id: ClientDocumentTestFixtures.clientID,
            profile: ClientProfile(displayName: "Edited during upload", taxIdentifier: "updated-tax"),
            operationID: UUID(),
            in: ModelContext(fixtures.container)
        )
        await gate.release()
        let result = try await task.value

        #expect(result.displayName == "Edited during upload")
        #expect(result.taxIdentifier == "updated-tax")
        #expect(try fixtures.client() == result)
        #expect(edited.status == .consentPendingUpload)
        #expect(try fixtures.pending().count == 4)
        #expect(try fixtures.pending().last?.client.toDomain() == result)
        #expect(try await fixtures.documents.delivery(id: accepted.id)?.document == accepted.document)
    }

    @Test
    func `revoked authorization prevents activation and keeps the accepted upload recoverable`() async throws {
        let container = try ClientDocumentPersistenceFixtures.container()
        let authority = RecoveryAuthorization()
        let documents = ClientDocumentRecoveryFixtures.repository(container: container, authority: authority)
        let activation = DefaultClientActivationRepository(
            persistence: documents.persistence,
            access: documents.access,
            observationSignal: documents.observationSignal
        )
        let fixtures = ClientActivationFixtures(container: container, documents: documents, activation: activation)
        let accepted = try await ClientDocumentRecoveryFixtures.accept(documents)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage(remote: remote)) {
            await authority.revoke()
        }

        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await fixtures.useCase(storage: storage)(
                clientID: ClientDocumentTestFixtures.clientID,
                documentID: accepted.id
            )
        }

        #expect(try fixtures.client().status == .consentPendingUpload)
        #expect(try fixtures.pending().count == 2)
        #expect(await remote.documentCount == 1)
        let inspecting = ClientDocumentPersistenceActor(modelContainer: container)
        #expect(try await inspecting.delivery(id: accepted.id)?.state == .pending)
        #expect(try await inspecting.delivery(id: accepted.id)?.document == accepted.document)
    }
}
