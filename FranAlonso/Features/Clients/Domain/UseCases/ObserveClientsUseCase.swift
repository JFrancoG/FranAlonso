struct ObserveClientsUseCase: Sendable {
    private let repository: any ClientRepository

    init(repository: any ClientRepository) {
        self.repository = repository
    }

    func callAsFunction() async -> AsyncThrowingStream<[Client], any Error> {
        await repository.observeClients()
    }
}
