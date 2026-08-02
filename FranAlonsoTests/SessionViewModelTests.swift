import Synchronization
import Testing
@testable import FranAlonso

@Suite("Session view model")
@MainActor
struct SessionViewModelTests {
    @Test("Starts with idle session and action states")
    func startsWithIdleSessionAndActionStates() {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)

        #expect(viewModel.state == .idle)
        #expect(viewModel.actionState == .idle)
    }

    @Test("An observed nil session is authoritative signed out state")
    func observedNilSessionIsAuthoritativeSignedOutState() async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)

        await repository.waitUntilObservationCount(1)
        await repository.emit(nil)
        await waitUntil { viewModel.state == .signedOut }

        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("A new principal locks with a fresh available biometric query")
    func newPrincipalLocksWithFreshAvailableBiometricQuery() async {
        await confirmation("Availability is queried for each new principal", expectedCount: 2) { queried in
            let repository = SessionAuthenticationRepositoryFake()
            let authenticator = BiometricAuthenticator(
                canAuthenticate: {
                    queried()
                    return true
                },
                authenticate: { _ in }
            )
            let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
            let observation = startObservation(viewModel)
            let firstSession = AuthenticationSession(id: "principal-session-first")
            let secondSession = AuthenticationSession(id: "principal-session-second")

            await repository.waitUntilObservationCount(1)
            await repository.emit(firstSession)
            await waitUntil { viewModel.state == .locked(firstSession, .available) }

            await repository.emit(secondSession)
            await waitUntil { viewModel.state == .locked(secondSession, .available) }

            await cancelAndWait(observation)
        }
    }

    @Test("Unavailable biometrics keep the observed principal locked")
    func unavailableBiometricsKeepObservedPrincipalLocked() async {
        let repository = SessionAuthenticationRepositoryFake()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { false },
            authenticate: { _ in }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-unavailable")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .unavailable) }

        await cancelAndWait(observation)
    }

    @Test("Biometric availability is refreshed for every unlock attempt")
    func biometricAvailabilityIsRefreshedForEveryUnlockAttempt() async {
        let repository = SessionAuthenticationRepositoryFake()
        let availability = Mutex(true)
        let authorizationCount = Mutex(0)
        let authenticator = BiometricAuthenticator(
            canAuthenticate: {
                availability.withLock { $0 }
            },
            authenticate: { _ in
                authorizationCount.withLock { $0 += 1 }
            }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-changing-availability")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }

        availability.withLock { $0 = false }
        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")

        #expect(viewModel.state == .locked(session, .unavailable))
        #expect(viewModel.actionState == .failed(.biometricUnavailable))
        #expect(authorizationCount.withLock { $0 } == 0)

        availability.withLock { $0 = true }
        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")

        #expect(viewModel.state == .unlocked(session))
        #expect(viewModel.actionState == .idle)
        #expect(authorizationCount.withLock { $0 } == 1)
        await cancelAndWait(observation)
    }

    @Test("The same observed principal preserves an unlocked session")
    func sameObservedPrincipalPreservesUnlockedSession() async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-preserved")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        #expect(viewModel.state == .unlocked(session))

        #expect(await repository.emitAndWaitUntilConsumed(session))

        #expect(viewModel.state == .unlocked(session))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("Cancelling the active observation restores idle")
    func cancellingActiveObservationRestoresIdle() async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)

        await repository.waitUntilObservationCount(1)
        #expect(viewModel.state == .loading)

        await cancelAndWait(observation)

        #expect(viewModel.state == .idle)
        #expect(viewModel.actionState == .idle)
    }

    @Test("An active observation that finishes unexpectedly reports failure")
    func activeObservationThatFinishesUnexpectedlyReportsFailure() async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)

        await repository.waitUntilObservationCount(1)
        await repository.finishObservation()
        await observation.value

        #expect(viewModel.state == .failed(.observationEnded))
        #expect(viewModel.actionState == .idle)
    }

    @Test(
        "An obsolete observation cannot overwrite its replacement",
        arguments: ObsoleteObservationEvent.allCases
    )
    fileprivate func obsoleteObservationCannotOverwriteReplacement(_ event: ObsoleteObservationEvent) async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let firstObservation = startObservation(viewModel)

        await repository.waitUntilObservationCount(1)
        let replacementObservation = startObservation(viewModel)
        await repository.waitUntilObservationCount(2)
        let currentSession = AuthenticationSession(id: "principal-session-current")
        await repository.emit(currentSession, observation: 1)
        await waitUntil { viewModel.state == .locked(currentSession, .available) }

        switch event {
        case .emits:
            await repository.emit(
                AuthenticationSession(id: "principal-session-obsolete"),
                observation: 0
            )
        case .finishes:
            await repository.finishObservation(0)
        case .cancels:
            firstObservation.cancel()
        }
        await firstObservation.value

        #expect(viewModel.state == .locked(currentSession, .available))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(replacementObservation)
    }

    @Test(
        "Observation invalidation makes a suspended action completion stale",
        arguments: ObservationInvalidationEvent.allCases
    )
    fileprivate func observationInvalidationMakesSuspendedActionCompletionStale(
        _ event: ObservationInvalidationEvent
    ) async {
        let repository = SessionAuthenticationRepositoryFake()
        let gate = SessionOperationGate()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in await gate.wait() }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-observation-invalidated")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        let unlock = Task { @MainActor in
            await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        }
        await gate.waitUntilBlocked()

        var replacementObservation: Task<Void, Never>?
        switch event {
        case .replacement:
            replacementObservation = startObservation(viewModel)
            await repository.waitUntilObservationCount(2)
            await waitUntil { viewModel.state == .loading }
        case .finish:
            await repository.finishObservation()
            await observation.value
            #expect(viewModel.state == .failed(.observationEnded))
        case .cancellation:
            observation.cancel()
            await observation.value
            #expect(viewModel.state == .idle)
        }
        let stateAfterInvalidation = viewModel.state
        #expect(viewModel.actionState == .idle)

        await gate.release()
        await unlock.value

        #expect(viewModel.state == stateAfterInvalidation)
        #expect(viewModel.actionState == .idle)
        if let replacementObservation {
            await cancelAndWait(replacementObservation)
            await cancelAndWait(observation)
        }
    }

    @Test(
        "Biometric failures preserve the lock and map to action failures",
        arguments: [
            BiometricActionFailureFixture(error: .denied, expected: .biometricDenied),
            BiometricActionFailureFixture(error: .cancelled, expected: .biometricCancelled),
            BiometricActionFailureFixture(error: .unavailable, expected: .biometricUnavailable),
            BiometricActionFailureFixture(error: .configuration, expected: .configuration),
            BiometricActionFailureFixture(error: .unexpected, expected: .unexpected)
        ]
    )
    fileprivate func biometricFailuresPreserveLockAndMapToActionFailures(
        _ fixture: BiometricActionFailureFixture
    ) async {
        let repository = SessionAuthenticationRepositoryFake()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in throw fixture.error }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-biometric-failure")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }

        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")

        #expect(viewModel.state == .locked(session, .available))
        #expect(viewModel.actionState == .failed(fixture.expected))
        await cancelAndWait(observation)
    }

    @Test("Swift cancellation of biometric authorization clears only the action state")
    func swiftCancellationOfBiometricAuthorizationClearsOnlyActionState() async {
        let repository = SessionAuthenticationRepositoryFake()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in throw CancellationError() }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-biometric-cancel")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }

        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")

        #expect(viewModel.state == .locked(session, .available))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("A suspended unlock ignores duplicates and sign out crossings")
    func suspendedUnlockIgnoresDuplicatesAndSignOutCrossings() async {
        let repository = SessionAuthenticationRepositoryFake()
        let gate = SessionOperationGate()
        let invocationProbe = BiometricInvocationProbe()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in
                await invocationProbe.recordInvocation()
                await gate.wait()
            }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-unlock-crossing")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        let unlock = Task { @MainActor in
            await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        }
        await gate.waitUntilBlocked()

        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        await viewModel.signOut()

        #expect(viewModel.actionState == .unlocking)
        #expect(await invocationProbe.invocationCount() == 1)
        #expect(await repository.signOutCallCount() == 0)
        await gate.release()
        await unlock.value
        #expect(viewModel.state == .unlocked(session))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("The same principal preserves an active unlock attempt")
    func samePrincipalPreservesActiveUnlockAttempt() async {
        let repository = SessionAuthenticationRepositoryFake()
        let gate = SessionOperationGate()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in await gate.wait() }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-active-unlock")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        let unlock = Task { @MainActor in
            await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        }
        await gate.waitUntilBlocked()

        #expect(await repository.emitAndWaitUntilConsumed(session))

        #expect(viewModel.state == .locked(session, .available))
        #expect(viewModel.actionState == .unlocking)
        await gate.release()
        await unlock.value
        #expect(viewModel.state == .unlocked(session))
        await cancelAndWait(observation)
    }

    @Test("A new principal invalidates a suspended unlock completion")
    func newPrincipalInvalidatesSuspendedUnlockCompletion() async {
        let repository = SessionAuthenticationRepositoryFake()
        let gate = SessionOperationGate()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in await gate.wait() }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let oldSession = AuthenticationSession(id: "principal-session-old")
        let newSession = AuthenticationSession(id: "principal-session-new")

        await repository.waitUntilObservationCount(1)
        await repository.emit(oldSession)
        await waitUntil { viewModel.state == .locked(oldSession, .available) }
        let unlock = Task { @MainActor in
            await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        }
        await gate.waitUntilBlocked()

        await repository.emit(newSession)
        await waitUntil { viewModel.state == .locked(newSession, .available) }
        await gate.release()
        await unlock.value

        #expect(viewModel.state == .locked(newSession, .available))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("Sign out success waits for authoritative nil before becoming signed out")
    func signOutSuccessWaitsForAuthoritativeNil() async {
        let repository = SessionAuthenticationRepositoryFake()
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-sign-out")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")
        #expect(viewModel.state == .unlocked(session))

        await viewModel.signOut()

        #expect(viewModel.state == .unlocked(session))
        #expect(viewModel.actionState == .signingOut)
        await repository.emit(nil)
        await waitUntil { viewModel.state == .signedOut }
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test(
        "Sign out failures map to stable action categories",
        arguments: [
            SignOutActionFailureFixture(error: .temporarilyUnavailable, expected: .temporarilyUnavailable),
            SignOutActionFailureFixture(error: .configuration, expected: .configuration),
            SignOutActionFailureFixture(error: .secureStorageUnavailable, expected: .secureStorageUnavailable),
            SignOutActionFailureFixture(error: .unexpected, expected: .unexpected),
            SignOutActionFailureFixture(error: .invalidCredentials, expected: .unexpected),
            SignOutActionFailureFixture(error: .accountDisabled, expected: .unexpected)
        ]
    )
    fileprivate func signOutFailuresMapToStableActionCategories(_ fixture: SignOutActionFailureFixture) async {
        let repository = SessionAuthenticationRepositoryFake(signOutBehavior: .fails(fixture.error))
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-sign-out-failure")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }

        await viewModel.signOut()

        #expect(viewModel.state == .locked(session, .available))
        #expect(viewModel.actionState == .failed(fixture.expected))
        await cancelAndWait(observation)
    }

    @Test("Sign out cancellation clears the action without changing the observed session")
    func signOutCancellationClearsActionWithoutChangingObservedSession() async {
        let repository = SessionAuthenticationRepositoryFake(signOutBehavior: .cancels)
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-sign-out-cancel")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }

        await viewModel.signOut()

        #expect(viewModel.state == .locked(session, .available))
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }

    @Test("A suspended sign out ignores duplicates and unlock crossings")
    func suspendedSignOutIgnoresDuplicatesAndUnlockCrossings() async {
        let gate = SessionOperationGate()
        let repository = SessionAuthenticationRepositoryFake(signOutBehavior: .waits(gate))
        let invocationProbe = BiometricInvocationProbe()
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in await invocationProbe.recordInvocation() }
        )
        let viewModel = makeSessionViewModel(repository: repository, authenticator: authenticator)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-sign-out-crossing")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        let signOut = Task { @MainActor in
            await viewModel.signOut()
        }
        await gate.waitUntilBlocked()

        await viewModel.signOut()
        await viewModel.unlock(localizedReason: "Desbloquea tu sesión")

        #expect(viewModel.actionState == .signingOut)
        #expect(await repository.signOutCallCount() == 1)
        #expect(await invocationProbe.invocationCount() == 0)
        await gate.release()
        await signOut.value
        #expect(viewModel.actionState == .signingOut)
        await repository.emit(nil)
        await waitUntil { viewModel.state == .signedOut }
        await cancelAndWait(observation)
    }

    @Test("An observed nil invalidates a suspended sign out completion")
    func observedNilInvalidatesSuspendedSignOutCompletion() async {
        let gate = SessionOperationGate()
        let repository = SessionAuthenticationRepositoryFake(signOutBehavior: .waits(gate))
        let viewModel = makeSessionViewModel(repository: repository)
        let observation = startObservation(viewModel)
        let session = AuthenticationSession(id: "principal-session-sign-out-nil")

        await repository.waitUntilObservationCount(1)
        await repository.emit(session)
        await waitUntil { viewModel.state == .locked(session, .available) }
        let signOut = Task { @MainActor in
            await viewModel.signOut()
        }
        await gate.waitUntilBlocked()

        await repository.emit(nil)
        await waitUntil { viewModel.state == .signedOut }
        await gate.release()
        await signOut.value

        #expect(viewModel.state == .signedOut)
        #expect(viewModel.actionState == .idle)
        await cancelAndWait(observation)
    }
}

