import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale repository use cases")
struct SaleRepositoryUseCaseTests {
    @Test("Delegates sale observation to the repository")
    func delegatesSaleObservationToTheRepository() async throws {
        let sale = try repositorySale()
        let repository = SaleRepositoryFake(sales: [sale])
        let useCase = ObserveSalesUseCase(repository: repository)

        let stream = await useCase()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [sale])
        #expect(try await iterator.next() == nil)
        #expect(await repository.observationCallCount() == 1)
        requireSaleUseCaseSendable(useCase)
    }

    @Test("Delegates local sale persistence to the repository")
    func delegatesLocalSalePersistenceToTheRepository() async throws {
        let sale = try repositorySale()
        let repository = SaleRepositoryFake(sales: [])
        let useCase = SaveSaleUseCase(repository: repository)

        try await useCase(sale)

        #expect(await repository.savedSales() == [sale])
        #expect(await repository.saveCallCount() == 1)
        requireSaleUseCaseSendable(useCase)
    }

    @Test("Propagates a local persistence failure")
    func propagatesALocalPersistenceFailure() async throws {
        let sale = try repositorySale()
        let repository = SaleRepositoryFake(
            sales: [],
            saveError: .rejected
        )
        let useCase = SaveSaleUseCase(repository: repository)

        await #expect(throws: RepositoryUseCaseTestError.rejected) {
            try await useCase(sale)
        }
        #expect(await repository.saveCallCount() == 1)
    }
}

private enum RepositoryUseCaseTestError: Error, Equatable {
    case rejected
}

private actor SaleRepositoryFake: SaleRepository {
    private let sales: [Sale]
    private let saveError: RepositoryUseCaseTestError?
    private var observationCalls = 0
    private var saveCalls = 0
    private var persistedSales: [Sale] = []

    init(sales: [Sale], saveError: RepositoryUseCaseTestError? = nil) {
        self.sales = sales
        self.saveError = saveError
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        observationCalls += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(sales)
            continuation.finish()
        }
    }

    func saveSale(_ sale: Sale) async throws {
        saveCalls += 1
        if let saveError {
            throw saveError
        }
        persistedSales.append(sale)
    }

    func observationCallCount() -> Int { observationCalls }

    func saveCallCount() -> Int { saveCalls }

    func savedSales() -> [Sale] { persistedSales }
}

private func repositorySale() throws -> Sale {
    try Sale.draft(
        id: SaleID(
            rawValue: UUID(
                uuidString: "30000000-3000-3000-3000-300000000001"
            )!
        ),
        clientID: nil,
        createdAt: Date(timeIntervalSince1970: 1_800_000_000),
        lines: []
    )
}

private func requireSaleUseCaseSendable<Value: Sendable>(_ value: Value) {}
