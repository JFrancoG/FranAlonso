import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Authorized client document composition")
@MainActor
struct ClientDocumentCompositionTests {
    @Test
    func `document access is unavailable before the root authorizes its principal`() throws {
        let fixture = DocumentAuthenticationFixture()
        #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try fixture.root.makeClientDocumentAccess()
        }
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let composition = ClientDocumentComposition(
            modelContainer: container,
            observationSignal: ClientObservationSignal()
        )
        #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try composition.makeRepository()
        }
    }

    @Test
    func `logout followed by the same principal never revives the earlier document capability`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let oldAccess = try fixture.root.makeClientDocumentAccess()
        try await oldAccess.validate()

        await fixture.repository.emit(nil)
        await fixture.waitForEvent(2)
        fixture.root.sessionEventDidChange()
        await fixture.authenticate(expectedEvent: 3)

        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await oldAccess.validate()
        }
        try await fixture.root.makeClientDocumentAccess().validate()
    }

    @Test
    func `batched principal replacement invalidates documents without a presentation callback`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let access = try fixture.root.makeClientDocumentAccess()

        await fixture.repository.emit(AuthenticationSession(id: "synthetic-other-document-principal"))
        await fixture.repository.emit(fixture.session)
        await fixture.waitForEvent(3)

        await #expect(throws: ClientDocumentAccessError.sessionExpired) { try await access.validate() }
    }

    @Test
    func `replacing local authorization revokes documents even when the account has not changed`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let access = try fixture.root.makeClientDocumentAccess()

        fixture.root.retryObservation()
        await #expect(throws: ClientDocumentAccessError.sessionExpired) { try await access.validate() }
        fixture.root.registerRecentSignIn(fixture.session)
        await fixture.root.authorizeLocalAccessIfNeeded()
        #expect(fixture.root.state == .authenticated(fixture.session))
        await #expect(throws: ClientDocumentAccessError.sessionExpired) { try await access.validate() }
        try await fixture.root.makeClientDocumentAccess().validate()
    }

    @Test
    func `a principal lookup suspended across logout cannot release protected document data`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let access = try fixture.root.makeClientDocumentAccess()
        await fixture.authorization.suspendNextCall()
        let validation = Task { try await access.validate() }
        await fixture.authorization.waitUntilSuspended()

        await fixture.root.signOut()
        await fixture.authorization.release()

        await #expect(throws: ClientDocumentAccessError.sessionExpired) { try await validation.value }
    }

    @Test
    func `two document capabilities share durable revisions and the client list signal`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let authenticationObservation = fixture.observe()
        defer { authenticationObservation.cancel() }
        await fixture.authenticate()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let signal = ClientObservationSignal()
        let composition = ClientDocumentComposition(modelContainer: container, observationSignal: signal)
        composition.authenticationRoot = fixture.root
        let first = try composition.makeRepository()
        let second = try composition.makeRepository()
        let clients = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(modelContainer: container),
            observationSignal: signal
        )
        var list = await clients.observeClients().makeAsyncIterator()
        #expect(try await list.next() == [])
        let draft = try await ClientDocumentPersistenceFixtures.draft(signed: false)
        let saved = try await first.saveDraft(draft, operationID: UUID())
        let visible = try #require(try await list.next())
        #expect(visible.map(\.displayName) == ["Cliente sintético Álvarez"])
        #expect(try await second.draft(id: saved.id) == saved)

        let changed = try saved.revising(
            profile: ClientProfile(displayName: "Cliente sintético Álvarez", taxIdentifier: "SYNTHETIC-REVISION"),
            snapshot: saved.fields.snapshot
        )
        _ = try await second.saveDraft(changed, operationID: UUID())
        await #expect(throws: ClientDocumentPersistenceError.staleDraft) {
            try await first.saveDraft(saved, operationID: UUID())
        }
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<ClientModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 2)
    }

    @Test
    func `normal document composition retains its artifact when storage remains unavailable`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let composition = ClientDocumentComposition(
            modelContainer: container,
            observationSignal: ClientObservationSignal()
        )
        composition.authenticationRoot = fixture.root
        let services = try composition.makeServices()
        let saved = try await services.repository.saveDraft(
            ClientDocumentPersistenceFixtures.draft(),
            operationID: UUID()
        )
        let document = try ClientDocumentPersistenceFixtures.document(saved)
        _ = try await services.repository.accept(document, draftID: saved.id, revision: saved.fields.revision)
        let upload = UploadConsentUseCase(
            repository: services.repository,
            storage: services.storage,
            now: { ClientDocumentTestFixtures.date }
        )

        await #expect(throws: ClientDocumentStorageError.unavailable) {
            try await upload(documentID: document.id)
        }

        let retained = try #require(try await services.repository.delivery(id: document.id))
        #expect(retained.document.fields.pdf == ClientDocumentPersistenceFixtures.bytes)
        #expect(retained.state == .failed(.unavailable))
        #expect(retained.attemptCount == 1)
        let client = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(client.status == .draft)
    }

    @Test
    func `runtime forms bind document writes to the authorized root and fail closed after logout`() async throws {
        let fixture = DocumentAuthenticationFixture()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let runtime = AppRuntime(
            modelContainer: container,
            environment: .develop,
            makeAuthenticationRootViewModel: { _ in fixture.root }
        )
        let draft = try await ClientDocumentPersistenceFixtures.draft(signed: false)
        let destination = ClientFormDestination(id: UUID(), clientID: draft.fields.clientID, mode: .create)
        let unavailable = runtime.dependencies.makeClientForm(destination)
        #expect(unavailable.consentUnavailable)

        runtime.activateAuthentication(firebaseIsConfigured: true)
        let observation = fixture.observe()
        defer { observation.cancel() }
        await fixture.authenticate()
        let form = runtime.dependencies.makeClientForm(destination)
        let store = try #require(form.consentStore)
        _ = try await store.services.repository.saveDraft(draft, operationID: UUID())
        let context = ModelContext(container)
        let client = try #require(context.fetch(FetchDescriptor<ClientModel>()).first).toDomain()
        #expect(client.displayName == "Cliente sintético Álvarez")
        #expect(try context.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 1)

        await fixture.root.signOut()

        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await store.services.repository.drafts(clientID: destination.clientID)
        }
        #expect(runtime.dependencies.makeClientForm(destination).consentUnavailable)
    }

