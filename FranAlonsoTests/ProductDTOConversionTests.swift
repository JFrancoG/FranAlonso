import Foundation
import Testing
@testable import FranAlonso

@Suite("Product DTO conversions")
struct ProductDTOConversionTests {
    @Test("Decodes a complete product fixture")
    func decodesACompleteProductFixture() throws {
        let dto = try JSONDecoder().decode(
            ProductDTO.self,
            from: Data(
                #"{"id":"71000000-0000-0000-0000-000000000001","name":"Champú nutritivo","status":"active"}"#.utf8
            )
        )

        #expect(
            dto == ProductDTO(
                id: "71000000-0000-0000-0000-000000000001",
                name: "Champú nutritivo",
                status: .active
            )
        )
    }

    @Test("Preserves an unknown status coding path")
    func preservesUnknownStatusCodingPath() {
        let data = Data(
            #"{"id":"71000000-0000-0000-0000-000000000001","name":"Champú nutritivo","status":"archived"}"#.utf8
        )

        do {
            _ = try JSONDecoder().decode(ProductDTO.self, from: data)
            Issue.record("Expected an unknown Product status decoding error")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["status"])
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }

    @Test("Rejects an invalid Product identifier")
    func rejectsInvalidProductIdentifier() {
        let dto = ProductDTO(
            id: "not-a-product-id",
            name: "Champú nutritivo",
            status: .active
        )

        #expect(
            throws: ProductMappingError.invalidIdentifier("not-a-product-id")
        ) {
            try dto.toDomain()
        }
    }
}
