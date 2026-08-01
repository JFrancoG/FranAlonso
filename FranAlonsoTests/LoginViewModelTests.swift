import Testing
@testable import FranAlonso

@Suite("Login view model")
@MainActor
struct LoginViewModelTests {
    @Test("Starts idle with empty ephemeral credentials")
    func startsIdleWithEmptyEphemeralCredentials() {
        let viewModel = makeLoginViewModel(repository: LoginAuthenticationRepositoryFake())

        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.state == .idle)
    }

    @Test("Successful sign in publishes the intent result and clears the password")
    func successfulSignInPublishesIntentResultAndClearsPassword() async {
        let expectedSession = AuthenticationSession(id: "principal-login-success")
        let repository = LoginAuthenticationRepositoryFake(behavior: .succeeds(expectedSession))
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"

        await viewModel.signIn()

        #expect(viewModel.state == .succeeded(expectedSession))
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.email == "owner@example.com")
        #expect(
            await repository.requests()
                == [LoginRequest(email: "owner@example.com", password: "ephemeral-password")]
        )
    }

    @Test(
        "Invalid credentials and disabled accounts share one presentation failure",
        arguments: [AuthenticationError.invalidCredentials, .accountDisabled]
    )
    func credentialFailuresShareOnePresentationFailure(_ error: AuthenticationError) async {
        let repository = LoginAuthenticationRepositoryFake(behavior: .fails(error))
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "invalid-password"

        await viewModel.signIn()

        #expect(viewModel.state == .failed(.credentialsRejected))
        #expect(viewModel.password == "invalid-password")
    }

    @Test(
        "Stable authentication failures keep provider-neutral presentation categories",
        arguments: [
            LoginFailureFixture(error: .temporarilyUnavailable, expected: .temporarilyUnavailable),
            LoginFailureFixture(error: .configuration, expected: .configuration),
            LoginFailureFixture(error: .secureStorageUnavailable, expected: .secureStorageUnavailable),
            LoginFailureFixture(error: .unexpected, expected: .unexpected)
        ]
    )
    fileprivate func stableAuthenticationFailuresKeepProviderNeutralCategories(_ fixture: LoginFailureFixture) async {
        let repository = LoginAuthenticationRepositoryFake(behavior: .fails(fixture.error))
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"

        await viewModel.signIn()

        #expect(viewModel.state == .failed(fixture.expected))
    }

    @Test("An unknown repository failure becomes unexpected")
    func unknownRepositoryFailureBecomesUnexpected() async {
        let repository = LoginAuthenticationRepositoryFake(behavior: .failsUnknown)
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"

        await viewModel.signIn()

        #expect(viewModel.state == .failed(.unexpected))
    }

    @Test("Duplicate submissions are ignored while the first intent is loading")
    func duplicateSubmissionsAreIgnoredWhileFirstIntentIsLoading() async {
        let gate = LoginOperationGate()
        let expectedSession = AuthenticationSession(id: "principal-login-gated")
        let repository = LoginAuthenticationRepositoryFake(
            behavior: .waits(expectedSession, gate)
        )
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"
        let firstSubmission = Task { @MainActor in
            await viewModel.signIn()
        }

        await gate.waitUntilBlocked()
        #expect(viewModel.state == .loading)

        await viewModel.signIn()

        #expect(await repository.requests().count == 1)
        await gate.release()
        await firstSubmission.value
        #expect(viewModel.state == .succeeded(expectedSession))
    }

    @Test("Cooperative cancellation restores idle without reporting failure")
    func cooperativeCancellationRestoresIdleWithoutReportingFailure() async {
        let repository = LoginAuthenticationRepositoryFake(behavior: .cancels)
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"

        await viewModel.signIn()

        #expect(viewModel.state == .idle)
        #expect(viewModel.password == "ephemeral-password")
    }

    @Test("Cancellation after repository delegation does not override a successful intent")
    func cancellationAfterRepositoryDelegationDoesNotOverrideSuccessfulIntent() async {
        let gate = LoginOperationGate()
        let expectedSession = AuthenticationSession(id: "principal-login-cancelled-after-delegation")
        let repository = LoginAuthenticationRepositoryFake(
            behavior: .waits(expectedSession, gate)
        )
        let viewModel = makeLoginViewModel(repository: repository)
        viewModel.email = "owner@example.com"
        viewModel.password = "ephemeral-password"
        let submission = Task { @MainActor in
            await viewModel.signIn()
        }

        await gate.waitUntilBlocked()
        submission.cancel()
        await gate.release()
        await submission.value

        #expect(viewModel.state == .succeeded(expectedSession))
        #expect(viewModel.password.isEmpty)
    }
}

private struct LoginRequest: Equatable {
    let email: String
    let password: String
}

private struct LoginFailureFixture {
    let error: AuthenticationError
    let expected: LoginViewModel.Failure
}

private enum LoginRepositoryFailure: Error {
    case expected
}

private enum LoginAuthenticationBehavior {
    case succeeds(AuthenticationSession)
    case fails(AuthenticationError)
    case failsUnknown
    case waits(AuthenticationSession, LoginOperationGate)
    case cancels
}

private actor LoginAuthenticationRepositoryFake: AuthenticationRepository {
    private let behavior: LoginAuthenticationBehavior
    private var recordedRequests: [LoginRequest] = []

    init(behavior: LoginAuthenticationBehavior = .fails(.unexpected)) {
        self.behavior = behavior
    }

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        recordedRequests.append(LoginRequest(email: email, password: password))

        switch behavior {
        case let .succeeds(session):
            return session
        case let .fails(error):
            throw error
        case .failsUnknown:
            throw LoginRepositoryFailure.expected
        case let .waits(session, gate):
            await gate.wait()
            return session
        case .cancels:
            throw CancellationError()
        }
    }

    func signOut() async throws {}

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func requests() -> [LoginRequest] {
        recordedRequests
    }
}

private actor LoginOperationGate {
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
private func makeLoginViewModel(repository: LoginAuthenticationRepositoryFake) -> LoginViewModel {
    LoginViewModel(signIn: SignInUseCase(repository: repository))
}
