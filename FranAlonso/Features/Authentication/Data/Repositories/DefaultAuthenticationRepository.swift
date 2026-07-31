/// Provides Authentication Domain access through a replaceable infrastructure boundary.
///
/// The repository translates provider-neutral infrastructure failures into stable Domain errors.
/// Session observation is returned directly so the DataSource retains transition ordering and
/// provider-lifecycle ownership.
struct DefaultAuthenticationRepository: AuthenticationRepository {
    private let authenticationDataSource: any AuthenticationDataSource

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticationSession {
        do {
            return try await authenticationDataSource.signIn(
                email: email,
                password: password
            )
        } catch let error as CancellationError {
            throw error
        } catch let error as AuthenticationDataSourceError {
            throw error.authenticationError
        } catch {
            throw AuthenticationError.unexpected
        }
    }

    func signOut() async throws {
        do {
            try await authenticationDataSource.signOut()
        } catch let error as CancellationError {
            throw error
        } catch let error as AuthenticationDataSourceError {
            throw error.authenticationError
        } catch {
            throw AuthenticationError.unexpected
        }
    }

    func observeSession() async -> AsyncStream<AuthenticationSession?> {
        await authenticationDataSource.observeSession()
    }
}

extension DefaultAuthenticationRepository {
    /// Creates the Repository with its replaceable Authentication infrastructure boundary.
    ///
    /// - Parameter dataSource: The provider-neutral source for authentication operations.
    init(dataSource: any AuthenticationDataSource) {
        self.init(authenticationDataSource: dataSource)
    }
}

private extension AuthenticationDataSourceError {
    /// Converts infrastructure meaning into the stable failure exposed by Domain.
    var authenticationError: AuthenticationError {
        switch self {
        case .credentialsRejected:
            .invalidCredentials
        case .accountDisabled:
            .accountDisabled
        case .networkUnavailable, .rateLimited:
            .temporarilyUnavailable
        case .misconfigured:
            .configuration
        case .secureStorageUnavailable:
            .secureStorageUnavailable
        case .unexpected:
            .unexpected
        }
    }
}