#if FRANALONSO_AUTH_FIXTURE
    @Test
    func `isolated Develop forms persist documents through fixture authentication and revoke old reads`() async throws {
        let fixture = try DevelopAuthenticationFixture.make(
            configuration: .standard(.restoredSession),
            biometricAuthenticator: BiometricAuthenticator(
                canAuthenticate: { true },
                authenticate: { _ in }
            )
        )
        let root = fixture.authenticationRootViewModel
        let observation = Task { await root.sessionViewModel.load() }
        defer { observation.cancel() }
        await waitForDocumentSessionEvent(root, revision: 1)
        root.sessionEventDidChange()
        await root.sessionViewModel.unlock(localizedReason: "Synthetic document fixture")
        await root.authorizeLocalAccessIfNeeded()
        let draft = try await ClientDocumentPersistenceFixtures.draft(signed: false)
        let form = fixture.dependencies.makeClientForm(
            ClientFormDestination(id: UUID(), clientID: draft.fields.clientID, mode: .create)
        )
        let store = try #require(form.consentStore)
        _ = try await store.services.repository.saveDraft(draft, operationID: UUID())
        #expect(try ModelContext(fixture.modelContainer).fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 1)

        await root.signOut()
        await waitForDocumentSessionEvent(root, revision: 2)

        await #expect(throws: ClientDocumentAccessError.sessionExpired) {
            try await store.services.repository.draft(id: draft.id)
        }
    }
#endif
}

@MainActor
private struct DocumentAuthenticationFixture {
    let repository = DocumentAuthenticationRepository()
    let authorization = DocumentAuthorizationProbe()
    let session = AuthenticationSession(id: "synthetic-document-principal")
    let root: AuthenticationRootViewModel

    func observe() -> Task<Void, Never> {
        Task { await root.sessionViewModel.load() }
    }

    func authenticate(expectedEvent: Int = 1) async {
        root.registerRecentSignIn(session)
        await repository.emit(session)
        await waitForEvent(expectedEvent)
        root.sessionEventDidChange()
        await root.authorizeLocalAccessIfNeeded()
        #expect(root.state == .authenticated(session))
    }

    func waitForEvent(_ revision: Int) async {
        await waitForDocumentSessionEvent(root, revision: revision)
    }
}

@MainActor
private func waitForDocumentSessionEvent(_ root: AuthenticationRootViewModel, revision: Int) async {
    for _ in 0..<10_000 {
        if root.sessionViewModel.sessionEventRevision == revision {
            return
        }
        await Task.yield()
    }
    Issue.record("The synthetic document session event did not arrive")
}

private extension DocumentAuthenticationFixture {
    init() {
        let repository = repository
        let authorization = authorization
        root = AuthenticationRootViewModel(
            signIn: SignInUseCase(repository: repository),
            observeSession: ObserveSessionUseCase(repository: repository),
            signOut: SignOutUseCase(repository: repository),
            biometricAuthenticator: BiometricAuthenticator(
                canAuthenticate: { true },
                authenticate: { _ in }
            ),
            authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(
                authorizer: LocalPrincipalAuthorizer { session in
                    await authorization.authorize(session)
                }
            )
        )
    }
}

private actor DocumentAuthenticationRepository: AuthenticationRepository {
    private let pair = AsyncStream<AuthenticationSession?>.makeStream()

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        AuthenticationSession(id: "synthetic-document-principal")
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> { pair.stream }

    func emit(_ session: AuthenticationSession?) {
        pair.continuation.yield(session)
    }
}

private actor DocumentAuthorizationProbe {
    private var shouldSuspend = false
    private var suspended = false
    private var continuation: CheckedContinuation<Void, Never>?
    private var observers: [CheckedContinuation<Void, Never>] = []

    func authorize(_ session: AuthenticationSession) async {
        guard shouldSuspend else { return }
        shouldSuspend = false
        suspended = true
        observers.forEach { $0.resume() }
        observers.removeAll()
        await withCheckedContinuation { continuation = $0 }
    }

    func suspendNextCall() {
        shouldSuspend = true
    }

    func waitUntilSuspended() async {
        guard !suspended else { return }
        await withCheckedContinuation { observers.append($0) }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}
