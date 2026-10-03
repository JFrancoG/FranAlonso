import Foundation

/// Captures one authorized shell lifetime; knowing a principal alone never grants access.
struct BillingAssetAccess: Sendable {
    let principalID: String
    private let authorizationCheck: @Sendable () async throws -> Void

    func validate() async throws {
        try Task.checkCancellation()
        guard !principalID.isEmpty else { throw BillingAssetError.unauthorized }
        try await authorizationCheck()
        try Task.checkCancellation()
    }
}

extension BillingAssetAccess {
    init(
        principalID: String,
        validateAuthorization: @escaping @Sendable () async throws -> Void
    ) {
        self.principalID = principalID
        authorizationCheck = validateAuthorization
    }
}
