protocol ClientRepository: Sendable {
    func observeClients() async -> AsyncThrowingStream<[Client], any Error>
}
