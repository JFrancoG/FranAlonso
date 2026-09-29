import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Form owned consent integration")
@MainActor
struct ClientConsentFormTests {
    @Test(arguments: [false, true])
    func `recovery adopts activation from another form while preserving local edits`(hasLocalEdit: Bool) async throws {
        let fixture = try ConsentFlowFixture(storage: InMemoryClientDocumentStorage())
        let first = writableModel(fixture, mode: .create)
        first.fields.displayName = fixture.profile.displayName
        await first.performConsent(.review)
        let capture = try #require(first.beginConsentCapture())
        await first.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), capture))
        await first.performConsent(.accept)
        let second = writableModel(fixture, mode: .edit)
        await second.load()
        if hasLocalEdit {
            second.fields.taxIdentifier = "UNSAVED-OTHER-FORM"
        }
        await first.performConsent(.upload)
        let active = try #require(first.loadedClient)
        guard case .active = active.status else {
            Issue.record("Expected the first form to activate the client")
            return
        }
        await second.performConsent(.recover)
        #expect(second.loadedClient == active)
        #expect(second.consentActivationMessage == .clientsConsentActivated)
        #expect(!second.hasConsentUploadAction)
        #expect(second.hasUnsavedChanges == hasLocalEdit)
        #expect(second.fields.taxIdentifier == (hasLocalEdit ? "UNSAVED-OTHER-FORM" : ""))
    }

    @Test(arguments: [false, true])
    func `activation confirmation identifies the selected document`(uploadOther: Bool) async throws {
        let fixture = try ConsentFlowFixture(storage: InMemoryClientDocumentStorage())
        let signed = try await fixture.sign()
        await fixture.store.accept()
        let initial = try #require(fixture.store.delivery)
        let snapshot = try #require(signed.fields.snapshot)
        let otherSnapshot = try ClientDocumentSnapshot(.init(
            id: UUID(),
            clientID: fixture.clientID,
            clientName: snapshot.fields.clientName,
            context: snapshot.fields.context,
            content: snapshot.fields.content
        ))
        let otherDraft = try ClientDocumentDraft(.init(
            id: UUID(),
            clientID: fixture.clientID,
            profile: fixture.profile,
            snapshot: otherSnapshot,
            binding: ClientDocumentSignature(snapshot: otherSnapshot, signature: ConsentFlowFixture.ink()),
            signedAt: ClientDocumentTestFixtures.date,
            revision: 0
        ))
        let saved = try await fixture.services.repository.saveDraft(otherDraft, operationID: UUID())
        let other = try await RenderAndPersistConsentUseCase(
            repository: fixture.services.repository,
            renderer: fixture.services.renderer
        )(draftID: saved.id)
        if uploadOther {
            _ = try await UploadConsentUseCase(
                repository: fixture.services.repository,
                storage: fixture.services.storage,
                now: fixture.services.now
            )(documentID: other.id)
        }
        let active = try #require(await fixture.store.upload())
        let reopened = writableModel(fixture, mode: .edit)
        await reopened.load()
        await reopened.performConsent(.selectDelivery(other.id))
        #expect(reopened.consentActivationMessage != nil)
        #expect(reopened.consentActivationMessage == .clientsConsentActivationUnlinked)
        #expect(!reopened.hasConsentUploadAction)
        await reopened.performConsent(.recover)
        await reopened.performConsent(.selectDelivery(initial.id))
        #expect(reopened.consentActivationMessage == .clientsConsentActivated)
        #expect(!reopened.hasConsentUploadAction)
        let current = try ClientLocalDataSource().client(id: fixture.clientID, in: ModelContext(fixture.container))
        #expect(current == active)
    }

    @Test
    func `activation preserves a profile edit committed by another form during upload`() async throws {
        let gate = RecoveryOperationGate()
        let storage = AfterUploadRecoveryStorage(base: InMemoryClientDocumentStorage()) { await gate.enter() }
        let fixture = try ConsentFlowFixture(storage: storage)
        let first = writableModel(fixture, mode: .create)
        first.fields.displayName = fixture.profile.displayName
        await first.performConsent(.review)
        let capture = try #require(first.beginConsentCapture())
        await first.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), capture))
        await first.performConsent(.accept)
        let second = writableModel(fixture, mode: .edit)
        await second.load()
        let upload = Task {
            await first.performConsent(.upload)
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        second.fields.displayName = "Perfil actualizado durante el envío"
        second.fields.taxIdentifier = "NEW-TAX-ACTIVATION"
        await second.save(in: ModelContext(fixture.container))
        await gate.release()
        await upload.value
        #expect(entered)
        let context = ModelContext(fixture.container)
        let current = try #require(try ClientLocalDataSource().client(id: fixture.clientID, in: context))
        guard case .active = current.status else {
            Issue.record("Expected the uploaded document to activate the current profile")
            return
        }
        #expect(current.displayName == "Perfil actualizado durante el envío")
        #expect(current.taxIdentifier == "NEW-TAX-ACTIVATION")
        #expect(first.loadedClient == current)
        #expect(first.fields.displayName == current.displayName)
        let operations = try ClientLocalDataSource().pendingOperations(in: context)
        let activeWrites = operations.compactMap { operation -> ClientDTO? in
            guard case .upsert(let upsert) = operation else { return nil }
            guard upsert.client.status == .active else { return nil }
            return upsert.client
        }
        #expect(activeWrites.count == 1)
        #expect(try activeWrites.first?.toDomain() == current)
    }

    @Test
    func `activation leaves unsaved form fields editable while updating the persisted status`() async throws {
        let fixture = try ConsentFlowFixture(storage: InMemoryClientDocumentStorage())
        let model = writableModel(fixture, mode: .create)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        let capture = try #require(model.beginConsentCapture())
        await model.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), capture))
        await model.performConsent(.accept)
        model.fields.taxIdentifier = "UNSAVED-TAX"
        await model.performConsent(.upload)
        let loaded = try #require(model.loadedClient)
        guard case .active = loaded.status else {
            Issue.record("Expected the facade to adopt the durable activation result")
            return
        }
        #expect(model.fields.taxIdentifier == "UNSAVED-TAX")
        #expect(model.hasUnsavedChanges)
        #expect(loaded.taxIdentifier == nil)
        #expect(!model.canReviewConsent)
    }

    @Test(arguments: [false, true])
    func savingAfterDocumentCompletionUpdatesTheAlreadyCreatedClient(acceptDocument: Bool) async throws {
        let fixture = try ConsentFlowFixture()
        let model = writableModel(fixture, mode: .create)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        if acceptDocument {
            let id = try #require(model.beginConsentCapture())
            await model.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
            await model.performConsent(.accept)
        } else {
            await model.performConsent(.discard)
        }
        await model.performConsent(.backToForm)
        model.fields.taxIdentifier = "NEW-AFTER-DOCUMENT"
        await model.save(in: fixture.container.mainContext)
        guard case .saved(let client) = model.state else {
            Issue.record("Expected an update of the client already created by review")
            return
        }
        #expect(client.taxIdentifier == "NEW-AFTER-DOCUMENT")
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<ClientModel>()) == 1)
        let deliveries = try await fixture.services.repository.deliveries(clientID: fixture.clientID)
        #expect(deliveries.count == (acceptDocument ? 1 : 0))
    }

    @Test
    func signingCannotOverwriteAProfileEditedByAnotherOpenForm() async throws {
        let fixture = try ConsentFlowFixture()
        _ = try ClientLocalDataSource().createClient(
            id: fixture.clientID,
            profile: fixture.profile,
            operationID: UUID(),
            in: fixture.container.mainContext
        )
        let first = writableModel(fixture, mode: .edit)
        let second = writableModel(fixture, mode: .edit)
        await first.load()
        await second.load()
        await first.performConsent(.review)
        let id = try #require(first.beginConsentCapture())
        second.fields.displayName = "Perfil más reciente en otra ventana"
        await second.save(in: ModelContext(fixture.container))
        await first.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        let current = try #require(try ClientLocalDataSource().client(
            id: fixture.clientID,
            in: ModelContext(fixture.container)
        ))
        #expect(current.displayName == "Perfil más reciente en otra ventana")
        #expect(first.consentStore?.failure == .conflict)
        #expect(first.consentStore?.canAccept == false)
        #expect(try await fixture.services.repository.deliveries(clientID: fixture.clientID).isEmpty)
        await first.performConsent(.recover)
        #expect(first.fields.displayName == "Perfil más reciente en otra ventana")
        #expect(first.consentStore?.phase == .profileConflict)
        await first.performConsent(.useCurrentProfile)
        #expect(first.consentStore?.failure == nil)
        #expect(first.consentStore?.snapshot?.fields.clientName == "Perfil más reciente en otra ventana")
        #expect(first.consentStore?.signature == nil)
    }

    @Test
    func `a name edited in another form during rendering requires a new signature`() async throws {
        let gate = RecoveryOperationGate()
        let fixture = try ConsentFlowFixture(renderer: GatedRecoveryRenderer(gate: gate))
        _ = try ClientLocalDataSource().createClient(
            id: fixture.clientID, profile: fixture.profile, operationID: UUID(), in: fixture.container.mainContext
        )
        let first = writableModel(fixture, mode: .edit)
        let second = writableModel(fixture, mode: .edit)
        await first.load()
        await second.load()
        await first.performConsent(.review)
        let id = try #require(first.beginConsentCapture())
        await first.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        let task = Task {
            await first.performConsent(.accept)
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        second.fields.displayName = "Nombre cambiado durante render"
        await second.save(in: ModelContext(fixture.container))
        await gate.release()
        await task.value

        #expect(entered)
        let current = try #require(try ClientLocalDataSource().client(
            id: fixture.clientID, in: ModelContext(fixture.container)
        ))
        #expect(current.displayName == "Nombre cambiado durante render")
        #expect(first.consentStore?.failure == .conflict)
        #expect(first.consentStore?.canAccept == false)
        #expect(first.consentStore?.delivery == nil)
        #expect(try await fixture.services.repository.deliveries(clientID: fixture.clientID).isEmpty)
        await first.performConsent(.recover)
        #expect(first.consentStore?.phase == .profileConflict)
        await first.performConsent(.useCurrentProfile)
        #expect(first.consentStore?.snapshot?.fields.clientName == "Nombre cambiado durante render")
        #expect(first.consentStore?.signature == nil)
        #expect(first.consentStore?.canCapture == true)
    }

    @Test
    func `an unpresented field edited during rendering preserves acceptance and historical retries`() async throws {
        let gate = RecoveryOperationGate()
        let fixture = try ConsentFlowFixture(renderer: GatedRecoveryRenderer(gate: gate))
        _ = try ClientLocalDataSource().createClient(
            id: fixture.clientID, profile: fixture.profile, operationID: UUID(), in: fixture.container.mainContext
        )
        let first = writableModel(fixture, mode: .edit)
        let second = writableModel(fixture, mode: .edit)
        await first.load()
        await second.load()
        await first.performConsent(.review)
        let id = try #require(first.beginConsentCapture())
        await first.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        let signed = try #require(first.consentStore?.draft)
        let task = Task {
            await first.performConsent(.accept)
            await gate.finish()
        }
        let entered = await gate.waitForEntry()
        second.fields.taxIdentifier = "TAX-EDITED-DURING-RENDER"
        await second.save(in: ModelContext(fixture.container))
        await gate.release()
        await task.value

        #expect(entered)
        #expect(first.consentStore?.failure == nil)
        let accepted = try #require(first.consentStore?.delivery)
        #expect(accepted.document.fields.binding == signed.fields.binding)
        #expect(accepted.document.fields.pdf == ClientDocumentPersistenceFixtures.bytes)
        let current = try #require(try ClientLocalDataSource().client(
            id: fixture.clientID, in: ModelContext(fixture.container)
        ))
        #expect(current.taxIdentifier == "TAX-EDITED-DURING-RENDER")

        let reopened = writableModel(fixture, mode: .edit)
        await reopened.load()
        reopened.fields.displayName = "Nombre posterior al documento aceptado"
        await reopened.save(in: ModelContext(fixture.container))
        let renamed = try #require(try ClientLocalDataSource().client(
            id: fixture.clientID, in: ModelContext(fixture.container)
        ))
        #expect(renamed.displayName == "Nombre posterior al documento aceptado")
        let repeated = try await fixture.services.repository.accept(
            accepted.document, draftID: signed.id, revision: signed.fields.revision
        )
        #expect(repeated == accepted)
        #expect(try await fixture.services.repository.deliveries(clientID: fixture.clientID).count == 1)
    }

    @Test
    func invalidRevisionDoesNotRestorePreviouslySavedFields() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        await model.performConsent(.backToForm)
        model.fields.displayName = ""
        model.fields.taxIdentifier = "UNSAVED"
        await model.performConsent(.review)
        #expect(model.fields.displayName.isEmpty)
        #expect(model.fields.taxIdentifier == "UNSAVED")
        #expect(model.state == .failed(.save, .invalidDisplayName))
    }

    @Test
    func reopeningAcceptedDocumentDoesNotOverwriteNewFormEdits() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        let id = try #require(model.beginConsentCapture())
        await model.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        await model.performConsent(.accept)
        await model.performConsent(.backToForm)
        model.fields.taxIdentifier = "NEW-UNSAVED"
        await model.performConsent(.review)
        #expect(model.fields.taxIdentifier == "NEW-UNSAVED")
        #expect(model.consentStore?.phase == .retained)
        #expect(model.hasUnsavedChanges)
    }

    @Test
    func consultingInformationDoesNotDiscardUnsavedFormEdits() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        await model.performConsent(.backToForm)
        model.fields.taxIdentifier = "UNSAVED-TAX"
        await model.performConsent(.information)
        await model.performConsent(.backToForm)
        #expect(model.fields.taxIdentifier == "UNSAVED-TAX")
        #expect(model.hasUnsavedChanges)
        #expect(model.consentStore?.draft?.fields.profile.taxIdentifier == nil)
    }

    @Test
    func changingNameDuringCaptureRejectsItsObsoleteCompletion() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        let id = try #require(model.beginConsentCapture())
        model.fields.displayName = "Nombre revisado"
        await model.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        #expect(model.consentStore?.signature == nil)
        #expect(model.consentStore?.canAccept == false)
        #expect(model.fields.displayName == "Nombre revisado")
        await model.performConsent(.review)
        #expect(model.consentStore?.snapshot?.fields.clientName == "Nombre revisado")
        #expect(model.consentStore?.signature == nil)
    }

    @Test
    func reviewPersistsThroughDocumentsAndKeepsTheFormOpen() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = "  Cliente de prueba  "
        await model.performConsent(.review)
        #expect(model.state == .editing)
        #expect(model.consentStore?.phase == .review)
        #expect(model.consentStore?.isPresented == true)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientModel>()) == 1)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 1)
    }

    @Test
    func savingAfterReviewUsesDocumentPipelineAndInvalidatesChangedName() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        let id = try #require(model.beginConsentCapture())
        await model.performConsent(.captured(.captured(try ConsentFlowFixture.ink()), id))
        let original = try #require(model.consentStore?.draft)
        await model.performConsent(.backToForm)
        model.fields.displayName = "Corrección visible"
        await model.save(in: fixture.container.mainContext)
        #expect(model.state == .saved(.draft(id: fixture.clientID, displayName: "Corrección visible")))
        let changed = try #require(try await fixture.services.repository.draft(id: original.id))
        #expect(changed.fields.profile.displayName == "Corrección visible")
        #expect(changed.fields.binding == nil)
        #expect(changed.fields.snapshot?.id != original.fields.snapshot?.id)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientModel>()) == 1)
    }

    @Test
    func invalidProfileNeverPersistsButPublicInformationRemainsReadable() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        await model.performConsent(.information)
        #expect(model.consentStore?.content != nil)
        await model.performConsent(.backToForm)
        model.fields.displayName = "   "
        await model.performConsent(.review)
        #expect(model.state == .failed(.save, .invalidDisplayName))
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientModel>()) == 0)
    }

    @Test
    func activeClientCannotStartAnotherInitialSignature() async throws {
        let fixture = try ConsentFlowFixture()
        let active = Client(
            id: fixture.clientID,
            displayName: fixture.profile.displayName,
            taxIdentifier: nil,
            billingAddress: nil,
            status: .active(consentReference: try ClientConsentReference(rawValue: "fixture/active"))
        )
        try ClientLocalDataSource().upsert(active, in: fixture.container.mainContext)
        let model = model(fixture, mode: .edit)
        await model.load()
        #expect(!model.canReviewConsent)
        await model.performConsent(.review)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 0)
        await model.performConsent(.information)
        #expect(model.consentStore?.content != nil)
    }

    @Test
    func closeClearsPersonalCopiesAndPreservesRecoverableWork() async throws {
        let fixture = try ConsentFlowFixture()
        let model = model(fixture)
        model.fields.displayName = fixture.profile.displayName
        await model.performConsent(.review)
        let draft = try #require(model.consentStore?.draft)
        model.close()
        #expect(model.fields.displayName.isEmpty)
        #expect(model.consentStore?.snapshot == nil)
        #expect(model.state == .closed)
        #expect(try await fixture.services.repository.draft(id: draft.id) != nil)
    }

    private func writableModel(_ fixture: ConsentFlowFixture, mode: ClientFormDestination.Mode) -> ClientFormViewModel {
        AppDependencies.makeClientFormViewModel(
            destination: .init(id: UUID(), clientID: fixture.clientID, mode: mode),
            persistenceActor: ClientPersistenceActor(modelContainer: fixture.container),
            observationSignal: ClientObservationSignal(),
            makeClientConsentServices: { fixture.services }
        )
    }

    private func model(
        _ fixture: ConsentFlowFixture,
        mode: ClientFormDestination.Mode = .create
    ) -> ClientFormViewModel {
        let repository = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(modelContainer: fixture.container),
            observationSignal: ClientObservationSignal()
        )
        return ClientFormViewModel(
            destination: .init(id: UUID(), clientID: fixture.clientID, mode: mode),
            getClient: GetClientUseCase(repository: repository),
            create: { _, _, _ in
                throw ClientError.persistenceUnavailable
            },
            update: { _, _, _ in
                throw ClientError.persistenceUnavailable
            },
            deactivate: { _, _ in
                throw ClientError.persistenceUnavailable
            },
            consentServices: fixture.services
        )
    }
}
