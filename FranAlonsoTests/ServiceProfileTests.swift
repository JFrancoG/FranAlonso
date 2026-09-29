import Foundation
import Testing
@testable import FranAlonso

@Suite("Service commercial profile validation")
struct ServiceProfileTests {
    @Test(arguments: ["", " ", "\n\t"])
    func `blank editable names are rejected`(_ name: String) throws {
        #expect(throws: ServiceError.invalidName) {
            try PrepareServiceProfileUseCase()(
                name: name,
                type: .professional,
                price: Money(amount: 20, currency: .eur),
                taxRate: TaxRate(percentage: 21),
                discount: nil
            )
        }
    }

    @Test(arguments: [Decimal(-1), Decimal(string: "-0.01")!])
    func `negative normalized prices cannot enter a commercial command`(_ amount: Decimal) throws {
        #expect(throws: ServiceError.invalidPrice) {
            try ServiceProfile(
                name: "Corte",
                type: .professional,
                price: Money(amount: amount, currency: .eur),
                taxRate: TaxRate(percentage: 21),
                discount: nil
            )
        }
    }

    @Test(arguments: [ServiceType.product, .professional])
    func `editable profiles enforce the relation between type and physical product`(_ type: ServiceType) throws {
        let unexpectedLink = ProductID(rawValue: UUID(uuidString: "10010000-0000-0000-0000-000000000001")!)
        let expected: ServiceError = type == .product ? .linkedProductRequired : .linkedProductNotAllowed

        #expect(throws: expected) {
            try ServiceProfile(
                name: "Catálogo",
                type: type,
                linkedProductID: type == .product ? nil : unexpectedLink,
                price: Money(amount: 20, currency: .eur),
                taxRate: TaxRate(percentage: 21),
                discount: nil
            )
        }
    }

    @Test(arguments: [
        (#"{"name":"  \n\t ","type":"professional","price":{"amount":25,"currency":"EUR"},"taxRate":{"percentage":21}}"#, ServiceError.invalidName),
        (#"{"name":"Corte","type":"professional","price":{"amount":-0.01,"currency":"EUR"},"taxRate":{"percentage":21}}"#, ServiceError.invalidPrice),
        (#"{"name":"Champú","type":"product","price":{"amount":25,"currency":"EUR"},"taxRate":{"percentage":21}}"#, ServiceError.linkedProductRequired),
        (#"{"name":"Corte","type":"professional","linkedProductID":{"rawValue":"10010000-0000-0000-0000-000000000001"},"price":{"amount":25,"currency":"EUR"},"taxRate":{"percentage":21}}"#, ServiceError.linkedProductNotAllowed)
    ])
    func `external editable payloads cannot bypass commercial validation`(_ json: String, expected: ServiceError) {
        #expect(throws: expected) {
            try JSONDecoder().decode(ServiceProfile.self, from: Data(json.utf8))
        }
    }

    @Test
    func `a historical snapshot remains readable despite new commercial input rules`() async throws {
        let json = #"{"id":{"rawValue":"10010000-0000-0000-0000-000000000001"},"name":"   ","type":"professional","price":{"amount":-12.34,"currency":"USD"},"taxRate":{"percentage":0},"status":"inactive"}"#
        let service = try JSONDecoder().decode(Service.self, from: Data(json.utf8))
        let repository = InMemoryServiceRepository()

        try await SaveServiceUseCase(repository: repository)(service)
        let reopened = try #require(try await GetServiceUseCase(repository: repository)(service.id))

        #expect(reopened.name == "   ")
        #expect(reopened.price.amount == Decimal(string: "-12.34"))
        #expect(reopened.price.currency == .usd)
        #expect(reopened.status == .inactive)
    }
}
