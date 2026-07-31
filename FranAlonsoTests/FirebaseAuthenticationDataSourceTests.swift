import FirebaseAuth
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firebase authentication data source")
struct FirebaseAuthenticationDataSourceTests {
    @Test("Sign in delegates exact credentials and converts the provider UID")
    func signInDelegatesCredentialsAndConvertsUID() async throws {
        let dataSource = makeFirebaseAuthenticationDataSource(
            signIn: { email, password in
                #expect(email == "owner@example.com")
                #expect(password == "ephemeral-password")
                return "principal-201"
            }
        )

        let session = try await dataSource.signIn(
            email: "owner@example.com",
            password: "ephemeral-password"
        )

        #expect(session == AuthenticationSession(id: "principal-201"))
    }

    @Test("Cancellation after delegation does not override provider success")
    func cancellationAfterDelegationDoesNotOverrideProviderSuccess() async throws {
        let gate = FirebaseSignInGate()
        let dataSource = makeFirebaseAuthenticationDataSource(
            signIn: { email, password in
                await gate.signIn(email: email, password: password)
            }
        )
        let signIn = Task {
            try await dataSource.signIn(
                email: "owner@example.com",
                password: "ephemeral-password"
            )
        }

        await gate.waitUntilReceived()
        signIn.cancel()
        await gate.succeed(with: "principal-202")

        #expect(
            try await signIn.value
                == AuthenticationSession(id: "principal-202")
        )
        #expect(
            await gate.receivedCredentials
                == [
                    FirebaseSignInCredentials(
                        email: "owner@example.com",
                        password: "ephemeral-password"
                    )
                ]
        )
    }

    @Test(
        "Sign in maps every approved Firebase error bucket",
        arguments: firebaseAuthenticationErrorFixtures
    )
    fileprivate func signInMapsFirebaseError(
        _ fixture: FirebaseAuthenticationErrorFixture
    ) async {
        let dataSource = makeFirebaseAuthenticationDataSource(
            signIn: { _, _ in
                throw firebaseAuthenticationError(code: fixture.code)
            }
        )

        await #expect(throws: fixture.expectedError) {
            try await dataSource.signIn(
                email: "owner@example.com",
                password: "ephemeral-password"
            )
        }
    }

    @Test("Sign in rejects non-Auth domains and unknown provider errors")
    func signInMapsUnsupportedFailuresToUnexpected() async {
        let knownButUnmapped = makeFirebaseAuthenticationDataSource(
            signIn: { _, _ in
                throw firebaseAuthenticationError(
                    code: AuthErrorCode.emailAlreadyInUse.rawValue
                )
            }
        )
        let unknownCode = makeFirebaseAuthenticationDataSource(
            signIn: { _, _ in
                throw firebaseAuthenticationError(code: 199_999)
            }
        )
        let foreignDomain = makeFirebaseAuthenticationDataSource(
            signIn: { _, _ in
                throw NSError(
                    domain: "ExampleAuthenticationErrorDomain",
                    code: AuthErrorCode.networkError.rawValue
                )
            }
        )

        for dataSource in [knownButUnmapped, unknownCode, foreignDomain] {
            await #expect(throws: AuthenticationDataSourceError.unexpected) {
                try await dataSource.signIn(
                    email: "owner@example.com",
                    password: "ephemeral-password"
                )
            }
        }
    }

    @Test("Sign in preserves injected cancellation")
    func signInPreservesInjectedCancellation() async {
        let dataSource = makeFirebaseAuthenticationDataSource(
            signIn: { _, _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await dataSource.signIn(
                email: "owner@example.com",
                password: "ephemeral-password"
            )
        }
    }

    @Test("Sign out delegates exactly once")
    func signOutDelegatesExactlyOnce() async throws {
        try await confirmation(
            "The Firebase sign-out operation is called once",
            expectedCount: 1
        ) { signOutCalled in
            let dataSource = makeFirebaseAuthenticationDataSource(
                signOut: { signOutCalled() }
            )

            try await dataSource.signOut()
        }
    }

    @Test("Sign out maps secure storage and unsupported failures")
    func signOutMapsFailures() async {
        let secureStorageFailure = makeFirebaseAuthenticationDataSource(
            signOut: {
                throw firebaseAuthenticationError(
                    code: AuthErrorCode.keychainError.rawValue
                )
            }
        )
        let unsupportedFailure = makeFirebaseAuthenticationDataSource(
            signOut: {
                throw firebaseAuthenticationError(
                    code: AuthErrorCode.internalError.rawValue
                )
            }
        )

        await #expect(
            throws: AuthenticationDataSourceError.secureStorageUnavailable
        ) {
            try await secureStorageFailure.signOut()
        }
        await #expect(throws: AuthenticationDataSourceError.unexpected) {
            try await unsupportedFailure.signOut()
        }
    }

    @Test("Sign out preserves injected cancellation")
    func signOutPreservesInjectedCancellation() async {
        let dataSource = makeFirebaseAuthenticationDataSource(
            signOut: { throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await dataSource.signOut()
        }
    }

    @Test("Observation preserves signed-out then signed-in source order")
    func observationPreservesSignedOutThenSignedInOrder() async {
        let expectedSession = AuthenticationSession(id: "principal-203")
        let upstream = firebasePrincipalStream([nil, expectedSession.id])
        let dataSource = makeFirebaseAuthenticationDataSource(
            observeSession: { firebaseSessionStream(from: upstream) }
        )

        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(nil)
        )
        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(expectedSession)
        )
        #expect(await iterator.next() == nil)
    }

    @Test("Natural upstream completion finishes downstream observation")
    func naturalUpstreamCompletionFinishesObservation() async {
        let upstream = firebasePrincipalStream([])
        let dataSource = makeFirebaseAuthenticationDataSource(
            observeSession: { firebaseSessionStream(from: upstream) }
        )

        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next() == nil)
    }

    @Test("Consumer cancellation terminates upstream exactly once")
    func consumerCancellationTerminatesUpstreamExactlyOnce() async {
        await confirmation(
            "The upstream sequence terminates once",
            expectedCount: 1
        ) { upstreamTerminated in
            let upstream = AsyncStream.makeStream(of: String?.self)
            upstream.continuation.onTermination = { _ in
                upstreamTerminated()
            }
            let dataSource = makeFirebaseAuthenticationDataSource(
                observeSession: {
                    firebaseSessionStream(from: upstream.stream)
                }
            )
            let started = AsyncStream.makeStream(of: Void.self)
            let pendingIteration = Task {
                let stream = await dataSource.observeSession()
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

    @Test("Abandoning observation before iteration terminates upstream once")
    func abandonmentBeforeIterationTerminatesUpstreamExactlyOnce() async {
        await confirmation(
            "The upstream sequence terminates once",
            expectedCount: 1
        ) { upstreamTerminated in
            let upstream = AsyncStream.makeStream(of: String?.self)
            upstream.continuation.onTermination = { _ in
                upstreamTerminated()
            }
            let relayStarted = AsyncStream.makeStream(of: Void.self)
            let dataSource = makeFirebaseAuthenticationDataSource(
                observeSession: {
                    FirebaseAuthenticationDataSource.sessionStream(
                        from: upstream.stream,
                        transform: { principalID in
                            relayStarted.continuation.yield()
                            return authenticationSession(id: principalID)
                        }
                    )
                }
            )
            var stream: AsyncStream<AuthenticationSession?>? =
                await dataSource.observeSession()
            var relayStartedIterator = relayStarted.stream.makeAsyncIterator()

            upstream.continuation.yield(nil)
            _ = await relayStartedIterator.next()
            #expect(stream != nil)

            stream = nil
            relayStarted.continuation.finish()
        }
    }

    @Test("Breaking observation then releasing it terminates upstream once")
    func earlyBreakThenReleaseTerminatesUpstreamExactlyOnce() async {
        await confirmation(
            "The upstream sequence terminates once",
            expectedCount: 1
        ) { upstreamTerminated in
            let upstream = AsyncStream.makeStream(of: String?.self)
            upstream.continuation.onTermination = { _ in
                upstreamTerminated()
            }
            let dataSource = makeFirebaseAuthenticationDataSource(
                observeSession: {
                    firebaseSessionStream(from: upstream.stream)
                }
            )
            var stream: AsyncStream<AuthenticationSession?>? =
                await dataSource.observeSession()
            upstream.continuation.yield(nil)

            if let observedStream = stream {
                for await _ in observedStream {
                    break
                }
            }

            stream = nil
        }
    }

    @Test("Values yielded after upstream finish are not observed")
    func valuesAfterFinishAreNotObserved() async {
        let upstream = AsyncStream.makeStream(of: String?.self)
        let dataSource = makeFirebaseAuthenticationDataSource(
            observeSession: { firebaseSessionStream(from: upstream.stream) }
        )

        upstream.continuation.yield(nil)
        upstream.continuation.finish()
        upstream.continuation.yield("principal-ignored")

        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(
            await iterator.next()
                == Optional<AuthenticationSession?>.some(nil)
        )
        #expect(await iterator.next() == nil)
    }

    @Test("Concrete adapter and Authentication boundary are Sendable")
    func adapterAndBoundaryAreSendable() {
        let dataSource = makeFirebaseAuthenticationDataSource()

        requireFirebaseAuthenticationSendable(dataSource)
        requireFirebaseAuthenticationDataSourceSendable(dataSource)
    }
}

private struct FirebaseAuthenticationErrorFixture: Sendable,
    CustomTestStringConvertible {
    let name: String
    let code: Int
    let expectedError: AuthenticationDataSourceError

    var testDescription: String { name }
}

private let firebaseAuthenticationErrorFixtures = [
    FirebaseAuthenticationErrorFixture(
        name: "invalidCredential",
        code: AuthErrorCode.invalidCredential.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "invalidEmail",
        code: AuthErrorCode.invalidEmail.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "wrongPassword",
        code: AuthErrorCode.wrongPassword.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "userNotFound",
        code: AuthErrorCode.userNotFound.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "rejectedCredential",
        code: AuthErrorCode.rejectedCredential.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "missingEmail",
        code: AuthErrorCode.missingEmail.rawValue,
        expectedError: .credentialsRejected
    ),
    FirebaseAuthenticationErrorFixture(
        name: "userDisabled",
        code: AuthErrorCode.userDisabled.rawValue,
        expectedError: .accountDisabled
    ),
    FirebaseAuthenticationErrorFixture(
        name: "networkError",
        code: AuthErrorCode.networkError.rawValue,
        expectedError: .networkUnavailable
    ),
    FirebaseAuthenticationErrorFixture(
        name: "tooManyRequests",
        code: AuthErrorCode.tooManyRequests.rawValue,
        expectedError: .rateLimited
    ),
    FirebaseAuthenticationErrorFixture(
        name: "operationNotAllowed",
        code: AuthErrorCode.operationNotAllowed.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "invalidAPIKey",
        code: AuthErrorCode.invalidAPIKey.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "appNotAuthorized",
        code: AuthErrorCode.appNotAuthorized.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "recaptchaNotEnabled",
        code: AuthErrorCode.recaptchaNotEnabled.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "recaptchaSDKNotLinked",
        code: AuthErrorCode.recaptchaSDKNotLinked.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "recaptchaSiteKeyMissing",
        code: AuthErrorCode.recaptchaSiteKeyMissing.rawValue,
        expectedError: .misconfigured
    ),
    FirebaseAuthenticationErrorFixture(
        name: "keychainError",
        code: AuthErrorCode.keychainError.rawValue,
        expectedError: .secureStorageUnavailable
    )
]

private struct FirebaseSignInCredentials: Equatable {
    let email: String
    let password: String
}

private actor FirebaseSignInGate {
    private var credentials: [FirebaseSignInCredentials] = []
    private var receivedWaiters: [CheckedContinuation<Void, Never>] = []
    private var resultContinuation: CheckedContinuation<String, Never>?

    var receivedCredentials: [FirebaseSignInCredentials] { credentials }

    func signIn(email: String, password: String) async -> String {
        credentials.append(
            FirebaseSignInCredentials(email: email, password: password)
        )
        receivedWaiters.forEach { $0.resume() }
        receivedWaiters.removeAll()

        return await withCheckedContinuation { continuation in
            resultContinuation = continuation
        }
    }

    func waitUntilReceived() async {
        guard credentials.isEmpty else { return }
        await withCheckedContinuation { continuation in
            receivedWaiters.append(continuation)
        }
    }

    func succeed(with principalID: String) {
        resultContinuation?.resume(returning: principalID)
        resultContinuation = nil
    }
}

private func makeFirebaseAuthenticationDataSource(
    signIn: @escaping @Sendable (
        String,
        String
    ) async throws -> String = { _, _ in
        throw AuthenticationDataSourceError.unexpected
    },
    signOut: @escaping @Sendable () throws -> Void = {},
    observeSession: @escaping @Sendable () -> AsyncStream<
        AuthenticationSession?
    > = { authenticationSessionStream([]) }
) -> FirebaseAuthenticationDataSource {
    FirebaseAuthenticationDataSource(
        signIn: signIn,
        signOut: signOut,
        observeSession: observeSession
    )
}

private func firebaseSessionStream(
    from upstream: AsyncStream<String?>
) -> AsyncStream<AuthenticationSession?> {
    FirebaseAuthenticationDataSource.sessionStream(
        from: upstream,
        transform: authenticationSession(id:)
    )
}

private func authenticationSession(id principalID: String?)
    -> AuthenticationSession? {
    principalID.map { AuthenticationSession(id: $0) }
}

private func firebasePrincipalStream(
    _ principalIDs: [String?]
) -> AsyncStream<String?> {
    AsyncStream { continuation in
        for principalID in principalIDs {
            continuation.yield(principalID)
        }
        continuation.finish()
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

private func firebaseAuthenticationError(code: Int) -> NSError {
    NSError(domain: AuthErrors.domain, code: code)
}

private func requireFirebaseAuthenticationSendable<Value: Sendable>(
    _ value: Value
) {}

private func requireFirebaseAuthenticationDataSourceSendable(
    _ dataSource: any AuthenticationDataSource
) {
    requireFirebaseAuthenticationSendable(dataSource)
}
