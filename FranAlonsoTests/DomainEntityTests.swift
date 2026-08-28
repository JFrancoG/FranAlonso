import Foundation
import Testing
@testable import FranAlonso

@Suite("Client domain entity")
struct ClientDomainTests {
    @Test("Creates a draft client through the named factory")
    func createsADraftClientThroughTheNamedFactory() {
        let client = Client.draft(
            id: ClientID(rawValue: fixedUUID()),
            displayName: "Ana Alonso"
        )

        #expect(client.status == .draft)
        #expect(client.taxIdentifier == nil)
        #expect(client.billingAddress == nil)
    }

    @Test("Rejects an empty active consent reference")
    func rejectsAnEmptyActiveConsentReference() {
        #expect(throws: ClientConsentReferenceError.empty) {
            try ClientConsentReference(rawValue: " \n ")
        }
    }

    @Test("Decoding cannot activate a client with an empty consent reference")
    func decodingCannotActivateAClientWithAnEmptyConsentReference() {
        let data = Data(#"{"active":{"consentReference":" \n "}}"#.utf8)

        #expect(throws: ClientConsentReferenceError.empty) {
            try JSONDecoder().decode(ClientStatus.self, from: data)
        }
    }
}

@Suite("Service domain entity")
struct ServiceDomainTests {
    @Test("Creates a professional service without a product link")
    func createsAProfessionalServiceWithoutAProductLink() throws {
        let service = try makeService(type: .professional)

        #expect(service.linkedProductID == nil)
        requireSendable(service)
    }

    @Test("Creates a product service with its required product link")
    func createsAProductServiceWithItsRequiredProductLink() throws {
        let productID = ProductID(rawValue: fixedUUID())
        let service = try makeService(
            type: .product,
            linkedProductID: productID
        )

        #expect(service.linkedProductID == productID)
        #expect(try domainRoundTrip(service) == service)
    }

    @Test("Rejects a product service without a product link")
    func rejectsAProductServiceWithoutAProductLink() {
        #expect(throws: ServiceError.linkedProductRequired) {
            try makeService(type: .product)
        }
    }

    @Test("Rejects a professional service with a product link")
    func rejectsAProfessionalServiceWithAProductLink() {
        #expect(throws: ServiceError.linkedProductNotAllowed) {
            try makeService(
                type: .professional,
                linkedProductID: ProductID(rawValue: fixedUUID())
            )
        }
    }

    @Test("Decoding cannot bypass the product-link invariant")
    func decodingCannotBypassTheProductLinkInvariant() throws {
        let payload = ServicePayload(
            id: ServiceID(rawValue: fixedUUID()),
            name: "Champú nutritivo",
            type: .product,
            linkedProductID: nil,
            price: try Money(amount: domainDecimal("12.50"), currency: .eur),
            taxRate: try TaxRate(percentage: domainDecimal("21")),
            discount: nil,
            status: .active
        )
        let data = try JSONEncoder().encode(payload)

        #expect(throws: ServiceError.linkedProductRequired) {
            try JSONDecoder().decode(Service.self, from: data)
        }
    }
}

private struct ServicePayload: Codable {
    let id: ServiceID
    let name: String
    let type: ServiceType
    let linkedProductID: ProductID?
    let price: Money
    let taxRate: TaxRate
    let discount: Discount?
    let status: ServiceStatus
}

private func makeService(type: ServiceType, linkedProductID: ProductID? = nil) throws -> Service {
    try Service(
        id: ServiceID(rawValue: fixedUUID()),
        name: "Corte y peinado",
        type: type,
        linkedProductID: linkedProductID,
        price: Money(amount: domainDecimal("32.50"), currency: .eur),
        taxRate: TaxRate(percentage: domainDecimal("21")),
        discount: nil,
        status: .active
    )
}

private func fixedUUID() -> UUID {
    UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
}

private func domainDecimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
}

private func domainRoundTrip<Value: Codable>(_ value: Value) throws -> Value {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(Value.self, from: data)
}

private func requireSendable<Value: Sendable>(_ value: Value) {}
