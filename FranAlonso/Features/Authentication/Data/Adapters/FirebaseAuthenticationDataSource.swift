import FirebaseAuth
import Foundation

/// Adapts Firebase Auth operations to the provider-neutral Authentication boundary.
///
/// Credentials are forwarded ephemerally and never retained. Provider identities are reduced to
/// opaque `AuthenticationSession` values before leaving the Data adapter boundary.
struct FirebaseAuthenticationDataSource: AuthenticationDataSource {
    private let signInOperation: @Sendable (String, String) async throws -> String
    private let signOutOperation: @Sendable () throws -> Void
    private let makeSessionStream: @Sendable () -> AsyncStream<AuthenticationSession?>

    func signIn(email: String, password: String) async throws -> AuthenticationSession {
        do {
            let principalID = try await signInOperation(email, password)
            return AuthenticationSession(id: principalID)
        } catch let error as CancellationError {
            throw error
        } catch {
            throw Self.authenticationError(from: error)
        }
    }

    @concurrent
    func signOut() async throws {
        do {
            try signOutOperation()
        } catch let error as CancellationError {
            throw error
        } catch {
            throw Self.authenticationError(from: error)
        }
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        makeSessionStream()
    }
}

extension FirebaseAuthenticationDataSource {
    /// Creates the live adapter after the default Firebase app has been configured.
    ///
    /// Construction resolves the process-wide `Auth` instance. Callers must therefore defer this
    /// initializer until `FirebaseApp.configure()` has succeeded.
    init() {
        let auth = Auth.auth()

        self.init(
            signIn: { email, password in
                let result = try await auth.signIn(
                    withEmail: email,
                    password: password
                )
                return result.user.uid
            },
            signOut: {
                try auth.signOut()
            },
            observeSession: {
                Self.sessionStream(
                    from: auth.authStateChanges,
                    transform: { user in
                        user.map { AuthenticationSession(id: $0.uid) }
                    }
                )
            }
        )
    }

    /// Creates an adapter from deterministic provider operations.
    ///
    /// The closures must be safe to invoke from any concurrency domain. The sign-in operation
    /// returns only the provider principal identifier; credentials remain operation arguments.
    init(
        signIn: @escaping @Sendable (
            String,
            String
        ) async throws -> String,
        signOut: @escaping @Sendable () throws -> Void,
        observeSession: @escaping @Sendable () -> AsyncStream<
            AuthenticationSession?
        >
    ) {
        signInOperation = signIn
        signOutOperation = signOut
        makeSessionStream = observeSession
    }

    /// Relays a provider sequence into the lossless stream required by Authentication.
    ///
    /// Source order and natural completion are preserved. Releasing or cancelling the returned
    /// stream cancels the relay task, which releases the upstream iterator and its listener.
    static func sessionStream<States>(
        from states: States,
        transform: @escaping @Sendable (
            States.Element
        ) -> AuthenticationSession?
    ) -> AsyncStream<AuthenticationSession?>
    where States: AsyncSequence & Sendable, States.Failure == Never {
        AsyncStream { continuation in
            let relayTask = Task { @concurrent in
                for await state in states {
                    continuation.yield(transform(state))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                relayTask.cancel()
            }
        }
    }
}

private extension FirebaseAuthenticationDataSource {
    /// Converts Firebase's unstable error surface into the stable DataSource contract.
    static func authenticationError(from error: any Error) -> AuthenticationDataSourceError {
        let providerError = error as NSError
        guard providerError.domain == AuthErrors.domain,
              let code = AuthErrorCode(rawValue: providerError.code) else {
            return .unexpected
        }

        return switch code {
        case .invalidCredential,
             .invalidEmail,
             .wrongPassword,
             .userNotFound,
             .rejectedCredential,
             .missingEmail:
            .credentialsRejected
        case .userDisabled:
            .accountDisabled
        case .networkError:
            .networkUnavailable
        case .tooManyRequests:
            .rateLimited
        case .operationNotAllowed,
             .invalidAPIKey,
             .appNotAuthorized,
             .recaptchaNotEnabled,
             .recaptchaSDKNotLinked,
             .recaptchaSiteKeyMissing:
            .misconfigured
        case .keychainError:
            .secureStorageUnavailable
        default:
            .unexpected
        }
    }
}
