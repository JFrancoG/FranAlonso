import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Form owned consent integration")
@MainActor
struct ClientConsentFormTests {
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
