import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct ClientActivationTests {
    @Test
    func `upload activates exactly once using the retained initial document reference`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let activate = fixtures.useCase(storage: InMemoryClientDocumentStorage(remote: remote))

        let result = try await activate(clientID: ClientDocumentTestFixtures.clientID, documentID: accepted.id)
        let receipt = try #require(await remote.receipt(documentID: accepted.id, principalID: "principal-A"))
        #expect(result.status == .active(consentReference: receipt.reference))
        #expect(try fixtures.client() == result)
        let operations = try fixtures.pending()
        #expect(operations.count == 3)
        #expect(try operations.last?.client.toDomain().status == .active(consentReference: receipt.reference))

        let repeated = try await activate(clientID: result.id, documentID: accepted.id)
        #expect(repeated == result)
        #expect(try fixtures.pending() == operations)
        #expect(await remote.documentCount == 1)
        #expect(try await fixtures.documents.delivery(id: accepted.id)?.attemptCount == 1)
    }

    @Test
    func `unavailable upload leaves pending activation with the same accepted artifact`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let storage = RefusingRecoveryStorage()

        await #expect(throws: ClientDocumentStorageError.unavailable) {
            try await fixtures.useCase(storage: storage)(
                clientID: ClientDocumentTestFixtures.clientID,
                documentID: accepted.id
            )
        }

        #expect(try fixtures.client().status == .consentPendingUpload)
        #expect(try fixtures.pending().count == 2)
        #expect(try await fixtures.documents.delivery(id: accepted.id)?.document == accepted.document)
        #expect(await storage.calls == 1)
    }

    @Test
    func `a document belonging to another client is rejected before upload`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let storage = RefusingRecoveryStorage()
        let original = try fixtures.client()
        let operations = try fixtures.pending()

        await #expect(throws: ClientActivationError.invalidDocument) {
            try await fixtures.useCase(storage: storage)(clientID: ClientID(rawValue: UUID()), documentID: accepted.id)
        }

        #expect(await storage.calls == 0)
        #expect(try fixtures.client() == original)
        #expect(try fixtures.pending() == operations)
    }

    @Test
    func `later photo authorization cannot activate or replace the initial reference`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let reference = try ClientConsentReference(rawValue: "existing-initial-information")
        let original = Client(
            id: ClientDocumentTestFixtures.clientID,
            displayName: "Cliente sintético Álvarez",
            taxIdentifier: nil,
            billingAddress: nil,
            status: .active(consentReference: reference)
        )
        try ClientLocalDataSource().upsert(original, in: ModelContext(fixtures.container))
        let snapshot = try await ClientDocumentTestFixtures.snapshot(
            decision: .authorized,
            purpose: .subsequentPhotoAuthorization
        )
        let draft = try ClientDocumentDraft(.init(
            id: ClientDocumentPersistenceFixtures.draftID,
            clientID: original.id,
            profile: ClientProfile(displayName: original.displayName),
            snapshot: snapshot,
            binding: ClientDocumentTestFixtures.binding(snapshot),
            signedAt: ClientDocumentTestFixtures.date,
            revision: 0
        ))
        let saved = try await fixtures.documents.saveDraft(draft, operationID: UUID())
        let accepted = try await fixtures.documents.accept(
            ClientDocumentPersistenceFixtures.document(saved),
            draftID: saved.id,
            revision: saved.fields.revision
        )
        _ = try await ClientDocumentRecoveryFixtures.upload(
            fixtures.documents,
            storage: InMemoryClientDocumentStorage()
        )(documentID: accepted.id)
        let storage = RefusingRecoveryStorage()

        await #expect(throws: ClientActivationError.invalidDocument) {
            try await fixtures.useCase(storage: storage)(clientID: original.id, documentID: accepted.id)
        }
        await #expect(throws: ClientActivationError.invalidDocument) {
            try await fixtures.activation.activate(clientID: original.id, documentID: accepted.id, operationID: UUID())
        }

        #expect(try fixtures.client() == original)
        #expect(try fixtures.pending().isEmpty)
        #expect(await storage.calls == 0)
    }

    @Test(arguments: [ActivationReceiptScenario.missing, .wrongDocument, .wrongPrincipal])
    func `activation requires a durable receipt correlated with the document and principal`(
        scenario: ActivationReceiptScenario
    ) async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let original = try fixtures.client()
        let operations = try fixtures.pending()
        if scenario != .missing {
            let context = ModelContext(fixtures.container)
            let model = try #require(context.fetch(FetchDescriptor<ClientSignedDocumentModel>()).first)
            try model.setState(.uploaded(ClientDocumentUploadReceipt(
                documentID: scenario == .wrongDocument ? UUID() : accepted.id,
                principalID: scenario == .wrongPrincipal ? "principal-B" : "principal-A",
                reference: ClientConsentReference(rawValue: "synthetic-receipt")
            )))
            try context.save()
        }

        switch scenario {
        case .missing:
            await #expect(throws: ClientActivationError.uploadRequired) {
                try await fixtures.activation.activate(
                    clientID: original.id,
                    documentID: accepted.id,
                    operationID: UUID()
                )
            }
        case .wrongDocument, .wrongPrincipal:
            await #expect(throws: ClientDocumentStorageError.invalidReceipt) {
                try await fixtures.activation.activate(
                    clientID: original.id,
                    documentID: accepted.id,
                    operationID: UUID()
                )
            }
        }

        #expect(try fixtures.client() == original)
        #expect(try fixtures.pending() == operations)
    }

    @Test
    func `an active client never changes its initial reference or returns to pending`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        _ = try await ClientDocumentRecoveryFixtures.upload(
            fixtures.documents,
            storage: InMemoryClientDocumentStorage()
        )(documentID: accepted.id)
        let original = try fixtures.client()
        let active = try Client(
            id: original.id,
            displayName: original.displayName,
            taxIdentifier: original.taxIdentifier,
            billingAddress: original.billingAddress,
            status: .active(consentReference: ClientConsentReference(rawValue: "another-initial-document"))
        )
        try ClientLocalDataSource().persistPendingUpsert(
            active,
            operationID: UUID(),
            in: ModelContext(fixtures.container)
        )
        let operations = try fixtures.pending()
        let storage = RefusingRecoveryStorage()

        await #expect(throws: ClientActivationError.differentInitialDocument) {
            try await fixtures.useCase(storage: storage)(clientID: active.id, documentID: accepted.id)
        }
        await #expect(throws: ClientActivationError.differentInitialDocument) {
            try await fixtures.activation.activate(clientID: active.id, documentID: accepted.id, operationID: UUID())
        }

        #expect(try fixtures.client() == active)
        #expect(try fixtures.pending() == operations)
        #expect(await storage.calls == 0)
    }

    @Test(arguments: [ActivationBlocker.documentConflict, .clientConflict, .deactivated])
    func `persisted conflicts and deactivation reject both activation transitions`(
        blocker: ActivationBlocker
    ) async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let receipt = try await ClientDocumentRecoveryFixtures.upload(
            fixtures.documents,
            storage: InMemoryClientDocumentStorage()
        )(documentID: accepted.id)
        try fixtures.apply(blocker, receipt: receipt)
        let operations = try fixtures.pending()
        let original = try fixtures.client()
        let storage = RefusingRecoveryStorage()

        await #expect {
            try await fixtures.useCase(storage: storage)(clientID: original.id, documentID: accepted.id)
        } throws: { error in
            blocker.matches(error)
        }
        await #expect {
            try await fixtures.activation.activate(clientID: original.id, documentID: accepted.id, operationID: UUID())
        } throws: { error in
            blocker.matches(error)
        }

        #expect(try fixtures.client() == original)
        #expect(try fixtures.pending() == operations)
        #expect(await storage.calls == 0)
    }

    @Test
    func `overlapping activation requests append only one active causal operation`() async throws {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container())
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let activate = fixtures.useCase(storage: InMemoryClientDocumentStorage(remote: remote))

        async let first = activate(clientID: ClientDocumentTestFixtures.clientID, documentID: accepted.id)
        async let second = activate(clientID: ClientDocumentTestFixtures.clientID, documentID: accepted.id)
        let results = try await (first, second)

        #expect(results.0 == results.1)
        #expect(try fixtures.client() == results.0)
        #expect(try fixtures.pending().count == 3)
        #expect(await remote.documentCount == 1)
    }
}
