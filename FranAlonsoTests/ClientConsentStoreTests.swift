import Foundation
import SwiftData
import Synchronization
import Testing
@testable import FranAlonso

@Suite("Recoverable consent review")
@MainActor
struct ClientConsentStoreTests {
    @Test
    func `sending the initial document activates the same client with its durable reference`() async throws {
        let fixture = try ConsentFlowFixture(storage: InMemoryClientDocumentStorage())
        _ = try await fixture.sign()
        await fixture.store.accept()
        let accepted = try #require(fixture.store.delivery?.document)
        await fixture.store.upload()
        let delivery = try #require(fixture.store.delivery)
        guard case .uploaded(let receipt) = delivery.state else {
            Issue.record("Expected a durable receipt before activation")
            return
        }
        let context = ModelContext(fixture.container)
        let clients = try context.fetch(FetchDescriptor<ClientModel>())
        #expect(clients.count == 1)
        #expect(try clients.first?.toDomain().status == .active(consentReference: receipt.reference))
        #expect(delivery.document == accepted)
    }

    @Test
    func `offline activation retains the signed artifact and a nonoperational pending client`() async throws {
        let fixture = try ConsentFlowFixture()
        _ = try await fixture.sign()
        await fixture.store.accept()
        let accepted = try #require(fixture.store.delivery?.document)
        await fixture.store.upload()
        let clients = try ModelContext(fixture.container).fetch(FetchDescriptor<ClientModel>())
        #expect(try clients.first?.toDomain().status == .consentPendingUpload)
        #expect(fixture.store.delivery?.document == accepted)
        #expect(fixture.store.failure == .unavailable)
    }

    @Test
    func `a failed activation stays actionable after reopening without another upload attempt`() async throws {
        let rejectActivation = Mutex(true)
        let fixture = try ConsentFlowFixture(storage: InMemoryClientDocumentStorage(), saveChanges: { context in
            let activating = try context.fetch(FetchDescriptor<ClientModel>()).contains {
                if case .active = try $0.toDomain().status {
                    return true
                }
                return false
            }
            let reject = activating && rejectActivation.withLock { value in
                defer { value = false }
                return value
            }
            if reject {
                throw ClientDocumentPersistenceError.persistenceUnavailable
            }
            try context.save()
        })
        _ = try await fixture.sign()
        await fixture.store.accept()
        await fixture.store.upload()
        #expect(fixture.store.failure == .activation)
        let uploaded = try #require(fixture.store.delivery)
        #expect(uploaded.state.isUploaded)
        let reopened = ClientConsentStore(clientID: fixture.clientID, services: fixture.services)
        await reopened.recover(profile: fixture.profile)
        #expect(reopened.hasUploadAction)
        let activated = try #require(await reopened.upload())
        guard case .active = activated.status else {
            Issue.record("Expected activation retry from the already uploaded document")
            return
        }
        #expect(reopened.delivery == uploaded)
        #expect(reopened.failure == nil)
        #expect(!reopened.hasUploadAction)
    }

    @Test
    func `closing during upload fences the result and leaves activation pending`() async throws {
        let gate = RecoveryOperationGate()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage()) { await gate.enter() }
        let fixture = try ConsentFlowFixture(storage: storage)
        _ = try await fixture.sign()
        await fixture.store.accept()
        let task = Task {
            await fixture.store.upload()
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        fixture.store.close()
        task.cancel()
        await gate.release()
        await task.value
        #expect(entered)
        #expect(fixture.store.phase == .closed)
        #expect(!fixture.store.isActivated)
        #expect(fixture.store.delivery == nil)
        let clients = try ModelContext(fixture.container).fetch(FetchDescriptor<ClientModel>())
        #expect(try clients.first?.toDomain().status == .consentPendingUpload)
    }

    @Test
    func failedSignatureSaveKeepsInkForRetryWithoutAnotherCapture() async throws {
        let saves = Mutex(0)
        let fixture = try ConsentFlowFixture(saveChanges: { context in
            let attempt = saves.withLock { value in
                value += 1
                return value
            }
            if attempt == 2 {
                throw ClientDocumentPersistenceError.persistenceUnavailable
            }
            try context.save()
        })
        let signed = try await fixture.sign()
        #expect(fixture.store.failure == .persistence)
        #expect(fixture.store.signature == signed.fields.binding?.signature)
        #expect(try await fixture.services.repository.draft(id: signed.id)?.fields.binding == nil)
        await fixture.store.accept()
        #expect(fixture.store.failure == nil)
        #expect(fixture.store.delivery?.document.fields.binding == signed.fields.binding)
        #expect(fixture.store.delivery?.document.fields.signedAt == ClientDocumentTestFixtures.date)
    }

