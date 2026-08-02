/// Deterministic authentication dependencies used only by application previews.
struct AuthenticationPreviewFixtures {
    let session: AuthenticationSession

    /// Creates a sign-in use case that never contacts a live provider.
    func makeSignInUseCase() -> SignInUseCase {
        SignInUseCase(
            repository: AuthenticationPreviewRepository(session: session)
        )
    }

    /// Creates an uncomposed session model backed by a stable preview observation.
    @MainActor
    func makeSessionViewModel(biometricsAvailable: Bool = true) -> SessionViewModel {
        let repository = AuthenticationPreviewRepository(session: session)

        return SessionViewModel(
            observeSession: ObserveSessionUseCase(repository: repository),
            signOut: SignOutUseCase(repository: repository),
            biometricAuthenticator: BiometricAuthenticator(
                canAuthenticate: { biometricsAvailable },
                authenticate: { _ in }
            )
        )
    }

    /// Creates a signed-out root backed only by inert preview dependencies.
    @MainActor
    func makeSignedOutRootViewModel() -> AuthenticationRootViewModel {
        let repository = AuthenticationSignedOutPreviewRepository(session: session)

        return makeRootViewModel(repository: repository) { _ in }
    }

    /// Creates a root whose observed principal is denied by the local binding.
    @MainActor
    func makeLocalAccessDeniedRootViewModel() -> AuthenticationRootViewModel {
        let repository = AuthenticationPreviewRepository(session: session)
        let viewModel = makeRootViewModel(repository: repository) { _ in
            throw LocalPrincipalAuthorizationError.differentPrincipal
        }
        viewModel.registerRecentSignIn(session)
        return viewModel
    }

    /// Creates a root whose authoritative observation ends without a replacement.
    @MainActor
    func makeObservationFailedRootViewModel() -> AuthenticationRootViewModel {
        let repository = AuthenticationFinishedPreviewRepository(session: session)
        return makeRootViewModel(repository: repository) { _ in }
    }

    /// Creates a root authorized by a matching recent credential intent and stream principal.
    @MainActor
    func makeAuthenticatedRootViewModel() -> AuthenticationRootViewModel {
        let repository = AuthenticationPreviewRepository(session: session)
        let viewModel = makeRootViewModel(repository: repository) { _ in }
        viewModel.registerRecentSignIn(session)
        return viewModel
    }

    @MainActor
    private func makeRootViewModel<Repository>(
        repository: Repository,
        authorize: @escaping @Sendable (AuthenticationSession) async throws -> Void
    ) -> AuthenticationRootViewModel where Repository: AuthenticationRepository {
        AuthenticationRootViewModel(
            signIn: SignInUseCase(repository: repository),
            observeSession: ObserveSessionUseCase(repository: repository),
            signOut: SignOutUseCase(repository: repository),
            biometricAuthenticator: BiometricAuthenticator(
                canAuthenticate: { false },
                authenticate: { _ in }
            ),
            authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(
                authorizer: LocalPrincipalAuthorizer(authorize: authorize)
            )
        )
    }
}

extension AuthenticationPreviewFixtures {
    /// The stable authenticated principal shared by authentication previews.
    static let standard = AuthenticationPreviewFixtures(
        session: AuthenticationSession(id: "preview-principal")
    )
}

private struct AuthenticationPreviewRepository: AuthenticationRepository {
    let session: AuthenticationSession

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        session
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        let session = session

        return AsyncStream { continuation in
            continuation.yield(session)
        }
    }
}

private struct AuthenticationSignedOutPreviewRepository: AuthenticationRepository {
    let session: AuthenticationSession

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        session
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        AsyncStream { continuation in
            continuation.yield(nil)
        }
    }
}

private struct AuthenticationFinishedPreviewRepository: AuthenticationRepository {
    let session: AuthenticationSession

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        session
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
