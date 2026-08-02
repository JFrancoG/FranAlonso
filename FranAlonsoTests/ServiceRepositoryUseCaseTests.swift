import Foundation
import Testing
@testable import FranAlonso

@Suite("Service repository use cases")
struct ServiceRepositoryUseCaseTests {
    @Test("Delegates service observation to the repository")
    func delegatesServiceObservationToTheRepository() async throws {
        let service = try repositoryService()
        let repository = ServiceRepositoryFake(services: [service])
        let useCase = ObserveServicesUseCase(repository: repository)

        let stream = await useCase()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [service])
        #expect(try await iterator.next() == nil)
        #expect(await repository.observationCallCount() == 1)
        requireServiceUseCaseSendable(useCase)
    }

    @Test("Delegates local service persistence to the repository")
    func delegatesLocalServicePersistenceToTheRepository() async throws {
        let service = try repositoryService()
        let repository = ServiceRepositoryFake(services: [])
        let useCase = SaveServiceUseCase(repository: repository)

        try await useCase(service)

        #expect(await repository.savedServices() == [service])
        #expect(await repository.saveCallCount() == 1)
        requireServiceUseCaseSendable(useCase)
    }
}

private actor ServiceRepositoryFake: ServiceRepository {
    private let services: [Service]
    private var observationCalls = 0
    private var saveCalls = 0
    private var persistedServices: [Service] = []

    init(services: [Service]) {
        self.services = services
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        observationCalls += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(services)
            continuation.finish()
        }
    }

    func saveService(_ service: Service) async throws {
        saveCalls += 1
        persistedServices.append(service)
    }

    func observationCallCount() -> Int { observationCalls }

    func saveCallCount() -> Int { saveCalls }

    func savedServices() -> [Service] { persistedServices }
}

private func repositoryService() throws -> Service {
    try Service(
        id: ServiceID(
            rawValue: UUID(
                uuidString: "20000000-2000-2000-2000-200000000001"
            )!
        ),
        name: "Corte",
        type: .professional,
        price: Money(amount: 25, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        status: .active
    )
}

private func requireServiceUseCaseSendable<Value: Sendable>(_ value: Value) {}
