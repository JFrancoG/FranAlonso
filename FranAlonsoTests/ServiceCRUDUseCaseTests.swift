import Foundation
import Testing
@testable import FranAlonso

@Suite("Service CRUD and search")
struct ServiceCRUDUseCaseTests {
    @Test(arguments: [ServiceType.professional, .product])
    func `creation normalizes exterior whitespace and reads both commercial types`(_ type: ServiceType) async throws {
        let repository = InMemoryServiceRepository()
        let profile = try serviceCRUDProfile(name: "  Corte  suave \n", type: type)
        let id = serviceCRUDID(1)

        _ = try await CreateServiceUseCase(repository: repository)(id: id, profile: profile)
        let reopened = try #require(try await GetServiceUseCase(repository: repository)(id))

        #expect(reopened == (try makeService(
            id: id.rawValue,
            name: "Corte  suave",
            type: type,
            linkedProductID: type == .product ? serviceCRUDProductID.rawValue : nil,
            priceAmount: Decimal(string: "90071992547409.93")!,
            currency: .usd,
            taxPercentage: Decimal(string: "7.125")!,
            discountPercentage: Decimal(string: "2.375")!,
            status: .active
        )))
    }

    @Test(arguments: [Decimal.zero, Decimal(string: "-0.004")!])
    func `a normalized zero price can be accepted as a free service`(_ input: Decimal) async throws {
        let repository = InMemoryServiceRepository()
        let profile = try ServiceProfile(
            name: "Consulta gratuita",
            type: .professional,
            price: Money(amount: input, currency: .eur),
            taxRate: TaxRate(percentage: 0),
            discount: nil
        )

        _ = try await CreateServiceUseCase(repository: repository)(id: serviceCRUDID(1), profile: profile)

        #expect(try await repository.service(id: serviceCRUDID(1))?.price.amount == 0)
    }

    @Test
    func `decoded profile normalization is preserved through creation`() async throws {
        let json = #"{"name":"  Mascarilla  suave  ","type":"professional","price":{"amount":19.995,"currency":"EUR"},"taxRate":{"percentage":21},"discount":{"percentage":0}}"#
        let profile = try JSONDecoder().decode(ServiceProfile.self, from: Data(json.utf8))
        let repository = InMemoryServiceRepository()

        _ = try await CreateServiceUseCase(repository: repository)(id: serviceCRUDID(1), profile: profile)
        let reopened = try #require(try await repository.service(id: serviceCRUDID(1)))

        #expect(reopened.name == "Mascarilla  suave")
        #expect(reopened.price.amount == 20)
        #expect(reopened.discount?.percentage == 0)
    }

    @Test
    func `a duplicate identity cannot overwrite an inactive commercial snapshot`() async throws {
        let original = try makeService(id: serviceCRUDID(1).rawValue, name: "Original", status: .inactive)
        let repository = InMemoryServiceRepository(services: [original])
        let replacement = try serviceCRUDProfile(name: "Replacement", type: .product)

        await #expect(throws: ServiceError.alreadyExists) {
            try await CreateServiceUseCase(repository: repository)(id: original.id, profile: replacement)
        }

        #expect(try await repository.service(id: original.id) == original)
    }

    @Test
    func `distinct service identities may use the same commercial name`() async throws {
        let repository = InMemoryServiceRepository()
        let profile = try serviceCRUDProfile(name: "Corte", type: .professional)
        let create = CreateServiceUseCase(repository: repository)

        _ = try await create(id: serviceCRUDID(1), profile: profile)
        _ = try await create(id: serviceCRUDID(2), profile: profile)
        var iterator = await repository.observeServices().makeAsyncIterator()

        #expect(try await iterator.next()?.map(\.id) == [serviceCRUDID(1), serviceCRUDID(2)])
    }

    @Test(arguments: [ServiceType.professional, .product])
    func `editing replaces the commercial profile and keeps the current inactive state`(
        _ originalType: ServiceType
    ) async throws {
        let original = try makeService(
            id: serviceCRUDID(1).rawValue,
            name: "Original",
            type: originalType,
            linkedProductID: originalType == .product ? serviceCRUDProductID.rawValue : nil,
            status: .inactive
        )
        let repository = InMemoryServiceRepository(services: [original])
        let newType: ServiceType = originalType == .product ? .professional : .product
        let profile = try serviceCRUDProfile(name: "  Renamed  ", type: newType)

        _ = try await UpdateServiceUseCase(repository: repository)(id: original.id, profile: profile)

        #expect(try await repository.service(id: original.id) == makeService(
            id: original.id.rawValue,
            name: "Renamed",
            type: newType,
            linkedProductID: newType == .product ? serviceCRUDProductID.rawValue : nil,
            priceAmount: Decimal(string: "90071992547409.93")!,
            currency: .usd,
            taxPercentage: Decimal(string: "7.125")!,
            discountPercentage: Decimal(string: "2.375")!,
            status: .inactive
        ))
    }

    @Test
    func `an explicit zero discount and an absent discount remain distinct after editing`() async throws {
        let original = try makeService(id: serviceCRUDID(1).rawValue, discountPercentage: 0)
        let repository = InMemoryServiceRepository(services: [original])
        let withoutDiscount = try ServiceProfile(
            name: original.name,
            type: original.type,
            price: original.price,
            taxRate: original.taxRate,
            discount: nil
        )

        _ = try await UpdateServiceUseCase(repository: repository)(id: original.id, profile: withoutDiscount)

        #expect(try await repository.service(id: original.id)?.discount == nil)
    }

    @Test
    func `editing and deactivating an absent identity cannot create a service`() async throws {
        let repository = InMemoryServiceRepository()
        let profile = try serviceCRUDProfile(name: "Absent", type: .professional)

        await #expect(throws: ServiceError.notFound) {
            try await UpdateServiceUseCase(repository: repository)(id: serviceCRUDID(1), profile: profile)
        }
        await #expect(throws: ServiceError.notFound) {
            try await DeactivateServiceUseCase(repository: repository)(serviceCRUDID(1))
        }

        #expect(try await GetServiceUseCase(repository: repository)(serviceCRUDID(1)) == nil)
    }

    @Test
    func `repeated deactivation retains exact commercial values and the physical link`() async throws {
        let selected = try makeService(
            id: serviceCRUDID(1).rawValue,
            type: .product,
            linkedProductID: serviceCRUDProductID.rawValue,
            priceAmount: Decimal(string: "90071992547409.93")!,
            currency: .usd,
            taxPercentage: Decimal(string: "7.125")!,
            discountPercentage: Decimal(string: "2.375")!
        )
        let other = try makeService(id: serviceCRUDID(2).rawValue, name: "Other")
        let repository = InMemoryServiceRepository(services: [selected, other])
        let deactivate = DeactivateServiceUseCase(repository: repository)

        try await deactivate(selected.id)
        try await deactivate(selected.id)
        let reopened = try #require(try await repository.service(id: selected.id))

        #expect(reopened.status == .inactive)
        #expect(reopened.price.amount == Decimal(string: "90071992547409.93"))
        #expect(reopened.price.currency == .usd)
        #expect(reopened.taxRate.percentage == Decimal(string: "7.125"))
        #expect(reopened.discount?.percentage == Decimal(string: "2.375"))
        #expect(reopened.linkedProductID == serviceCRUDProductID)
        #expect(reopened.name == "Corte y peinado")
        #expect(reopened.type == .product)
        #expect(try await repository.service(id: other.id) == other)
    }

    @Test(arguments: [
        ("", [3, 1, 2]),
        (" \n", [3, 1, 2]),
        ("  CHAMPU  ", [3, 1]),
        ("suave", [3]),
        ("ausente", [])
    ])
    func `search preserves source order and includes both types and inactive services`(
        _ query: String,
        expectedIDs: [Int]
    ) throws {
        let services = try [
            makeService(id: serviceCRUDID(3).rawValue, name: "Champú suave", status: .inactive),
            makeService(
                id: serviceCRUDID(1).rawValue,
                name: "Champú sólido",
                type: .product,
                linkedProductID: serviceCRUDProductID.rawValue
            ),
            makeService(id: serviceCRUDID(2).rawValue, name: "Corte")
        ]

        let matches = SearchServicesUseCase()(services, query: query)

        #expect(matches.map(\.id) == expectedIDs.map(serviceCRUDID))
    }

    @Test
    func `prior cancellation prevents mutations of an existing or missing service`() async throws {
        let original = try makeService(id: serviceCRUDID(1).rawValue, name: "Original")
        let repository = InMemoryServiceRepository(services: [original])
        let profile = try serviceCRUDProfile(name: "Cancelled", type: .product)

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledServiceOperation {
                _ = try await CreateServiceUseCase(repository: repository)(id: serviceCRUDID(2), profile: profile)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledServiceOperation {
                _ = try await UpdateServiceUseCase(repository: repository)(id: original.id, profile: profile)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledServiceOperation {
                try await DeactivateServiceUseCase(repository: repository)(original.id)
            }
        }

        #expect(try await repository.service(id: original.id) == original)
        #expect(try await repository.service(id: serviceCRUDID(2)) == nil)
    }

    @Test(arguments: [ServiceCRUDCommand.create, .update, .deactivate])
    func `cancellation after local acceptance preserves a successful mutation`(
        _ command: ServiceCRUDCommand
    ) async throws {
        let original = try makeService(id: serviceCRUDID(1).rawValue, name: "Original")
        let backing = InMemoryServiceRepository(services: command == .create ? [] : [original])
        let accepted = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let repository = ServiceCRUDDelayedRepository(
            backing: backing,
            accepted: accepted.continuation,
            release: release.stream
        )
        let profile = try serviceCRUDProfile(name: "Accepted", type: .product)
        let task = Task {
            switch command {
            case .create:
                _ = try await CreateServiceUseCase(repository: repository)(id: original.id, profile: profile)
            case .update:
                _ = try await UpdateServiceUseCase(repository: repository)(id: original.id, profile: profile)
            case .deactivate:
                try await DeactivateServiceUseCase(repository: repository)(original.id)
            }
        }
        var acceptance = accepted.stream.makeAsyncIterator()
        guard await acceptance.next() != nil else {
            try await task.value
            Issue.record("Mutation returned before accepting its local snapshot")
            return
        }

        task.cancel()
        release.continuation.finish()
        try await task.value

        let reopened = try #require(try await backing.service(id: original.id))
        #expect(reopened.status == (command == .deactivate ? .inactive : .active))
        #expect(reopened.name == (command == .deactivate ? "Original" : "Accepted"))
        #expect(reopened.type == (command == .deactivate ? .professional : .product))
    }
}

