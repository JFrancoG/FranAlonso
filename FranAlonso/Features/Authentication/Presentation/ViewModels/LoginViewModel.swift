import Observation

/// Coordinates ephemeral credentials into an explicit sign-in intent state.
///
/// A successful intent does not grant protected-root access. The session observation composed in
/// 06.7 remains authoritative for that decision.
@Observable
@MainActor
final class LoginViewModel {
    /// The lifecycle of the current sign-in intent.
    enum State: Equatable {
        case idle
        case loading
        case succeeded(AuthenticationSession)
        case failed(Failure)
    }

    /// Provider-neutral failures that the login screen can present.
    enum Failure: Equatable {
        case credentialsRejected
        case temporarilyUnavailable
        case configuration
        case secureStorageUnavailable
        case unexpected
    }

    var email = ""
    var password = ""
    private(set) var state: State = .idle

    private let signInUseCase: SignInUseCase

    init(signIn: SignInUseCase) {
        signInUseCase = signIn
    }

    /// Submits the current ephemeral credentials unless another intent is already loading.
    ///
    /// The password is cleared only after success. Cooperative cancellation restores `idle`,
    /// while provider failures become stable presentation categories.
    func signIn() async {
        guard state != .loading else { return }

        state = .loading

        do {
            let session = try await signInUseCase(email: email, password: password)
            password = ""
            state = .succeeded(session)
        } catch is CancellationError {
            state = .idle
        } catch let error as AuthenticationError {
            state = .failed(Failure(error))
        } catch {
            state = .failed(.unexpected)
        }
    }

    /// Clears a completed credential intent after authoritative session replacement or logout.
    ///
    /// The email remains available for a retry, while the ephemeral password and terminal state
    /// are discarded.
    func resetForAuthoritativeSessionChange() {
        password = ""
        state = .idle
    }
}

private extension LoginViewModel.Failure {
    init(_ error: AuthenticationError) {
        switch error {
        case .invalidCredentials, .accountDisabled:
            self = .credentialsRejected
        case .temporarilyUnavailable:
            self = .temporarilyUnavailable
        case .configuration:
            self = .configuration
        case .secureStorageUnavailable:
            self = .secureStorageUnavailable
        case .unexpected:
            self = .unexpected
        }
    }
}
