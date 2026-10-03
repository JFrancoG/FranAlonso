import Foundation

/// Serializes private signature filesystem access across repository instances.
///
/// Authorization may suspend, so publication captures the previous resource only in its final synchronous commit.
/// Preparation, commit and cleanup run on this actor; no filesystem operation interleaves inside a commit.
actor BillingSignatureCacheCoordinator {
    static let shared = BillingSignatureCacheCoordinator()

    func load(
        access: BillingAssetAccess,
        read: @Sendable () throws -> Data?
    ) async throws -> Data? {
        try await access.validate()
        let data = try read()
        try await access.validate()
        return data
    }

    func publish(
        access: BillingAssetAccess,
        prepare: @Sendable () throws -> URL,
        commit: @Sendable (URL) throws -> Void,
        discard: @Sendable (URL) -> Void
    ) async throws {
        try await access.validate()
        let candidate = try prepare()
        defer {
            discard(candidate)
        }
        try await access.validate()
        try commit(candidate)
        // The synchronous commit has accepted the resource; later cancellation cannot undo that acceptance.
    }
}
