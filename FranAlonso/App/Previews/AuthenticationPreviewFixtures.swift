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
