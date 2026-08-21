#if FRANALONSO_AUTH_FIXTURE
import Foundation

/// A deterministic in-process Authentication adapter reserved for the Develop fixture gate.
actor DevelopAuthenticationDataSource: AuthenticationDataSource {
    enum InitialState: Equatable {
        case signedOut
        case restoredSession
    }

    private var currentSession: AuthenticationSession?
    private var observers: [
        UUID: AsyncStream<AuthenticationSession?>.Continuation
    ] = [:]

    var activeObservationCount: Int { observers.count }

    init(initialState: InitialState) {
        currentSession = switch initialState {
        case .signedOut:
            nil
        case .restoredSession:
            AuthenticationSession(id: DevelopAuthenticationFixture.principalID)
        }
    }

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticationSession {
        try Task.checkCancellation()
        guard email == DevelopAuthenticationFixture.email,
              password == DevelopAuthenticationFixture.password
        else {
            throw AuthenticationDataSourceError.credentialsRejected
        }

        let session = AuthenticationSession(
            id: DevelopAuthenticationFixture.principalID
        )
        currentSession = session
        publish(session)
        return session
    }

    func signOut() async throws {
        try Task.checkCancellation()
        currentSession = nil
        publish(nil)
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        let observerID = UUID()
        let pair = AsyncStream<AuthenticationSession?>.makeStream(
            bufferingPolicy: .unbounded
        )
        observers[observerID] = pair.continuation
        pair.continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeObserver(observerID)
            }
        }
        pair.continuation.yield(currentSession)
        return pair.stream
    }

    private func publish(_ session: AuthenticationSession?) {
        for (observerID, continuation) in observers {
            if case .terminated = continuation.yield(session) {
                observers[observerID] = nil
            }
        }
    }

    private func removeObserver(_ observerID: UUID) {
        observers[observerID] = nil
    }
}
#endif
