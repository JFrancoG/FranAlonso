/// Coordinates an email and password authentication intent.
struct SignInUseCase {
    private let authenticationRepository: any AuthenticationRepository

    /// Authenticates after checking cancellation and rejecting empty credentials.
    ///
    /// Cancellation wins before repository delegation. Once delegation begins, the repository
    /// result is authoritative because an in-flight provider operation may not be cancellable.
    ///
    /// - Parameters:
    ///   - email: The externally provisioned account email.
    ///   - password: The account password.
    /// - Returns: The principal reported by the repository.
    /// - Throws: `CancellationError` before delegation, `AuthenticationError.invalidCredentials`
    ///   for an empty value, or the repository error unchanged.
    func callAsFunction(
        email: String,
        password: String
    ) async throws -> AuthenticationSession {
        try Task.checkCancellation()

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthenticationError.invalidCredentials
        }

        return try await authenticationRepository.signIn(
            email: email,
            password: password
        )
    }
}

extension SignInUseCase {
    /// Creates the use case with its feature-owned authentication boundary.
    ///
    /// - Parameter repository: The repository that authenticates the supplied credentials.
    init(repository: any AuthenticationRepository) {
        self.init(authenticationRepository: repository)
    }
}
