import Testing
@testable import FranAlonso

@Suite("Authentication root view model")
@MainActor
struct AuthenticationRootViewModelTests {
    @Test("A sign-in result never grants access before the stream confirms it")
    func signInResultNeverGrantsAccessBeforeStreamConfirmation() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-login")

        viewModel.registerRecentSignIn(session)

        #expect(viewModel.state == .checkingSession)
        #expect(await authorization.sessions.isEmpty)
    }

    @Test("A matching observed UID authorizes a recent email and password login without biometrics")
    func matchingObservedUIDAuthorizesRecentLoginWithoutBiometrics() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let biometrics = BiometricProbe()
        let viewModel = makeRootViewModel(
            repository: repository,
            authorization: authorization,
            biometricProbe: biometrics
        )
        let session = AuthenticationSession(id: "principal-login")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .authenticated(session))
        #expect(await authorization.sessions == [session])
        #expect(await biometrics.invocationCount == 0)
        await cancelRootObservation(observation)
    }

    @Test("A different observed UID invalidates the recent credential proof")
    func differentObservedUIDInvalidatesRecentCredentialProof() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(AuthenticationSession(id: "principal-login"))
        await repository.emit(AuthenticationSession(id: "principal-other"))
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions.isEmpty)
        await cancelRootObservation(observation)
    }

    @Test("An observed nil invalidates a recent credential proof even when already signed out")
    func observedNilInvalidatesRecentCredentialProofWhenAlreadySignedOut() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-login")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        await repository.emit(nil)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        viewModel.registerRecentSignIn(session)
        await repository.emit(nil)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 2 }
        viewModel.sessionEventDidChange()
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 3 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions.isEmpty)
        await cancelRootObservation(observation)
    }

    @Test("Consecutive nil and original UID events cannot reopen previously authorized access")
    func consecutiveNilAndOriginalUIDCannotReopenAuthorizedAccess() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-authorized")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()
        #expect(viewModel.state == .authenticated(session))

        await repository.emit(nil)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 3 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions == [session])
        await cancelRootObservation(observation)
    }

    @Test("Consecutive different and original UID events cannot reopen previously authorized access")
    func consecutiveDifferentAndOriginalUIDCannotReopenAuthorizedAccess() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-authorized")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()
        #expect(viewModel.state == .authenticated(session))

        await repository.emit(AuthenticationSession(id: "principal-other"))
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 3 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions == [session])
        await cancelRootObservation(observation)
    }

    @Test("A restored session requires biometrics before local authorization")
    func restoredSessionRequiresBiometricsBeforeLocalAuthorization() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let biometrics = BiometricProbe()
        let viewModel = makeRootViewModel(
            repository: repository,
            authorization: authorization,
            biometricProbe: biometrics
        )
        let session = AuthenticationSession(id: "principal-restored")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions.isEmpty)

        await viewModel.sessionViewModel.unlock(localizedReason: "Unlock the existing session")
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .authenticated(session))
        #expect(await authorization.sessions == [session])
        #expect(await biometrics.invocationCount == 1)
        await cancelRootObservation(observation)
    }

    @Test("Email and password recover access when restored-session biometrics are unavailable")
    func emailAndPasswordRecoverAccessWhenBiometricsAreUnavailable() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let biometrics = BiometricProbe()
        let viewModel = makeRootViewModel(
            repository: repository,
            authorization: authorization,
            biometricProbe: biometrics,
            biometricsAvailable: false
        )
        let session = AuthenticationSession(id: "principal-recovery")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.sessionViewModel.unlock(localizedReason: "Unlock the restored session")

        #expect(viewModel.state == .locked)
        #expect(viewModel.sessionViewModel.actionState == .failed(.biometricUnavailable))

        await repository.emit(nil)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 2 }
        viewModel.sessionEventDidChange()
        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 3 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .authenticated(session))
        #expect(await authorization.sessions == [session])
        #expect(await biometrics.invocationCount == 0)
        await cancelRootObservation(observation)
    }

    @Test("A stale authorization result cannot grant access after the principal changes")
    func staleAuthorizationResultCannotGrantAccessAfterPrincipalChanges() async {
        let repository = AuthenticationRootRepositoryFake()
        let gate = AuthorizationGate()
        let authorization = LocalAuthorizationFake(gate: gate)
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let firstSession = AuthenticationSession(id: "principal-first")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(firstSession)
        await repository.emit(firstSession)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        let authorizationTask = Task { @MainActor in
            await viewModel.authorizeLocalAccessIfNeeded()
        }
        await gate.waitUntilBlocked()

        await repository.emit(AuthenticationSession(id: "principal-second"))
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 2 }
        viewModel.sessionEventDidChange()
        await gate.release()
        await authorizationTask.value

        #expect(viewModel.state == .locked)
        await cancelRootObservation(observation)
    }

    @Test("Cancelling local authorization invalidates recent credential proof")
    func cancellingLocalAuthorizationInvalidatesRecentCredentialProof() async {
        let repository = AuthenticationRootRepositoryFake()
        let gate = AuthorizationGate()
        let authorization = LocalAuthorizationFake(gate: gate)
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-cancelled")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        let authorizationTask = Task { @MainActor in
            await viewModel.authorizeLocalAccessIfNeeded()
        }
        await gate.waitUntilBlocked()

        authorizationTask.cancel()
        await gate.release()
        await authorizationTask.value

        #expect(viewModel.state == .locked)
        #expect(await authorization.sessions == [session])
        await cancelRootObservation(observation)
    }

    @Test("A local authorization failure keeps the protected shell closed")
    func localAuthorizationFailureKeepsProtectedShellClosed() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake(error: .differentPrincipal)
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-denied")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        #expect(viewModel.state == .localAccessDenied(.differentPrincipal))
        await cancelRootObservation(observation)
    }

    @Test("Unexpected observation completion immediately removes an authorized shell")
    func unexpectedObservationCompletionRemovesAuthorizedShell() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-observation")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()
        #expect(viewModel.state == .authenticated(session))

        await repository.finishObservation()
        await observation.value

        #expect(viewModel.state == .observationFailed)
    }

    @Test("Logout hides the shell until the stream publishes authoritative nil")
    func logoutHidesShellUntilStreamPublishesAuthoritativeNil() async {
        let repository = AuthenticationRootRepositoryFake()
        let authorization = LocalAuthorizationFake()
        let viewModel = makeRootViewModel(repository: repository, authorization: authorization)
        let session = AuthenticationSession(id: "principal-logout")
        let observation = startRootObservation(viewModel)
        await repository.waitUntilObserved()

        viewModel.registerRecentSignIn(session)
        await repository.emit(session)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 1 }
        viewModel.sessionEventDidChange()
        await viewModel.authorizeLocalAccessIfNeeded()

        await viewModel.signOut()

        #expect(viewModel.state == .signingOut)

        await repository.emit(nil)
        await waitUntil { viewModel.sessionViewModel.sessionEventRevision == 2 }
        viewModel.sessionEventDidChange()

        #expect(viewModel.state == .signedOut)
        await cancelRootObservation(observation)
    }
}