private struct BiometricActionFailureFixture {
    let error: BiometricAuthenticationError
    let expected: SessionViewModel.ActionFailure
}

private struct SignOutActionFailureFixture {
    let error: AuthenticationError
    let expected: SessionViewModel.ActionFailure
}

private enum ObsoleteObservationEvent: CaseIterable {
    case emits
    case finishes
    case cancels
}

private enum ObservationInvalidationEvent: CaseIterable {
    case replacement
    case finish
    case cancellation
}

private enum SessionSignOutBehavior {
    case succeeds
    case fails(AuthenticationError)
    case waits(SessionOperationGate)
    case cancels
}

private actor SessionObservationChannel {
    private struct QueuedObservation {
        let sequence: Int
        let session: AuthenticationSession?
    }

    private var queuedObservations: [QueuedObservation] = []
    private var nextWaiter: CheckedContinuation<AuthenticationSession??, Never>?
    private var nextSequence = 0
    private var deliveredSequence: Int?
    private var consumedSequence = 0
    private var consumptionWaiters: [(sequence: Int, continuation: CheckedContinuation<Bool, Never>)] = []
    private var isFinished = false

    func next() async -> AuthenticationSession?? {
        acknowledgeDeliveredObservation()

        if !queuedObservations.isEmpty {
            let observation = queuedObservations.removeFirst()
            deliveredSequence = observation.sequence
            return .some(observation.session)
        }
        guard !isFinished else { return nil }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(returning: nil)
                    return
                }
                nextWaiter = continuation
            }
        } onCancel: {
            Task {
                await self.cancel()
            }
        }
    }

    func enqueue(_ session: AuthenticationSession?) -> Int? {
        guard !isFinished else { return nil }

        nextSequence += 1
        let observation = QueuedObservation(sequence: nextSequence, session: session)
        if let nextWaiter {
            self.nextWaiter = nil
            deliveredSequence = observation.sequence
            nextWaiter.resume(returning: .some(observation.session))
        } else {
            queuedObservations.append(observation)
        }
        return observation.sequence
    }

    func waitUntilConsumed(_ sequence: Int) async -> Bool {
        guard consumedSequence < sequence else { return true }
        guard !isFinished else { return false }

        return await withCheckedContinuation { continuation in
            consumptionWaiters.append((sequence, continuation))
        }
    }

    func finish() {
        guard !isFinished else { return }

        isFinished = true
        nextWaiter?.resume(returning: nil)
        nextWaiter = nil
        resumeConsumptionWaitersAfterFinish()
    }

    private func cancel() {
        finish()
    }

    private func acknowledgeDeliveredObservation() {
        guard let deliveredSequence else { return }

        consumedSequence = max(consumedSequence, deliveredSequence)
        self.deliveredSequence = nil
        let readyWaiters = consumptionWaiters.filter { $0.sequence <= consumedSequence }
        consumptionWaiters.removeAll { $0.sequence <= consumedSequence }
        readyWaiters.forEach { $0.continuation.resume(returning: true) }
    }

    private func resumeConsumptionWaitersAfterFinish() {
        let waiters = consumptionWaiters
        consumptionWaiters.removeAll()
        waiters.forEach { waiter in
            waiter.continuation.resume(returning: waiter.sequence <= consumedSequence)
        }
    }
}

