import Foundation

enum ClientConsentReferenceError: Error, Equatable {
    case empty
}

struct ClientConsentReference: Codable, Equatable, Hashable {
    private let storedValue: String

    var rawValue: String {
        storedValue
    }
}

extension ClientConsentReference {
    init(rawValue: String) throws {
        let normalizedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedValue.isEmpty else {
            throw ClientConsentReferenceError.empty
        }

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
