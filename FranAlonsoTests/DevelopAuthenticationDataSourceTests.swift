import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Develop authentication data source")
struct DevelopAuthenticationDataSourceTests {
    @Test(
        "The first observation reflects the selected deterministic mode",
        arguments: [
            (
                DevelopAuthenticationDataSource.InitialState.signedOut,
                Optional<AuthenticationSession>.none
            ),
            (
                .restoredSession,
                AuthenticationSession(id: DevelopAuthenticationFixture.principalID)
            )
        ]
    )
    func initialObservationReflectsMode(
        initialState: DevelopAuthenticationDataSource.InitialState,
        expectedSession: AuthenticationSession?
    ) async {
        let dataSource = DevelopAuthenticationDataSource(initialState: initialState)
        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next() == .some(expectedSession))
    }

    @Test("Only the exact fake credential signs in and publishes the same session")
    func exactCredentialSignsInAndPublishesSession() async throws {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)
        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next() == .some(nil))

        let session = try await dataSource.signIn(
            email: DevelopAuthenticationFixture.email,
            password: DevelopAuthenticationFixture.password
        )

        #expect(session == AuthenticationSession(id: DevelopAuthenticationFixture.principalID))
        #expect(await iterator.next() == .some(session))
    }

    @Test("Rejected credentials never mutate the authoritative stream")
    func rejectedCredentialsDoNotMutateStream() async {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)

        await #expect(throws: AuthenticationDataSourceError.credentialsRejected) {
            try await dataSource.signIn(
                email: DevelopAuthenticationFixture.email,
                password: "not-the-fixture-password"
            )
        }

        let stream = await dataSource.observeSession()
        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next() == .some(nil))
    }

    @Test("Independent observers receive every transition in source order")
    func independentObserversReceiveEveryOrderedTransition() async throws {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)
        let firstStream = await dataSource.observeSession()
        let secondStream = await dataSource.observeSession()
        var first = firstStream.makeAsyncIterator()
        var second = secondStream.makeAsyncIterator()
        let session = try await dataSource.signIn(
            email: DevelopAuthenticationFixture.email,
            password: DevelopAuthenticationFixture.password
        )
        try await dataSource.signOut()

        #expect(await first.next() == .some(nil))
        #expect(await first.next() == .some(session))
        #expect(await first.next() == .some(nil))
        #expect(await second.next() == .some(nil))
        #expect(await second.next() == .some(session))
        #expect(await second.next() == .some(nil))
    }

    @Test("Consumer cancellation releases its observer without affecting another")
    func cancellationReleasesOnlyTheCancelledObserver() async {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)
        let cancelledStream = await dataSource.observeSession()
        let survivingStream = await dataSource.observeSession()
        #expect(await dataSource.activeObservationCount == 2)

        let pendingIteration = Task {
            var iterator = cancelledStream.makeAsyncIterator()
            _ = await iterator.next()
            return await iterator.next()
        }
        await Task.yield()
        pendingIteration.cancel()
        _ = await pendingIteration.value
        await waitUntil { await dataSource.activeObservationCount == 1 }

        var survivingIterator = survivingStream.makeAsyncIterator()
        #expect(await survivingIterator.next() == .some(nil))
        #expect(await dataSource.activeObservationCount == 1)
    }

    @Test("A stream abandoned before iteration releases its continuation")
    func abandonedStreamReleasesContinuation() async {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)
        var stream: AsyncStream<AuthenticationSession?>? = await dataSource.observeSession()
        #expect(stream != nil)
        #expect(await dataSource.activeObservationCount == 1)

        stream = nil

        await waitUntil { await dataSource.activeObservationCount == 0 }
    }

    @Test("Breaking iteration releases only that observer")
    func breakingIterationReleasesOnlyThatObserver() async {
        let dataSource = DevelopAuthenticationDataSource(initialState: .signedOut)
        var survivingStream: AsyncStream<AuthenticationSession?>? = await dataSource.observeSession()
        do {
            let endingStream = await dataSource.observeSession()
            #expect(await dataSource.activeObservationCount == 2)
            await consumeFirstValueAndStop(endingStream)
        }
        await waitUntil { await dataSource.activeObservationCount == 1 }

        var survivingIterator = survivingStream?.makeAsyncIterator()
        #expect(await survivingIterator?.next() == .some(nil))
        survivingStream = nil
        survivingIterator = nil
        await waitUntil { await dataSource.activeObservationCount == 0 }
    }
}

private func consumeFirstValueAndStop(
    _ stream: AsyncStream<AuthenticationSession?>
) async {
    for await _ in stream {
        break
    }
}

private func waitUntil(
    _ condition: @escaping @Sendable () async -> Bool
) async {
    for _ in 0..<10_000 {
        if await condition() {
            return
        }
        await Task.yield()
    }

    Issue.record("Expected fixture observation transition did not occur")
}
#endif