private actor SessionAuthenticationRepositoryFake: AuthenticationRepository {
    private let signOutBehavior: SessionSignOutBehavior
    private var signOutCalls = 0
    private var observationCount = 0
    private var observationChannels: [Int: SessionObservationChannel] = [:]
    private var observationWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(signOutBehavior: SessionSignOutBehavior = .succeeds) {
        self.signOutBehavior = signOutBehavior
    }

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        throw AuthenticationError.unexpected
    }

    func signOut() async throws {
        signOutCalls += 1

        switch signOutBehavior {
        case .succeeds:
            return
        case let .fails(error):
            throw error
        case let .waits(gate):
            await gate.wait()
        case .cancels:
            throw CancellationError()
        }
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        let index = observationCount
        observationCount += 1
        let channel = SessionObservationChannel()
        observationChannels[index] = channel

        let readyWaiters = observationWaiters.filter { $0.count <= observationCount }
        observationWaiters.removeAll { $0.count <= observationCount }
        readyWaiters.forEach { $0.continuation.resume() }
        return AsyncStream(unfolding: {
            await channel.next()
        })
    }

    func emit(_ session: AuthenticationSession?, observation: Int = 0) async {
        _ = await observationChannels[observation]?.enqueue(session)
    }

    func emitAndWaitUntilConsumed(_ session: AuthenticationSession?, observation: Int = 0) async -> Bool {
        guard let channel = observationChannels[observation], let sequence = await channel.enqueue(session) else {
            return false
        }

        return await channel.waitUntilConsumed(sequence)
    }

    func finishObservation(_ observation: Int = 0) async {
        await observationChannels[observation]?.finish()
        observationChannels[observation] = nil
    }

    func waitUntilObservationCount(_ expectedCount: Int) async {
        guard observationCount < expectedCount else { return }

        await withCheckedContinuation { continuation in
            observationWaiters.append((expectedCount, continuation))
        }
    }

    func signOutCallCount() -> Int { signOutCalls }
}

private actor SessionOperationGate {
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

private actor BiometricInvocationProbe {
    private var count = 0

    func recordInvocation() {
        count += 1
    }

    func invocationCount() -> Int { count }
}

@MainActor
private func makeSessionViewModel(
    repository: SessionAuthenticationRepositoryFake,
    authenticator: BiometricAuthenticator = BiometricAuthenticator(
        canAuthenticate: { true },
        authenticate: { _ in }
    )
) -> SessionViewModel {
    SessionViewModel(
        observeSession: ObserveSessionUseCase(repository: repository),
        signOut: SignOutUseCase(repository: repository),
        biometricAuthenticator: authenticator
    )
}

@MainActor
private func startObservation(_ viewModel: SessionViewModel) -> Task<Void, Never> {
    Task { @MainActor in
        await viewModel.load()
    }
}

@MainActor
private func cancelAndWait(_ task: Task<Void, Never>) async {
    task.cancel()
    await task.value
}

@MainActor
private func waitUntil(
    _ condition: @MainActor () -> Bool
) async {
    for _ in 0..<10_000 {
        if condition() {
            return
        }
        await Task.yield()
    }

    Issue.record("Expected main-actor state transition did not occur")
}
