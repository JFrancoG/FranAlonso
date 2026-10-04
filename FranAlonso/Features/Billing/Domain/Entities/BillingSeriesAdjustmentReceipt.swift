import Foundation

/// The original acceptance of an administrative sequence advance by its remote authority.
///
/// The principal is an opaque authority identity, never a caller-supplied permission.
/// The timestamp belongs to the authority; constructing this value does not prove its origin.
/// Replaying the same accepted command retains the original principal and timestamp.
struct BillingSeriesAdjustmentReceipt: Identifiable, Codable, Equatable {
    private let storedRequest: BillingSeriesAdjustmentRequest
    private let storedPrincipalID: String
    private let storedAdjustedAt: Date

    var id: UUID { storedRequest.id }
    var request: BillingSeriesAdjustmentRequest { storedRequest }
    var principalID: String { storedPrincipalID }
    var adjustedAt: Date { storedAdjustedAt }

    private enum CodingKeys: String, CodingKey {
        case request, principalID, adjustedAt
    }
}

extension BillingSeriesAdjustmentReceipt {
    /// Accepts an opaque principal and a resolved, finite authoritative timestamp.
    /// - Throws: `BillingSeriesAdjustmentError.invalidResponse` for an empty principal,
    ///   whitespace, control characters, slashes, or a nonfinite timestamp.
    init(request: BillingSeriesAdjustmentRequest, principalID: String, adjustedAt: Date) throws {
        guard
            Self.acceptsPrincipal(principalID),
            adjustedAt.timeIntervalSinceReferenceDate.isFinite
        else {
            throw BillingSeriesAdjustmentError.invalidResponse
        }
        self.init(storedRequest: request, storedPrincipalID: principalID, storedAdjustedAt: adjustedAt)
    }

    /// Checks opaque identity syntax without granting administrative authority.
    /// Data uses this same predicate before contacting a provider; acceptance still requires fresh authorization.
    static func acceptsPrincipal(_ principalID: String) -> Bool {
        let forbiddenCharacters = CharacterSet.whitespacesAndNewlines
            .union(.controlCharacters)
            .union(CharacterSet(charactersIn: "/"))
        return !principalID.isEmpty && principalID.rangeOfCharacter(from: forbiddenCharacters) == nil
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            request: container.decode(BillingSeriesAdjustmentRequest.self, forKey: .request),
            principalID: container.decode(String.self, forKey: .principalID),
            adjustedAt: container.decode(Date.self, forKey: .adjustedAt)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request, forKey: .request)
        try container.encode(principalID, forKey: .principalID)
        try container.encode(adjustedAt, forKey: .adjustedAt)
    }
}
