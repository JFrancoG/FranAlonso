import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale exact timestamp transport")
struct SaleTimestampDTOTests {
    @Test(
        "Finite timestamps round trip through their exact bit pattern",
        arguments: [
            0.0,
            0.000_000_123_456_789,
            -123_456.789_012_345,
            Double.greatestFiniteMagnitude,
            -Double.greatestFiniteMagnitude
        ]
    )
    func finiteTimestampsRoundTripExactly(_ interval: TimeInterval) throws {
        let date = Date(timeIntervalSinceReferenceDate: interval)

        let dto = try SaleTimestampDTO(date)
        let roundTrip = try JSONDecoder().decode(
            SaleTimestampDTO.self,
            from: JSONEncoder().encode(dto)
        )

        #expect(roundTrip.date.timeIntervalSinceReferenceDate.bitPattern == interval.bitPattern)
        #expect(dto.canonicalString.count == 16)
        #expect(dto.canonicalString == dto.canonicalString.lowercased())
    }

    @Test("Negative zero normalizes to the sole positive-zero representation")
    func negativeZeroNormalizesToPositiveZero() throws {
        let negativeZero = Date(timeIntervalSinceReferenceDate: -0.0)

        let dto = try SaleTimestampDTO(negativeZero)

        #expect(dto.canonicalString == "0000000000000000")
        #expect(dto.date.timeIntervalSinceReferenceDate.bitPattern == 0)
        #expect(try JSONEncoder().encode(dto) == Data(#""0000000000000000""#.utf8))
    }

    @Test(
        "Noncanonical or nonfinite bit patterns fail closed",
        arguments: [
            "0",
            "00000000000000000",
            "3FF0000000000000",
            "7ff0000000000000",
            "fff0000000000000",
            "7ff8000000000000",
            "8000000000000000",
            "gggggggggggggggg"
        ]
    )
    func invalidBitPatternsFailClosed(_ encoded: String) {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                SaleTimestampDTO.self,
                from: Data("\"\(encoded)\"".utf8)
            )
        }
    }

    @Test("Construction rejects nonfinite dates")
    func constructionRejectsNonfiniteDates() {
        #expect(throws: SaleTimestampDTOError.invalidValue) {
            _ = try SaleTimestampDTO(
                Date(timeIntervalSinceReferenceDate: .nan)
            )
        }
    }
}
