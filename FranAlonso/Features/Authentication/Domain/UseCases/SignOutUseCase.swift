/// Coordinates ending the current authentication session.
struct SignOutUseCase {
    private let authenticationRepository: any AuthenticationRepository

    /// Delegates session termination to the authentication repository.
    ///
    /// - Throws: The repository error unchanged.
    func callAsFunction() async throws {
        try await authenticationRepository.signOut()
    }
}

extension SignOutUseCase {
    /// Creates the use case with its feature-owned authentication boundary.
    ///
    /// - Parameter repository: The repository that ends the provider session.
    init(repository: any AuthenticationRepository) {
        self.init(authenticationRepository: repository)
    }
}