    @Test
    func failedRenderCanRetryTheSameSignedPresentation() async throws {
        let renderer = RetryingConsentRenderer()
        let fixture = try ConsentFlowFixture(renderer: renderer)
        let signed = try await fixture.sign()
        await fixture.store.accept()
        #expect(fixture.store.failure == .rendering)
        #expect(fixture.store.signature == signed.fields.binding?.signature)
        #expect(fixture.store.delivery == nil)
        await fixture.store.accept()
        #expect(fixture.store.failure == nil)
        #expect(fixture.store.delivery?.document.fields.binding == signed.fields.binding)
        #expect(fixture.store.delivery?.document.fields.signedAt == signed.fields.signedAt)
    }

    @Test
    func overlappingAcceptanceRetainsOneDocumentWithoutASecondRender() async throws {
        let gate = RecoveryOperationGate()
        let fixture = try ConsentFlowFixture(renderer: GatedRecoveryRenderer(gate: gate))
        let signed = try await fixture.sign()
        let first = Task {
            await fixture.store.accept()
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        await fixture.store.accept()
        await gate.release()
        await first.value
        #expect(entered)
        #expect(fixture.store.delivery?.document.fields.binding == signed.fields.binding)
        #expect(try await fixture.services.repository.deliveries(clientID: fixture.clientID).count == 1)
    }

    @Test
    func informationIsReadableWithoutCreatingAClient() async throws {
        let fixture = try ConsentFlowFixture()
        await fixture.store.showInformation()
        #expect(fixture.store.phase == .information)
        let content = try #require(fixture.store.content)
        #expect(content.fields.photoAuthorization == nil)
        #expect(!content.fields.sections.isEmpty)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientModel>()) == 0)
    }

    @Test
    func reviewWritesOneClientAndDraftWithoutActivation() async throws {
        let fixture = try ConsentFlowFixture()
        await fixture.store.review(profile: fixture.profile)
        #expect(fixture.store.phase == .review)
        let draft = try #require(fixture.store.draft)
        let stored = try await fixture.services.repository.draft(id: draft.id)
        #expect(stored?.fields.profile.displayName == "Cliente de prueba")
        #expect(stored?.fields.snapshot?.fields.clientName == "Cliente de prueba")
        let clients = try fixture.container.mainContext.fetch(FetchDescriptor<ClientModel>())
        #expect(try clients.first?.toDomain().status == .draft)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 1)
    }

    @Test
    func readingAgainKeepsSignedIdentityAndDate() async throws {
        let fixture = try ConsentFlowFixture()
        let signed = try await fixture.sign()
        await fixture.store.showInformation()
        await fixture.store.review(profile: fixture.profile)
        #expect(fixture.store.snapshot == signed.fields.snapshot)
        #expect(fixture.store.draft?.fields.binding == signed.fields.binding)
        #expect(fixture.store.draft?.fields.signedAt == ClientDocumentTestFixtures.date)
    }

    @Test
    func nameChangeInvalidatesInkWhileUnpresentedFieldsDoNot() async throws {
        let fixture = try ConsentFlowFixture()
        let signed = try await fixture.sign()
        let taxChange = try ClientProfile(displayName: fixture.profile.displayName, taxIdentifier: "NEW-TAX")
        #expect(await fixture.store.saveProfile(taxChange))
        #expect(fixture.store.draft?.fields.binding == signed.fields.binding)
        await fixture.store.review(profile: try ClientProfile(displayName: "Nombre corregido"))
        #expect(fixture.store.snapshot?.id != signed.fields.snapshot?.id)
        #expect(fixture.store.signature == nil)
        #expect(fixture.store.draft?.fields.signedAt == nil)
        #expect(fixture.store.phase == .review)
    }

    @Test(arguments: [ClientDocumentPhotoDecision.authorized, .declined, .notSelected])
    func photoRequiresAnExplicitDecision(_ decision: ClientDocumentPhotoDecision) async throws {
        let fixture = try ConsentFlowFixture()
        await fixture.store.review(
            profile: fixture.profile,
            context: .init(purpose: .initialInformation, photoDecision: .undecided)
        )
        #expect(!fixture.store.canCapture)
        #expect(fixture.store.snapshot?.fields.content.fields.photoAuthorization != nil)
        await fixture.store.choosePhoto(decision)
        #expect(fixture.store.canCapture)
        #expect(fixture.store.snapshot?.fields.context.photoDecision == decision)
        #expect((fixture.store.content?.fields.photoAuthorization != nil) == (decision == .authorized))
        #expect(fixture.store.signature == nil)
    }

    @Test
    func cancelCaptureAndLateCompletionNeverPersistInk() async throws {
        let fixture = try ConsentFlowFixture()
        await fixture.store.review(profile: fixture.profile)
        let id = try #require(fixture.store.startCapture())
        await fixture.store.completeCapture(.cancelled, id: id)
        await fixture.store.completeCapture(.captured(try ConsentFlowFixture.ink()), id: id)
        #expect(fixture.store.phase == .review)
        #expect(fixture.store.signature == nil)
        let draft = try #require(fixture.store.draft)
        #expect(try await fixture.services.repository.draft(id: draft.id)?.fields.binding == nil)
    }

    @Test
    func restartAfterSigningRetainsInkAndCanRenderWithoutSigningAgain() async throws {
        let fixture = try ConsentFlowFixture()
        let signed = try await fixture.sign()
        fixture.store.close()
        #expect(fixture.store.snapshot == nil)
        let reopened = ClientConsentStore(clientID: fixture.clientID, services: fixture.services)
        await reopened.recover(profile: fixture.profile)
        #expect(reopened.phase == .signatureReview)
        #expect(reopened.draft?.id == signed.id)
        #expect(reopened.draft?.fields.signedAt == signed.fields.signedAt)
        await reopened.accept()
        let delivery = try #require(reopened.delivery)
        #expect(delivery.document.fields.pdf == ConsentFlowRenderer.bytes)
        #expect(delivery.document.fields.binding == signed.fields.binding)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 1)
    }

    @Test
    func acceptedWorkIsRecoveredAsImmutableAndNeverOverwritten() async throws {
        let fixture = try ConsentFlowFixture()
        _ = try await fixture.sign()
        await fixture.store.accept()
        let accepted = try #require(fixture.store.delivery)
        let reopened = ClientConsentStore(clientID: fixture.clientID, services: fixture.services)
        await reopened.recover(profile: fixture.profile)
        #expect(reopened.phase == .retained)
        #expect(reopened.delivery == accepted)
        #expect(!reopened.canCapture)
        #expect(!reopened.canAccept)
        await reopened.discard()
        #expect(try await fixture.services.repository.delivery(id: accepted.id) == accepted)
    }

    @Test
    func multipleDraftsRequireSelectionInsteadOfUUIDOrdering() async throws {
        let fixture = try ConsentFlowFixture()
        await fixture.store.review(profile: fixture.profile)
        let first = try #require(fixture.store.draft)
        let otherStore = ClientConsentStore(clientID: fixture.clientID, services: fixture.services)
        let otherDraft = try ClientDocumentDraft(.init(
            id: UUID(),
            clientID: fixture.clientID,
            profile: fixture.profile,
            snapshot: nil,
            binding: nil,
            signedAt: nil,
            revision: 0
        ))
        let second = try await fixture.services.repository.saveDraft(otherDraft, operationID: UUID())
        await otherStore.recover(profile: fixture.profile)
        #expect(otherStore.phase == .choosing)
        #expect(otherStore.draft == nil)
        #expect(Set(otherStore.pendingDrafts.map(\.id)) == [first.id, second.id])
        otherStore.dismiss()
        await otherStore.review(profile: fixture.profile)
        #expect(otherStore.phase == .choosing)
        #expect(try await fixture.services.repository.drafts(clientID: fixture.clientID).count == 2)
        otherStore.selectDraft(id: second.id, profile: fixture.profile)
        #expect(otherStore.draft?.id == second.id)
    }

    @Test
    func profileMismatchRequiresAChoiceBeforeWriting() async throws {
        let fixture = try ConsentFlowFixture()
        let signed = try await fixture.sign()
        let current = try ClientProfile(displayName: "Ficha más reciente")
        let reopened = ClientConsentStore(clientID: fixture.clientID, services: fixture.services)
        await reopened.recover(profile: current)
        #expect(reopened.phase == .profileConflict)
        #expect(!reopened.canAccept)
        reopened.dismiss()
        await reopened.review(profile: current)
        #expect(reopened.phase == .profileConflict)
        #expect(reopened.draft?.fields.binding == signed.fields.binding)
        await reopened.showInformation()
        reopened.dismiss()
        await reopened.review(profile: current)
        #expect(reopened.phase == .profileConflict)
        let selected = await reopened.resolveProfile(useDraft: false, current: current)
        #expect(selected == current)
        #expect(reopened.signature == nil)
        #expect(reopened.snapshot?.id != signed.fields.snapshot?.id)
        #expect(reopened.snapshot?.fields.clientName == current.displayName)
    }

    @Test
    func offlineUploadKeepsExactArtifactAndRetryReusesReceipt() async throws {
        let storage = InMemoryClientDocumentStorage()
        let fixture = try ConsentFlowFixture(storage: storage)
        _ = try await fixture.sign()
        await fixture.store.accept()
        let accepted = try #require(fixture.store.delivery)
        await fixture.store.upload()
        let uploaded = try #require(fixture.store.delivery)
        guard case .uploaded(let receipt) = uploaded.state else {
            Issue.record("Expected a durable upload receipt")
            return
        }
        await fixture.store.upload()
        #expect(fixture.store.delivery?.document == accepted.document)
        #expect(fixture.store.delivery?.attemptCount == 1)
        #expect(fixture.store.delivery?.state == uploaded.state)
        let client = try #require(fixture.container.mainContext.fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(client.status == .active(consentReference: receipt.reference))
    }

    @Test
    func uploadActionRemainsVisibleButCannotRunAgainWhileSending() async throws {
        let gate = RecoveryOperationGate()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage()) {
            await gate.enter()
        }
        let fixture = try ConsentFlowFixture(storage: storage)
        _ = try await fixture.sign()
        await fixture.store.accept()
        #expect(fixture.store.hasUploadAction)
        let task = Task {
            await fixture.store.upload()
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        #expect(entered)
        #expect(fixture.store.hasUploadAction)
        #expect(!fixture.store.canUpload)
        await gate.release()
        await task.value
        #expect(!fixture.store.hasUploadAction)
        #expect(fixture.store.delivery?.attemptCount == 1)
    }

    @Test
    func unavailableUploadIsAnActionableFailureWithoutLosingDocument() async throws {
        let fixture = try ConsentFlowFixture()
        _ = try await fixture.sign()
        await fixture.store.accept()
        let document = try #require(fixture.store.delivery?.document)
        await fixture.store.upload()
        #expect(fixture.store.failure == .unavailable)
        #expect(fixture.store.delivery?.state == .failed(.unavailable))
        #expect(fixture.store.delivery?.document == document)
    }

    @Test
    func cancellationDuringRenderFencesLateOutputAndKeepsSignedDraft() async throws {
        let gate = RecoveryOperationGate()
        let fixture = try ConsentFlowFixture(renderer: GatedRecoveryRenderer(gate: gate))
        let draft = try await fixture.sign()
        let task = Task {
            await fixture.store.accept()
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        fixture.store.close()
        task.cancel()
        await gate.release()
        await task.value
        #expect(entered)
        #expect(fixture.store.phase == .closed)
        #expect(fixture.store.snapshot == nil)
        #expect(try await fixture.services.repository.draft(id: draft.id)?.fields.binding == draft.fields.binding)
        #expect(try await fixture.services.repository.deliveries(clientID: fixture.clientID).isEmpty)
    }
}

@MainActor
struct ConsentFlowFixture {
    let container: ModelContainer
    let services: ClientConsentServices
    let store: ClientConsentStore
    let clientID: ClientID
    let profile: ClientProfile
}

extension ConsentFlowFixture {
    init(
        renderer: any ClientDocumentRenderer = ConsentFlowRenderer(),
        storage: any ClientDocumentStorage = RefusingRecoveryStorage(),
        saveChanges: @escaping @Sendable (ModelContext) throws -> Void = {
            try $0.save()
        }
    ) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let repository = ClientDocumentRecoveryFixtures.repository(
            persistence: ClientDocumentPersistenceActor(modelContainer: container, saveChanges: saveChanges)
        )
        let services = ClientConsentServices(
            repository: repository,
            activationRepository: DefaultClientActivationRepository(
                persistence: repository.persistence,
                access: repository.access,
                observationSignal: repository.observationSignal
            ),
            catalog: BundleClientDocumentCatalog(bundle: .main),
            renderer: renderer,
            storage: storage,
            version: "2026-09-10-draft",
            language: "es",
            now: { ClientDocumentTestFixtures.date },
            newID: { UUID() }
        )
        let clientID = ClientID(rawValue: UUID())
        self.init(
            container: container,
            services: services,
            store: ClientConsentStore(clientID: clientID, services: services),
            clientID: clientID,
            profile: try ClientProfile(displayName: "Cliente de prueba")
        )
    }

    static func ink() throws -> ClientSignature {
        try ClientSignature(strokes: [[.init(x: 0.1, y: 0.2), .init(x: 0.7, y: 0.8)]])
    }

    func sign() async throws -> ClientDocumentDraft {
        await store.review(profile: profile)
        let id = try #require(store.startCapture())
        await store.completeCapture(.captured(try Self.ink()), id: id)
        return try #require(store.draft)
    }
}

struct ConsentFlowRenderer: ClientDocumentRenderer {
    static let bytes = Data("%PDF-1.7\nCONSENT FLOW SYNTHETIC ARTIFACT\n%%EOF\n".utf8)

    func render(binding: ClientDocumentSignature, signedAt: Date) async throws -> Data { Self.bytes }
}

private actor RetryingConsentRenderer: ClientDocumentRenderer {
    private var attempts = 0

    func render(binding: ClientDocumentSignature, signedAt: Date) throws -> Data {
        attempts += 1
        if attempts == 1 {
            throw ClientDocumentError.renderingFailed
        }
        return ConsentFlowRenderer.bytes
    }
}
