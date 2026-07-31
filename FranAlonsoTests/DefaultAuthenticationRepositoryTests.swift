import Testing
@testable import FranAlonso

@Suite("Authentication default repository")
struct DefaultAuthenticationRepositoryTests {
    @Test("Sign in delegates credentials and returns the DataSource session")
    func signInDelegatesCredentialsAndReturnsSession() async throws {
        let expectedSession = AuthenticationSession(id: "principal-101")
        let dataSource = AuthenticationDataSourceFake(
            signInBehavior: .succeeds(expectedSession)
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        let session = try await repository.signIn(
            email: "owner@example.com",
            password: "valid-password"
        )

        #expect(session == expectedSession)
        #expect(
            await dataSource.signInRequests()
                == [
                    AuthenticationDataSourceSignInRequest(
                        email: "owner@example.com",
                        password: "valid-password"
                    )
                ]
        )
    }

    @Test(
        "Sign in maps provider-neutral infrastructure failures",
        arguments: [
            (
                AuthenticationDataSourceError.credentialsRejected,
                AuthenticationError.invalidCredentials
            ),
            (
                AuthenticationDataSourceError.accountDisabled,
                AuthenticationError.accountDisabled
            ),
            (
                AuthenticationDataSourceError.networkUnavailable,
                AuthenticationError.temporarilyUnavailable
            ),
            (
                AuthenticationDataSourceError.rateLimited,
                AuthenticationError.temporarilyUnavailable
            ),
            (
                AuthenticationDataSourceError.misconfigured,
                AuthenticationError.configuration
            ),
            (
                AuthenticationDataSourceError.secureStorageUnavailable,
                AuthenticationError.secureStorageUnavailable
            ),
            (
                AuthenticationDataSourceError.unexpected,
                AuthenticationError.unexpected
            )
        ]
    )
    func signInMapsInfrastructureFailures(
        _ infrastructureError: AuthenticationDataSourceError,
        to expectedError: AuthenticationError
    ) async {
        let dataSource = AuthenticationDataSourceFake(
            signInBehavior: .fails(infrastructureError)
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: expectedError) {
            try await repository.signIn(
                email: "owner@example.com",
                password: "invalid-password"
            )
        }
        #expect(await dataSource.signInRequests().count == 1)
    }

    @Test("Sign in maps an undeclared failure to unexpected")
    func signInMapsUndeclaredFailureToUnexpected() async {
        let dataSource = AuthenticationDataSourceFake(
            signInBehavior: .failsWithUndeclaredError
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: AuthenticationError.unexpected) {
            try await repository.signIn(
                email: "owner@example.com",
                password: "valid-password"
            )
        }
    }

    @Test("Sign in preserves DataSource cancellation")
    func signInPreservesDataSourceCancellation() async {
        let dataSource = AuthenticationDataSourceFake(
            signInBehavior: .cancels
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: CancellationError.self) {
            try await repository.signIn(
                email: "owner@example.com",
                password: "valid-password"
            )
        }
    }

    @Test("Sign out delegates successfully")
    func signOutDelegatesSuccessfully() async throws {
        let dataSource = AuthenticationDataSourceFake()
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        try await repository.signOut()

        #expect(await dataSource.signOutCallCount() == 1)
    }

    @Test(
        "Sign out maps provider-neutral infrastructure failures",
        arguments: [
            (
                AuthenticationDataSourceError.credentialsRejected,
                AuthenticationError.invalidCredentials
            ),
            (
                AuthenticationDataSourceError.accountDisabled,
                AuthenticationError.accountDisabled
            ),
            (
                AuthenticationDataSourceError.networkUnavailable,
                AuthenticationError.temporarilyUnavailable
            ),
            (
                AuthenticationDataSourceError.rateLimited,
                AuthenticationError.temporarilyUnavailable
            ),
            (
                AuthenticationDataSourceError.misconfigured,
                AuthenticationError.configuration
            ),
            (
                AuthenticationDataSourceError.secureStorageUnavailable,
                AuthenticationError.secureStorageUnavailable
            ),
            (
                AuthenticationDataSourceError.unexpected,
                AuthenticationError.unexpected
            )
        ]
    )
    func signOutMapsInfrastructureFailures(
        _ infrastructureError: AuthenticationDataSourceError,
        to expectedError: AuthenticationError
    ) async {
        let dataSource = AuthenticationDataSourceFake(
            signOutBehavior: .fails(infrastructureError)
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: expectedError) {
            try await repository.signOut()
        }
        #expect(await dataSource.signOutCallCount() == 1)
    }

    @Test("Sign out maps an undeclared failure to unexpected")
    func signOutMapsUndeclaredFailureToUnexpected() async {
        let dataSource = AuthenticationDataSourceFake(
            signOutBehavior: .failsWithUndeclaredError
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: AuthenticationError.unexpected) {
            try await repository.signOut()
        }
        #expect(await dataSource.signOutCallCount() == 1)
    }

    @Test("Sign out preserves DataSource cancellation")
    func signOutPreservesDataSourceCancellation() async {
        let dataSource = AuthenticationDataSourceFake(
            signOutBehavior: .cancels
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        await #expect(throws: CancellationError.self) {
            try await repository.signOut()
        }
        #expect(await dataSource.signOutCallCount() == 1)
    }

