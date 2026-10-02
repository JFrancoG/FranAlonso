import Foundation

/// Integrity or orchestration failures; no business payload belongs in diagnostics.
enum StockSyncError: Error, Codable, Equatable {
    case invalidPayload, invalidMetadata, invalidBatch, identityConflict, storageFailure, alreadySynchronizing
}

/// Immutable acknowledged event with its authoritative feed identity.
struct StockRemoteRecord: Codable, Equatable {
    let movement: StockMovementDTO
    let revision: Int64
    let operationID: UUID
    let changeSequence: Int64

    /// Validates the complete immutable record before any local mutation or remote acknowledgement.
    func validatedMovement() throws -> StockMovement {
        let value = try movement.toDomain()
        guard revision == 1, operationID == value.id.rawValue, changeSequence > 0 else {
            throw StockSyncError.invalidMetadata
        }
        return value
    }
}

/// The durable position of the immutable stock feed, advanced with its complete batch.
struct StockSyncCursor: Codable, Equatable { let changeSequence: Int64 }

/// An indivisible provider-neutral pull; empty batches retain the previous cursor or zero.
struct StockRemoteChangeBatch: Codable, Equatable {
    let records: [StockRemoteRecord]
    let nextCursor: StockSyncCursor
}

/// The remote outcome preserves both complete snapshots when an identity diverges.
enum StockRemoteMutationResult: Codable, Equatable {
    case applied(StockRemoteRecord)
    case alreadyApplied(StockRemoteRecord)
    case conflict(StockRemoteRecord)
}

/// Durable divergent payloads requiring explicit resolution; originals are never replaced.
struct StockSyncConflict: Codable, Equatable {
    let local: StockMovementDTO
    let remote: StockRemoteRecord
}
