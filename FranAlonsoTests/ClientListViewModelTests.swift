import Foundation
import Testing
@testable import FranAlonso

@Suite("Client list view model")
@MainActor
struct ClientListViewModelTests {
    @Test("Starts idle before loading clients")
    func startsIdleBeforeLoadingClients() {
        let repository = ClientListRepositoryFake(behavior: .clients([]))
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )

        #expect(viewModel.state == .idle)
    }

    @Test("Shows content from the observed client snapshot")
    func showsContentFromTheObservedClientSnapshot() async {
        let expectedClients = [
            Client(
                id: ClientID(
                    rawValue: UUID(
                        uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                    )!
                ),
                displayName: "Ana Alonso"
            )
        ]
        let repository = ClientListRepositoryFake(behavior: .clients(expectedClients))
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.state == .content(expectedClients))
        #expect(await repository.observationCallCount() == 1)
    }

    @Test("Shows an explicit empty state for an empty snapshot")
    func showsAnExplicitEmptyStateForAnEmptySnapshot() async {
        let repository = ClientListRepositoryFake(behavior: .clients([]))
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("Shows an empty state when observation finishes without a snapshot")
    func showsAnEmptyStateWhenObservationFinishesWithoutASnapshot() async {
        let repository = ClientListRepositoryFake(behavior: .finished)
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("Shows failure when client observation throws")
    func showsFailureWhenClientObservationThrows() async {
        let repository = ClientListRepositoryFake(behavior: .failure)
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test("Cancellation leaves the screen idle instead of failed")
    func cancellationLeavesTheScreenIdleInsteadOfFailed() async {
        let repository = ClientListRepositoryFake(behavior: .suspended)
        let viewModel = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: repository)
        )
        let loadingTask = Task {
            await viewModel.load()
        }

        await repository.waitUntilObservationStarts()
        #expect(viewModel.state == .loading)

        loadingTask.cancel()
        await loadingTask.value

        #expect(viewModel.state == .idle)
    }
}

private enum ClientListRepositoryFakeFailure: Error {
    case expected
}

private actor ClientListRepositoryFake: ClientRepository {
    enum Behavior {
        case clients([Client])
        case finished
        case failure
        case suspended
    }

    private let behavior: Behavior
    private var callCount = 0
    private var observationWaiters: [CheckedContinuation<Void, Never>] = []
    private var suspendedContinuation:
        AsyncThrowingStream<[Client], any Error>.Continuation?

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        callCount += 1
        observationWaiters.forEach { $0.resume() }
        observationWaiters.removeAll()

        switch behavior {
        case let .clients(clients):
            return AsyncThrowingStream { continuation in
                continuation.yield(clients)
                continuation.finish()
            }
        case .finished:
            return AsyncThrowingStream { continuation in
                continuation.finish()
            }
        case .failure:
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: ClientListRepositoryFakeFailure.expected)
            }
        case .suspended:
            let (stream, continuation) =
                AsyncThrowingStream<[Client], any Error>.makeStream()
            suspendedContinuation = continuation
            return stream
        }
    }

    func waitUntilObservationStarts() async {
        guard callCount == 0 else {
            return
        }

        await withCheckedContinuation { continuation in
            observationWaiters.append(continuation)
        }
    }

    func observationCallCount() -> Int {
        callCount
    }
}
