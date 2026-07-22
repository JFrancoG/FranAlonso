struct ObserveClientsUseCase: Sendable {
    private let clientRepository: any ClientRepository

    func callAsFunction() async -> AsyncThrowingStream<[Client], any Error> {
        await clientRepository.observeClients()
    }
}

extension ObserveClientsUseCase {
    init(repository: any ClientRepository) {
        self.init(clientRepository: repository)
    }
}
