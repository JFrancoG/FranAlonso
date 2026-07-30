/// Exposes provider-neutral authentication session changes to consumers.
struct ObserveSessionUseCase {
    private let authenticationRepository: any AuthenticationRepository

    /// Starts observing the current and subsequent authentication states.
    ///
    /// - Returns: A stream whose first element is the current session state.
    func callAsFunction() async -> AsyncStream<AuthenticationSession?> {
        await authenticationRepository.observeSession()
    }
}

extension ObserveSessionUseCase {
    /// Creates the use case with its feature-owned authentication boundary.
    ///
    /// - Parameter repository: The repository that provides session changes.
    init(repository: any AuthenticationRepository) {
        self.init(authenticationRepository: repository)
    }
}
