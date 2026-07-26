import Foundation

/// The provider-neutral version carried by a remote Clients document.
enum ClientRemoteVersion: Codable, Equatable {
    /// A document created before authoritative sync metadata existed.
    case legacy

    /// A document advanced atomically by the synchronized write path.
    case versioned(revision: Int64, lastOperationID: UUID)
}

/// A complete remote Clients snapshot and its authoritative version state.
struct ClientRemoteRecord: Identifiable, Codable, Equatable {
    let client: ClientDTO
    let version: ClientRemoteVersion

    var id: String { client.id }
}

/// The immutable remote state against which a root local operation was created.
enum ClientRemoteBase: Codable, Equatable {
    /// No remote document had been observed for this entity.
    case absent

    /// The exact business snapshot observed before version metadata existed.
    case legacy(ClientDTO)

    /// The authoritative remote revision observed when the local edit was accepted.
    case versioned(Int64)
}

/// A durable, immutable Clients upsert ready for causal remote delivery.
struct ClientPendingUpsert: Identifiable, Codable, Equatable {
    let clientID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ClientRemoteBase
    let client: ClientDTO

    var id: UUID { operationID }
}

/// Why a local Clients operation cannot be applied to the current remote state.
enum ClientSyncConflictReason: String, Codable, Equatable {
    case baseChanged
    case causalPredecessorMissing
    case operationIdentityMismatch
}

/// Invalid sync metadata that must never be advanced or silently repaired.
enum ClientSyncPolicyError: Error, Codable, Equatable {
    case entityIdentityMismatch
    case invalidRemoteRevision
    case remoteRevisionOverflow
}

/// The deterministic remote action selected for one immutable Clients operation.
enum ClientRemoteUpsertDecision: Codable, Equatable {
    /// Commit the supplied next authoritative record.
    case apply(ClientRemoteRecord)

    /// The exact operation and payload are already authoritative remotely.
    case alreadyApplied(ClientRemoteRecord)

    /// Preserve both snapshots for explicit conflict resolution.
    case conflict(ClientSyncConflictReason, ClientRemoteRecord?)

    /// Reject invalid metadata without writing or discarding local work.
    case invalid(ClientSyncPolicyError)
}

/// The remotely acknowledged outcome returned after an upsert attempt.
enum ClientRemoteUpsertResult: Codable, Equatable {
    case applied(ClientRemoteRecord)
    case alreadyApplied(ClientRemoteRecord)
    case conflict(ClientSyncConflictReason, ClientRemoteRecord?)
}
