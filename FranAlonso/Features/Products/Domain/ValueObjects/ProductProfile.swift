import Foundation

/// Editable product metadata, independent of identity, availability and stock.
struct ProductProfile: Codable, Equatable {
    private let storedName: String

    var name: String { storedName }

    private enum CodingKeys: String, CodingKey {
        case storedName = "name"
    }
}

extension ProductProfile {
    /// Accepts a nonempty name after trimming exterior whitespace.
    /// - Throws: `ProductError.invalidName` when the normalized name is empty.
    init(name: String) throws {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { throw ProductError.invalidName }
        self.init(storedName: normalizedName)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(name: container.decode(String.self, forKey: .storedName))
    }
}
