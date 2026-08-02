import Foundation

/// Errors produced while normalizing a consent reference.
enum ClientConsentReferenceError: Error, Equatable {
    /// The supplied reference contains no non-whitespace characters.
    case empty
}

/// An opaque, non-empty reference to a client's persisted signed consent.
///
/// Construction and decoding trim surrounding whitespace and reject empty values.
struct ClientConsentReference: Codable, Hashable {
    private let storedValue: String

    /// The normalized reference, with surrounding whitespace removed.
    var rawValue: String {
        storedValue
    }
}

extension ClientConsentReference {
    /// Creates a consent reference from an opaque persisted value.
    ///
    /// Leading and trailing whitespace and newlines are removed before validation.
    /// - Parameter rawValue: The persisted consent reference.
    /// - Throws: `ClientConsentReferenceError.empty` if the normalized value is empty.
    init(rawValue: String) throws {
        let normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedValue.isEmpty else { throw ClientConsentReferenceError.empty }

        self.init(storedValue: normalizedValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(String.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