private actor AuthenticationRootRepositoryFake: AuthenticationRepository {
    private let stream: AsyncStream<AuthenticationSession?>
    private let continuation: AsyncStream<AuthenticationSession?>.Continuation
    private var observationStarted = false
    private var observationWaiters: [CheckedContinuation<Void, Never>] = []

    init() {
        let pair = AsyncStream<AuthenticationSession?>.makeStream()
        stream = pair.stream
        continuation = pair.continuation
    }

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        AuthenticationSession(id: "principal-login")
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        observationStarted = true
        observationWaiters.forEach { $0.resume() }
        observationWaiters.removeAll()
        return stream
    }

    func emit(_ session: AuthenticationSession?) {
        continuation.yield(session)
    }

    func finishObservation() {
        continuation.finish()
    }

    func waitUntilObserved() async {
        guard !observationStarted else { return }
        await withCheckedContinuation { continuation in
            observationWaiters.append(continuation)
        }
    }
}

private actor LocalAuthorizationFake {
    private let gate: AuthorizationGate?
    private let error: LocalPrincipalAuthorizationError?
    private(set) var sessions: [AuthenticationSession] = []

    init(
        gate: AuthorizationGate? = nil,
        error: LocalPrincipalAuthorizationError? = nil
    ) {
        self.gate = gate
        self.error = error
    }

    func authorize(_ session: AuthenticationSession) async throws {
        sessions.append(session)
        await gate?.wait()
        if let error {
            throw error
        }
    }
}

private actor BiometricProbe {
    private(set) var invocationCount = 0

    func authenticate() {
        invocationCount += 1
    }
}

private actor AuthorizationGate {
    private var blocked = false
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func wait() async {
        blocked = true
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        guard !blocked else { return }
        await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

@MainActor
private func makeRootViewModel(
    repository: AuthenticationRootRepositoryFake,
    authorization: LocalAuthorizationFake,
    biometricProbe: BiometricProbe = BiometricProbe(),
    biometricsAvailable: Bool = true
) -> AuthenticationRootViewModel {
    AuthenticationRootViewModel(
        signIn: SignInUseCase(repository: repository),
        observeSession: ObserveSessionUseCase(repository: repository),
        signOut: SignOutUseCase(repository: repository),
        biometricAuthenticator: BiometricAuthenticator(
            canAuthenticate: { biometricsAvailable },
            authenticate: { _ in
                await biometricProbe.authenticate()
            }
        ),
        authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(
            authorizer: LocalPrincipalAuthorizer { session in
                try await authorization.authorize(session)
            }
        )
    )
}

@MainActor
private func startRootObservation(_ viewModel: AuthenticationRootViewModel) -> Task<Void, Never> {
    Task { @MainActor in
        await viewModel.sessionViewModel.load()
    }
}

@MainActor
private func cancelRootObservation(_ task: Task<Void, Never>) async {
    task.cancel()
    await task.value
}

@MainActor
private func waitUntil(_ condition: @MainActor () -> Bool) async {
    for _ in 0..<10_000 {
        if condition() {
            return
        }
        await Task.yield()
    }

    Issue.record("Expected authentication-root transition did not occur")
}