    @Test("Observation preserves prebuffered signed-out then signed-in order")
    func observationPreservesPrebufferedOrder() async {
        let session = AuthenticationSession(id: "principal-102")
        let dataSource = AuthenticationDataSourceFake(
            sessionStream: authenticationSessionStream([nil, session])
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        let stream = await repository.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(nil)
        )
        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(session)
        )
        #expect(await dataSource.observationCallCount() == 1)
    }

    @Test("Natural upstream finish ends repository observation")
    func naturalUpstreamFinishEndsObservation() async {
        let dataSource = AuthenticationDataSourceFake(
            sessionStream: authenticationSessionStream([])
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        let stream = await repository.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next() == nil)
    }

    @Test("Consumer cancellation terminates upstream exactly once")
    func consumerCancellationTerminatesUpstreamExactlyOnce() async {
        await confirmation(
            "The upstream stream terminates once",
            expectedCount: 1
        ) { upstreamTerminated in
            let upstream = AsyncStream<AuthenticationSession?> { continuation in
                continuation.onTermination = { _ in
                    upstreamTerminated()
                }
            }
            let dataSource = AuthenticationDataSourceFake(
                sessionStream: upstream
            )
            let repository = DefaultAuthenticationRepository(
                dataSource: dataSource
            )
            let started = AsyncStream.makeStream(of: Void.self)
            let pendingIteration = Task {
                let stream = await repository.observeSession()
                var iterator = stream.makeAsyncIterator()
                started.continuation.yield()
                return await iterator.next()
            }
            var startedIterator = started.stream.makeAsyncIterator()
            _ = await startedIterator.next()

            pendingIteration.cancel()

            #expect(await pendingIteration.value == nil)
            started.continuation.finish()
        }
    }

    @Test("Upstream values yielded after finish are not observed")
    func valuesYieldedAfterFinishAreNotObserved() async {
        let ignoredSession = AuthenticationSession(id: "principal-103")
        let upstream = AsyncStream<AuthenticationSession?> { continuation in
            continuation.yield(nil)
            continuation.finish()
            continuation.yield(ignoredSession)
        }
        let dataSource = AuthenticationDataSourceFake(sessionStream: upstream)
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)

        let stream = await repository.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(nil)
        )
        #expect(await iterator.next() == nil)
    }

    @Test("Authentication Data boundary values are Sendable")
    func authenticationDataBoundaryValuesAreSendable() {
        let dataSource = AuthenticationDataSourceFake()

        requireAuthenticationDataSendable(
            AuthenticationDataSourceError.unexpected
        )
        requireAuthenticationDataSourceSendable(dataSource)
        requireAuthenticationDataSendable(
            DefaultAuthenticationRepository(dataSource: dataSource)
        )
    }
}

private struct AuthenticationDataSourceSignInRequest: Equatable {
    let email: String
    let password: String
}

private struct UndeclaredAuthenticationDataSourceError: Error {}

private enum AuthenticationDataSourceSignInBehavior {
    case succeeds(AuthenticationSession)
    case fails(AuthenticationDataSourceError)
    case failsWithUndeclaredError
    case cancels
}

private enum AuthenticationDataSourceSignOutBehavior {
    case succeeds
    case fails(AuthenticationDataSourceError)
    case failsWithUndeclaredError
    case cancels
}

private actor AuthenticationDataSourceFake: AuthenticationDataSource {
    private let signInBehavior: AuthenticationDataSourceSignInBehavior
    private let signOutBehavior: AuthenticationDataSourceSignOutBehavior
    private let sessionStream: AsyncStream<AuthenticationSession?>
    private var recordedSignInRequests: [AuthenticationDataSourceSignInRequest] = []
    private var signOutCalls = 0
    private var observationCalls = 0

    init(
        signInBehavior: AuthenticationDataSourceSignInBehavior = .fails(.unexpected),
        signOutBehavior: AuthenticationDataSourceSignOutBehavior = .succeeds,
        sessionStream: AsyncStream<AuthenticationSession?> = authenticationSessionStream([])
    ) {
        self.signInBehavior = signInBehavior
        self.signOutBehavior = signOutBehavior
        self.sessionStream = sessionStream
    }

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticationSession {
        recordedSignInRequests.append(
            AuthenticationDataSourceSignInRequest(
                email: email,
                password: password
            )
        )

        switch signInBehavior {
        case let .succeeds(session):
            return session
        case let .fails(error):
            throw error
        case .failsWithUndeclaredError:
            throw UndeclaredAuthenticationDataSourceError()
        case .cancels:
            throw CancellationError()
        }
    }

    func signOut() async throws {
        signOutCalls += 1

        switch signOutBehavior {
        case .succeeds:
            return
        case let .fails(error):
            throw error
        case .failsWithUndeclaredError:
            throw UndeclaredAuthenticationDataSourceError()
        case .cancels:
            throw CancellationError()
        }
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        observationCalls += 1
        return sessionStream
    }

    func signInRequests() -> [AuthenticationDataSourceSignInRequest] {
        recordedSignInRequests
    }

    func signOutCallCount() -> Int {
        signOutCalls
    }

    func observationCallCount() -> Int {
        observationCalls
    }
}

private func authenticationSessionStream(
    _ sessions: [AuthenticationSession?]
) -> AsyncStream<AuthenticationSession?> {
    AsyncStream { continuation in
        for session in sessions {
            continuation.yield(session)
        }
        continuation.finish()
    }
}

private func requireAuthenticationDataSendable<Value: Sendable>(
    _ value: Value
) {}

private func requireAuthenticationDataSourceSendable(
    _ dataSource: any AuthenticationDataSource
) {
    requireAuthenticationDataSendable(dataSource)
}
