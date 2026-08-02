import Foundation

/// Errors raised when a decimal value cannot participate in canonical transport.
enum CanonicalDecimalDTOError: Error, Equatable {
    /// The value is not a finite decimal number.
    case invalidValue
}

/// A decimal value transported as one canonical, locale-independent JSON string.
///
/// Decoding accepts only the exact representation produced by this type. This
/// prevents provider or locale coercion from silently changing business values.
struct CanonicalDecimalDTO: Codable, Equatable {
    private let storedDecimal: Decimal

    /// The exact decimal value represented by the transport string.
    var decimal: Decimal {
        storedDecimal
    }

    /// The canonical string used by transport and flattened local persistence.
    var canonicalString: String {
        Self.canonicalString(for: storedDecimal)
    }
}

extension CanonicalDecimalDTO {
    /// Creates a transport value from a valid decimal number.
    ///
    /// - Parameter decimal: The decimal value to preserve.
    /// - Throws: `CanonicalDecimalDTOError.invalidValue` when the value is not a number.
    init(_ decimal: Decimal) throws {
        guard !decimal.isNaN else { throw CanonicalDecimalDTOError.invalidValue }
        self.init(storedDecimal: decimal)
    }

    /// Reconstructs a decimal only when its persisted string is already canonical.
    ///
    /// - Parameter canonicalString: The exact base-ten representation to validate.
    /// - Throws: `CanonicalDecimalDTOError.invalidValue` when the representation is
    ///   malformed or would be normalized to a different byte sequence.
    init(canonicalString: String) throws {
        guard let decimal = Decimal(
            string: canonicalString,
            locale: Locale(identifier: "en_US_POSIX")
        ), !decimal.isNaN,
        Self.canonicalString(for: decimal) == canonicalString else {
            throw CanonicalDecimalDTOError.invalidValue
        }
        self.init(storedDecimal: decimal)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode(String.self)
        do {
            try self.init(canonicalString: encoded)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a canonical decimal string."
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(canonicalString)
    }

    private static func canonicalString(for decimal: Decimal) -> String {
        decimal.formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.significantDigits(1...38))
        )
    }
}