enum ServiceCRUDCommand {
    case create
    case update
    case deactivate
}

private struct ServiceCRUDDelayedRepository: ServiceRepository {
    let backing: InMemoryServiceRepository
    let accepted: AsyncStream<Void>.Continuation
    let release: AsyncStream<Void>

    func createService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        defer { accepted.finish() }
        let result = try await backing.createService(id: id, profile: profile)
        await waitAfterAcceptance()
        return result
    }

    func updateService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        defer { accepted.finish() }
        let result = try await backing.updateService(id: id, profile: profile)
        await waitAfterAcceptance()
        return result
    }

    func deactivateService(_ id: ServiceID) async throws {
        defer { accepted.finish() }
        try await backing.deactivateService(id)
        await waitAfterAcceptance()
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        await backing.observeServices()
    }

    func saveService(_ service: Service) async throws {
        try await backing.saveService(service)
    }

    func service(id: ServiceID) async throws -> Service? {
        try await backing.service(id: id)
    }

    private func waitAfterAcceptance() async {
        accepted.yield(())
        var iterator = release.makeAsyncIterator()
        _ = await iterator.next()
    }
}

private func serviceCRUDProfile(name: String, type: ServiceType) throws -> ServiceProfile {
    try PrepareServiceProfileUseCase()(
        name: name,
        type: type,
        linkedProductID: type == .product ? serviceCRUDProductID : nil,
        price: Money(amount: Decimal(string: "90071992547409.93")!, currency: .usd),
        taxRate: TaxRate(percentage: Decimal(string: "7.125")!),
        discount: Discount(percentage: Decimal(string: "2.375")!)
    )
}

private let serviceCRUDProductID = ProductID(rawValue: UUID(uuidString: "10010000-0000-0000-0000-000000000010")!)

private func serviceCRUDID(_ suffix: Int) -> ServiceID {
    ServiceID(rawValue: UUID(uuidString: "10010000-0000-0000-0000-00000000000\(suffix)")!)
}

private func runPreCancelledServiceOperation(
    _ operation: @escaping @Sendable () async throws -> Void
) async throws {
    let gate = AsyncStream<Void>.makeStream()
    let task = Task {
        var iterator = gate.stream.makeAsyncIterator()
        _ = await iterator.next()
        try await operation()
    }
    task.cancel()
    gate.continuation.finish()
    try await task.value
}
