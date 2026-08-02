import Testing
@testable import FranAlonso

@Suite("Local principal authorization")
struct LocalPrincipalAuthorizationTests {
    @Test("The use case delegates the opaque observed principal")
    func useCaseDelegatesOpaqueObservedPrincipal() async throws {
        let recorder = LocalPrincipalAuthorizationRecorder()
        let authorizer = LocalPrincipalAuthorizer { session in
            await recorder.record(session)
        }
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: authorizer)
        let session = AuthenticationSession(id: "principal-authorized")

        try await useCase(session: session)

        #expect(await recorder.sessions == [session])
    }

    @Test("The use case preserves a closed authorization failure")
    func useCasePreservesClosedAuthorizationFailure() async {
        let authorizer = LocalPrincipalAuthorizer { _ in
            throw LocalPrincipalAuthorizationError.differentPrincipal
        }
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: authorizer)

        await #expect(throws: LocalPrincipalAuthorizationError.differentPrincipal) {
            try await useCase(session: AuthenticationSession(id: "principal-denied"))
        }
    }

    @Test("Cancellation wins before local authorization starts")
    func cancellationWinsBeforeLocalAuthorizationStarts() async {
        let recorder = LocalPrincipalAuthorizationRecorder()
        let authorizer = LocalPrincipalAuthorizer { session in
            await recorder.record(session)
        }
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: authorizer)
        let task = Task {
            try await useCase(session: AuthenticationSession(id: "principal-cancelled"))
        }

        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await recorder.sessions.isEmpty)
    }
}

private actor LocalPrincipalAuthorizationRecorder {
    private(set) var sessions: [AuthenticationSession] = []

    func record(_ session: AuthenticationSession) {
        sessions.append(session)
    }
}
