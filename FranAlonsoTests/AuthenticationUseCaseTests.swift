import Foundation
import Testing
@testable import FranAlonso

@Suite("Authentication use cases")
struct AuthenticationUseCaseTests {
    @Test("Sign in delegates valid credentials and returns the session")
    func signInDelegatesValidCredentialsAndReturnsSession() async throws {
        let expectedSession = AuthenticationSession(id: "principal-002")
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .succeeds(expectedSession)
        )
        let useCase = SignInUseCase(repository: repository)

        let session = try await useCase(
            email: "owner@example.com",
            password: "valid-password"
        )

        #expect(session == expectedSession)
        #expect(
            await repository.signInRequests()
                == [
                    AuthenticationSignInRequest(
                        email: "owner@example.com",
                        password: "valid-password"
                    )
                ]
        )
    }

    @Test("Sign in rejects an empty email before delegating")
    func signInRejectsEmptyEmailBeforeDelegating() async {
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .succeeds(
                AuthenticationSession(id: "unused-principal")
            )
        )
        let useCase = SignInUseCase(repository: repository)

        await #expect(throws: AuthenticationError.invalidCredentials) {
            try await useCase(email: "", password: "valid-password")
        }
        #expect(await repository.signInRequests().isEmpty)
    }

    @Test("Sign in rejects an empty password before delegating")
    func signInRejectsEmptyPasswordBeforeDelegating() async {
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .succeeds(
                AuthenticationSession(id: "unused-principal")
            )
        )
        let useCase = SignInUseCase(repository: repository)

        await #expect(throws: AuthenticationError.invalidCredentials) {
            try await useCase(email: "owner@example.com", password: "")
        }
        #expect(await repository.signInRequests().isEmpty)
    }

    @Test("A pre-cancelled sign in wins over credential validation")
    func preCancelledSignInWinsOverCredentialValidation() async {
        let gate = AuthenticationTestGate()
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .succeeds(
                AuthenticationSession(id: "unused-principal")
            )
        )
        let useCase = SignInUseCase(repository: repository)
        let task = Task {
            await gate.wait()
            return try await useCase(email: "", password: "")
        }

        await gate.waitUntilBlocked()
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await repository.signInRequests().isEmpty)
    }

    @Test("Sign in propagates a repository authentication failure")
    func signInPropagatesRepositoryFailure() async {
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .fails(.invalidCredentials)
        )
        let useCase = SignInUseCase(repository: repository)

        await #expect(throws: AuthenticationError.invalidCredentials) {
            try await useCase(
                email: "owner@example.com",
                password: "invalid-password"
            )
        }
        #expect(await repository.signInRequests().count == 1)
    }

    @Test("Sign in propagates repository cancellation")
    func signInPropagatesRepositoryCancellation() async {
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .cancels
        )
        let useCase = SignInUseCase(repository: repository)

        await #expect(throws: CancellationError.self) {
            try await useCase(
                email: "owner@example.com",
                password: "valid-password"
            )
        }
        #expect(await repository.signInRequests().count == 1)
    }

    @Test("Cancellation after delegation does not override repository success")
    func cancellationAfterDelegationDoesNotOverrideRepositorySuccess() async throws {
        let expectedSession = AuthenticationSession(id: "principal-003")
        let gate = AuthenticationTestGate()
        let repository = AuthenticationRepositoryFake(
            signInBehavior: .succeeds(expectedSession),
            signInGate: gate
        )
        let useCase = SignInUseCase(repository: repository)
        let task = Task {
            try await useCase(
                email: "owner@example.com",
                password: "valid-password"
            )
        }

        await gate.waitUntilBlocked()
        task.cancel()
        await gate.release()

        #expect(try await task.value == expectedSession)
        #expect(await repository.signInRequests().count == 1)
    }

    @Test("Sign out delegates to the repository")
    func signOutDelegatesToRepository() async throws {
        let repository = AuthenticationRepositoryFake()
        let useCase = SignOutUseCase(repository: repository)

        try await useCase()

        #expect(await repository.signOutCallCount() == 1)
    }

    @Test("Sign out propagates secure storage failure")
    func signOutPropagatesSecureStorageFailure() async {
        let repository = AuthenticationRepositoryFake(
            signOutBehavior: .fails(.secureStorageUnavailable)
        )
        let useCase = SignOutUseCase(repository: repository)

        await #expect(throws: AuthenticationError.secureStorageUnavailable) {
            try await useCase()
        }
        #expect(await repository.signOutCallCount() == 1)
    }

    @Test("Session observation preserves signed-out then signed-in order")
    func observeSessionPreservesSignedOutThenSignedInOrder() async {
        let session = AuthenticationSession(id: "principal-004")
        let repository = AuthenticationRepositoryFake(
            observedSessions: [nil, session]
        )
        let useCase = ObserveSessionUseCase(repository: repository)

        let stream = await useCase()
        var iterator = stream.makeAsyncIterator()

        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(nil)
        )
        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(session)
        )
        #expect(await iterator.next() == nil)
        #expect(await repository.observationCallCount() == 1)
    }

}

private struct AuthenticationSignInRequest: Equatable {
    let email: String
    let password: String
}

private enum AuthenticationSignInBehavior {
    case succeeds(AuthenticationSession)
    case fails(AuthenticationError)
    case cancels
}

private enum AuthenticationSignOutBehavior {
    case succeeds
    case fails(AuthenticationError)
}

private actor AuthenticationRepositoryFake: AuthenticationRepository {
    private let signInBehavior: AuthenticationSignInBehavior?
    private let signOutBehavior: AuthenticationSignOutBehavior
    private let observedSessions: [AuthenticationSession?]
    private let signInGate: AuthenticationTestGate?
    private var recordedSignInRequests: [AuthenticationSignInRequest] = []
    private var signOutCalls = 0
    private var observationCalls = 0

    init(
        signInBehavior: AuthenticationSignInBehavior? = nil,
        signOutBehavior: AuthenticationSignOutBehavior = .succeeds,
        observedSessions: [AuthenticationSession?] = [],
        signInGate: AuthenticationTestGate? = nil
    ) {
        self.signInBehavior = signInBehavior
        self.signOutBehavior = signOutBehavior
        self.observedSessions = observedSessions
        self.signInGate = signInGate
    }

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        recordedSignInRequests.append(
            AuthenticationSignInRequest(email: email, password: password)
        )

        if let signInGate {
            await signInGate.wait()
        }

        switch signInBehavior {
        case let .succeeds(session):
            return session
        case let .fails(error):
            throw error
        case .cancels:
            throw CancellationError()
        case nil:
            throw AuthenticationError.unexpected
        }
    }

    func signOut() async throws {
        signOutCalls += 1

        switch signOutBehavior {
        case .succeeds:
            return
        case let .fails(error):
            throw error
        }
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        observationCalls += 1
        let sessions = observedSessions

        return AsyncStream { continuation in
            for session in sessions {
                continuation.yield(session)
            }
            continuation.finish()
        }
    }

    func signInRequests() -> [AuthenticationSignInRequest] { recordedSignInRequests }

    func signOutCallCount() -> Int { signOutCalls }

    func observationCallCount() -> Int { observationCalls }
}

private actor AuthenticationTestGate {
    private var isBlocked = false
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func wait() async {
        isBlocked = true
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()

        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        if isBlocked {
            return
        }

        await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}
