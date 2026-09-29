import Foundation
import SwiftData
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Reusable Develop demo composition")
@MainActor
struct DevelopDemoCompositionTests {
    @Test
    func `launch seeds synthetic clients and products without unrelated business data`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients)
        let composition = demo.applicationComposition
        let context = ModelContext(composition.modelContainer)
        let clients = try ClientLocalDataSource().fetchAll(in: context)

        #expect(clients.map(\.displayName) == ["Cliente DEMO Alba", "Cliente DEMO Bruno"])
        #expect(clients.allSatisfy { $0.status == .draft && $0.taxIdentifier == nil && $0.billingAddress == nil })
        #expect(Set(clients.map { $0.id.rawValue.uuidString }) == [
            "088A0000-0000-4000-8000-000000000001", "088A0000-0000-4000-8000-000000000002"
        ])
        let operations = try ClientLocalDataSource().pendingOperations(in: context)
        #expect(operations.count == 2)
        #expect(operations.allSatisfy { $0.predecessorOperationID == nil })
        #expect(Set(operations.map { $0.operationID.uuidString }) == [
            "088A0000-0000-4000-9000-000000000001", "088A0000-0000-4000-9000-000000000002"
        ])
        #expect(try context.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(await demo.documentRemoteStore.documentCount == 0)
        #expect(composition.runtime == nil)
    }

    @Test
    func `form changes survive reopen and relogin but a new composition restores the scenario`() async throws {
        let session = try await DemoTestSession.make(configuration: .clients)
        defer { session.observation.cancel() }
        let initial = try session.clients()
        let alba = try #require(initial.first)
        let edit = session.form(clientID: alba.id, mode: .edit)
        await edit.load()
        edit.fields.displayName = "Cliente DEMO Alba revisada"
        await edit.save(in: ModelContext(session.composition.modelContainer))
        #expect(edit.loadedClient?.displayName == "Cliente DEMO Alba revisada")
        edit.close()
        let newID = ClientID(rawValue: UUID())
        let create = session.form(clientID: newID, mode: .create)
        create.fields.displayName = "Cliente DEMO creada"
        await create.save(in: ModelContext(session.composition.modelContainer))
        #expect(create.loadedClient?.id == newID)
        create.close()

        await session.signOut()
        try await session.signIn()
        let reopened = session.form(clientID: alba.id, mode: .edit)
        await reopened.load()
        #expect(reopened.fields.displayName == "Cliente DEMO Alba revisada")
        #expect(try session.clients().count == 3)

        let restarted = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        let restored = try ClientLocalDataSource().fetchAll(in: ModelContext(restarted.modelContainer))
        #expect(restored == initial)
        #expect(try session.clients().count == 3)
    }

    @Test
    func `demo logout revokes document and activation capabilities across same principal login`() async throws {
        let session = try await DemoTestSession.make(configuration: .clients)
        defer { session.observation.cancel() }
        let client = try #require(try session.clients().first)
        let oldForm = session.form(clientID: client.id, mode: .edit)
        await oldForm.load()
        await oldForm.performConsent(.review)
        let oldServices = try #require(oldForm.consentStore?.services)
        let draft = try #require(oldForm.consentStore?.draft)

        await session.signOut()
        #expect(session.form(clientID: client.id, mode: .edit).consentUnavailable)
        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await oldServices.repository.draft(id: draft.id)
        }
        try await session.signIn()
        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await oldServices.activationRepository.prepareActivation(
                clientID: client.id, documentID: UUID(), operationID: UUID()
            )
        }
        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await oldServices.repository.draft(id: draft.id)
        }
        let newForm = session.form(clientID: client.id, mode: .edit)
        await newForm.load()
        #expect(newForm.consentStore?.draft == draft)
        #expect(newForm.consentStore?.failure == nil)
    }
}

@MainActor
struct DemoTestSession {
    let demo: DevelopDemoComposition
    let root: AuthenticationRootViewModel
    let observation: Task<Void, Never>

    var composition: ApplicationComposition { demo.applicationComposition }

    static func make(configuration: DevelopDemoComposition.Configuration) async throws -> DemoTestSession {
        let demo = try DevelopDemoComposition.make(configuration: configuration)
        let root = try #require(demo.applicationComposition.authenticationRootViewModel)
        let observation = Task { await root.sessionViewModel.load() }
        let session = DemoTestSession(demo: demo, root: root, observation: observation)
        await session.waitForEvent(1)
        root.sessionEventDidChange()
        #expect(root.state == .signedOut)
        do {
            try await session.signIn()
        } catch {
            observation.cancel()
            throw error
        }
        return session
    }

    func signIn() async throws {
        let expectedRevision = root.sessionViewModel.sessionEventRevision + 1
        root.loginViewModel.email = DevelopAuthenticationFixture.email
        root.loginViewModel.password = DevelopAuthenticationFixture.password
        await root.loginViewModel.signIn()
        guard case .succeeded(let session) = root.loginViewModel.state else {
            Issue.record("The synthetic credentials must traverse the normal login pipeline")
            throw DemoTestError.signInFailed
        }
        root.registerRecentSignIn(session)
        await waitForEvent(expectedRevision)
        root.sessionEventDidChange()
        await root.authorizeLocalAccessIfNeeded()
        #expect(root.state == .authenticated(session))
    }

    func signOut() async {
        let expectedRevision = root.sessionViewModel.sessionEventRevision + 1
        await root.signOut()
        await waitForEvent(expectedRevision)
        root.sessionEventDidChange()
        #expect(root.state == .signedOut)
    }

    func clients() throws -> [Client] {
        try ClientLocalDataSource().fetchAll(in: ModelContext(composition.modelContainer))
    }

    func form(clientID: ClientID, mode: ClientFormDestination.Mode) -> ClientFormViewModel {
        composition.dependencies.makeClientForm(.init(id: UUID(), clientID: clientID, mode: mode))
    }

    private func waitForEvent(_ revision: Int) async {
        for _ in 0..<10_000 {
            if root.sessionViewModel.sessionEventRevision >= revision {
                return
            }
            await Task.yield()
        }
        Issue.record("The demo authentication event did not arrive")
    }
}

private enum DemoTestError: Error {
    case signInFailed
}
#endif
