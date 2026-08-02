import Foundation
import Testing
@testable import FranAlonso

@Suite("Service DTO conversion")
struct ServiceDTOConversionTests {
    @Test("A professional Service round trips through its nested transport payload")
    func professionalServiceRoundTrips() throws {
        let service = try makeService()

        let dto = try ServiceDTO(service)

        #expect(try dto.toDomain() == service)
        #expect(dto.type == .professional)
        #expect(dto.linkedProductID == nil)
        #expect(dto.price.currency == .eur)
        #expect(dto.price.amount.decimal == 29.95)
        #expect(dto.taxRate.percentage.decimal == 21)
        #expect(dto.discount?.percentage.decimal == 10)
        #expect(dto.status == .active)
    }

    @Test("A product-backed Service preserves its Product link")
    func productServicePreservesItsLink() throws {
        let linkedProductID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000511"
        )!
        let service = try makeService(
            name: "Champú",
            type: .product,
            linkedProductID: linkedProductID,
            priceAmount: 12.5,
            currency: .usd,
            taxPercentage: 8.5,
            discountPercentage: nil,
            status: .inactive
        )

        let dto = try ServiceDTO(service)

        #expect(try dto.toDomain() == service)
        #expect(dto.type == .product)
        #expect(dto.linkedProductID == linkedProductID.uuidString)
        #expect(dto.discount == nil)
    }

    @Test("The encoded wire payload contains decimal strings, never JSON numbers")
    func wirePayloadContainsDecimalStrings() throws {
        let dto = try ServiceDTO(makeService())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(dto)

        #expect(
            String(decoding: data, as: UTF8.self)
                == #"{"discount":{"percentage":"10"},"id":"00000000-0000-0000-0000-000000000510","name":"Corte y peinado","price":{"amount":"29.95","currency":"EUR"},"status":"active","taxRate":{"percentage":"21"},"type":"professional"}"#
        )
    }

    @Test(
        "Invalid nested decimal strings retain their exact coding path",
        arguments: [
            (
                #"{"id":"00000000-0000-0000-0000-000000000510","name":"A","type":"professional","price":{"amount":"01.0","currency":"EUR"},"taxRate":{"percentage":"21"},"status":"active"}"#,
                ["price", "amount"]
            ),
            (
                #"{"id":"00000000-0000-0000-0000-000000000510","name":"A","type":"professional","price":{"amount":"1","currency":"EUR"},"taxRate":{"percentage":"21.0"},"status":"active"}"#,
                ["taxRate", "percentage"]
            ),
            (
                #"{"id":"00000000-0000-0000-0000-000000000510","name":"A","type":"professional","price":{"amount":"1","currency":"EUR"},"taxRate":{"percentage":"21"},"discount":{"percentage":"10.0"},"status":"active"}"#,
                ["discount", "percentage"]
            )
        ]
    )
    func invalidNestedDecimalRetainsCodingPath(payload: String, expectedPath: [String]) {
        do {
            _ = try JSONDecoder().decode(
                ServiceDTO.self,
                from: Data(payload.utf8)
            )
            Issue.record("Expected the nested decimal payload to fail")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == expectedPath)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Invalid stable identifiers fail at the Data-to-Domain boundary")
    func invalidIdentifiersFailAtMappingBoundary() throws {
        let valid = try ServiceDTO(makeService())
        let invalidServiceID = ServiceDTO(
            id: "not-a-uuid",
            name: valid.name,
            type: valid.type,
            linkedProductID: valid.linkedProductID,
            price: valid.price,
            taxRate: valid.taxRate,
            discount: valid.discount,
            status: valid.status
        )
        let invalidProductID = ServiceDTO(
            id: valid.id,
            name: "Producto",
            type: .product,
            linkedProductID: "not-a-uuid",
            price: valid.price,
            taxRate: valid.taxRate,
            discount: nil,
            status: valid.status
        )

        #expect(
            throws: ServiceMappingError.invalidIdentifier("not-a-uuid")
        ) {
            _ = try invalidServiceID.toDomain()
        }
        #expect(
            throws: ServiceMappingError.invalidLinkedProductIdentifier(
                "not-a-uuid"
            )
        ) {
            _ = try invalidProductID.toDomain()
        }
    }

    @Test("DTO reconstruction re-runs the Service type-link invariant")
    func reconstructionRevalidatesTypeLinkInvariant() throws {
        let valid = try ServiceDTO(makeService())
        let productWithoutLink = ServiceDTO(
            id: valid.id,
            name: valid.name,
            type: .product,
            linkedProductID: nil,
            price: valid.price,
            taxRate: valid.taxRate,
            discount: valid.discount,
            status: valid.status
        )
        let professionalWithLink = ServiceDTO(
            id: valid.id,
            name: valid.name,
            type: .professional,
            linkedProductID: UUID().uuidString,
            price: valid.price,
            taxRate: valid.taxRate,
            discount: valid.discount,
            status: valid.status
        )

        #expect(throws: ServiceError.linkedProductRequired) {
            _ = try productWithoutLink.toDomain()
        }
        #expect(throws: ServiceError.linkedProductNotAllowed) {
            _ = try professionalWithLink.toDomain()
        }
    }

    @Test("A remote price that Domain would normalize fails closed")
    func normalizedRemotePriceFailsClosed() throws {
        let valid = try ServiceDTO(makeService())
        let unnormalizedPrice = ServiceDTO(
            id: valid.id,
            name: valid.name,
            type: valid.type,
            linkedProductID: valid.linkedProductID,
            price: ServiceMoneyDTO(
                amount: try CanonicalDecimalDTO(10.005),
                currency: .eur
            ),
            taxRate: valid.taxRate,
            discount: valid.discount,
            status: valid.status
        )

        #expect(
            throws: ServiceMappingError.moneyNormalizationChanged(
                original: 10.005,
                normalized: 10.01
            )
        ) {
            _ = try unnormalizedPrice.toDomain()
        }
    }

    @Test("Out-of-range percentages preserve Domain validation errors")
    func outOfRangePercentagesPreserveDomainErrors() throws {
        let valid = try ServiceDTO(makeService())
        let invalidTax = ServiceDTO(
            id: valid.id,
            name: valid.name,
            type: valid.type,
            linkedProductID: valid.linkedProductID,
            price: valid.price,
            taxRate: ServiceTaxRateDTO(
                percentage: try CanonicalDecimalDTO(101)
            ),
            discount: valid.discount,
            status: valid.status
        )
        let invalidDiscount = ServiceDTO(
            id: valid.id,
            name: valid.name,
            type: valid.type,
            linkedProductID: valid.linkedProductID,
            price: valid.price,
            taxRate: valid.taxRate,
            discount: ServiceDiscountDTO(
                percentage: try CanonicalDecimalDTO(-1)
            ),
            status: valid.status
        )

        #expect(throws: TaxRateError.outOfRange) {
            _ = try invalidTax.toDomain()
        }
        #expect(throws: DiscountError.outOfRange) {
            _ = try invalidDiscount.toDomain()
        }
    }
}
