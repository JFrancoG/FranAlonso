import Foundation

/// Errors raised when a date cannot participate in exact Sale transport.
enum SaleTimestampDTOError: Error, Equatable {
    /// The timestamp is nonfinite or its representation is not canonical.
    case invalidValue
}

/// An exact Sale timestamp transported as a canonical IEEE-754 bit pattern.
struct SaleTimestampDTO: Codable, Equatable {
    private let storedDate: Date

    /// The exact finite date represented by the transport string.
    var date: Date {
        storedDate
    }

    /// The lowercase, sixteen-character hexadecimal transport representation.
    var canonicalString: String {
        Self.canonicalString(for: storedDate.timeIntervalSinceReferenceDate)
    }
}

extension SaleTimestampDTO {
    /// Creates an exact timestamp while normalizing negative zero to positive zero.
    ///
    /// - Parameter date: The finite Foundation date to preserve.
    /// - Throws: `SaleTimestampDTOError.invalidValue` when the date is not finite.
    init(_ date: Date) throws {
        let interval = date.timeIntervalSinceReferenceDate
        guard interval.isFinite else {
            throw SaleTimestampDTOError.invalidValue
        }

        let canonicalInterval = interval == 0 ? 0.0 : interval
        self.init(storedDate: Date(timeIntervalSinceReferenceDate: canonicalInterval))
    }

    /// Reconstructs a date only from the exact canonical transport representation.
    ///
    /// - Parameter canonicalString: A lowercase sixteen-character hexadecimal bit pattern.
    /// - Throws: `SaleTimestampDTOError.invalidValue` for malformed, nonfinite, or
    ///   noncanonical values.
    init(canonicalString: String) throws {
        guard canonicalString.count == 16,
              canonicalString == canonicalString.lowercased(),
              let bitPattern = UInt64(canonicalString, radix: 16),
              bitPattern != (-0.0).bitPattern else {
            throw SaleTimestampDTOError.invalidValue
        }

        let interval = Double(bitPattern: bitPattern)
        guard interval.isFinite,
              Self.canonicalString(for: interval) == canonicalString else {
            throw SaleTimestampDTOError.invalidValue
        }

        try self.init(Date(timeIntervalSinceReferenceDate: interval))
        guard self.canonicalString == canonicalString else {
            throw SaleTimestampDTOError.invalidValue
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode(String.self)
        do {
            try self.init(canonicalString: encoded)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a canonical finite Sale timestamp."
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(canonicalString)
    }

    private static func canonicalString(for interval: TimeInterval) -> String {
        let raw = String(interval.bitPattern, radix: 16, uppercase: false)
        return String(repeating: "0", count: 16 - raw.count) + raw
    }
}
