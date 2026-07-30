import Foundation
import Testing
@testable import FranAlonso

@Suite("Canonical decimal transport")
struct CanonicalDecimalDTOTests {
    @Test(
        "Canonical decimal strings round trip byte for byte",
        arguments: [
            "0",
            "-12.5",
            "0.5",
            "10.005",
            "12345678901234567890123456789012345678",
            "0.00000000000000000000000000000000000001"
        ]
    )
    func canonicalDecimalStringsRoundTrip(_ canonicalValue: String) throws {
        let encoded = Data("\"\(canonicalValue)\"".utf8)

        let value = try JSONDecoder().decode(
            CanonicalDecimalDTO.self,
            from: encoded
        )

        #expect(try JSONEncoder().encode(value) == encoded)
    }

    @Test(
        "Noncanonical decimal strings fail closed",
        arguments: [
            "-0",
            "1.0",
            "0.50",
            "01",
            "-01",
            "+1",
            ".5",
            "100.",
            "1e2",
            "1E+2",
            "1,000",
            "0,5",
            "1.234,5",
            "1_000",
            " 1",
            "1 ",
            "123456789012345678901234567890123456789",
            "",
            "NaN",
            "Infinity",
            "-Infinity"
        ]
    )
    func noncanonicalDecimalStringsFailClosed(_ value: String) {
        let encoded = Data("\"\(value)\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                CanonicalDecimalDTO.self,
                from: encoded
            )
        }
    }

    @Test("The wire representation must be a string")
    func wireRepresentationMustBeAString() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                CanonicalDecimalDTO.self,
                from: Data("10.5".utf8)
            )
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                CanonicalDecimalDTO.self,
                from: Data("null".utf8)
            )
        }
    }

    @Test("Construction rejects a non-number Decimal")
    func constructionRejectsANonNumberDecimal() {
        #expect(throws: CanonicalDecimalDTOError.invalidValue) {
            _ = try CanonicalDecimalDTO(.nan)
        }
    }
}
