import Foundation

/// The provider-neutral version carried by a remote Clients document.
enum ClientRemoteVersion: Codable, Equatable {
    /// A document created before authoritative sync metadata existed.
    case legacy

    /// A document advanced atomically by the synchronized write path.
    case versioned(revision: Int64, lastOperationID: UUID)
}

/// The business state represented by a remote Clients document.
enum ClientRemoteContent: Codable, Equatable {
    /// A materialized client snapshot.
    case live(ClientDTO)

    /// A retained deletion marker containing no client PII.
    case tombstone(clientID: UUID)
}

/// A complete remote Clients state and its authoritative ordering metadata.
struct ClientRemoteRecord: Identifiable, Codable, Equatable {
    let content: ClientRemoteContent
    let version: ClientRemoteVersion
    let changeSequence: Int64?

    var id: String {
        switch content {
        case .live(let client):
            client.id
        case .tombstone(let clientID):
            clientID.uuidString
        }
    }

    var isLive: Bool {
        if case .live = content {
            return true
        }
        return false
    }

    var isTombstone: Bool { !isLive }

    var liveClient: ClientDTO? {
        guard case .live(let client) = content else { return nil }
        return client
    }
}

extension ClientRemoteRecord {
    /// Creates a live remote record while preserving the compact 05.7 call-site meaning.
    init(client: ClientDTO, version: ClientRemoteVersion, changeSequence: Int64? = nil) {
        self.init(
            content: .live(client),
            version: version,
            changeSequence: changeSequence
        )
    }

    /// Returns the stable client identity carried by live content or a tombstone.
    ///
    /// - Throws: `ClientSyncPersistenceError.entityIdentityMismatch` for an invalid live ID.
    func stableClientID() throws -> UUID {
        switch content {
        case .live(let client):
            try client.stableUUID()
        case .tombstone(let clientID):
            clientID
        }
    }
}

extension ClientRemoteRecord {
    private enum CodingKeys: String, CodingKey {
        case content
        case client
        case version
        case changeSequence
    }

    /// Decodes both the current live-or-tombstone representation and 05.7 live blobs.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedContent: ClientRemoteContent
        if let legacyClient = try container.decodeIfPresent(
            ClientDTO.self,
            forKey: .client
        ) {
            decodedContent = .live(legacyClient)
        } else {
            decodedContent = try container.decode(
                ClientRemoteContent.self,
                forKey: .content
            )
        }

        self.init(
            content: decodedContent,
            version: try container.decode(
                ClientRemoteVersion.self,
                forKey: .version
            ),
            changeSequence: try container.decodeIfPresent(
                Int64.self,
                forKey: .changeSequence
            )
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(
            changeSequence,
            forKey: .changeSequence
        )
    }
}

/// The durable position of the Clients incremental remote feed.
struct ClientSyncCursor: Codable, Equatable {
    let changeSequence: Int64
}

/// One complete remote pull and the cursor that becomes durable with it.
struct ClientRemoteChangeBatch: Codable, Equatable {
    let records: [ClientRemoteRecord]
    let nextCursor: ClientSyncCursor
}

/// The immutable remote state against which a root local operation was created.
enum ClientRemoteBase: Codable, Equatable {
    /// No remote document had been observed for this entity.
    case absent

    /// The exact business snapshot observed before version metadata existed.
    case legacy(ClientDTO)

    /// The authoritative live remote revision observed when the local edit was accepted.
    case versioned(Int64)

    /// The authoritative tombstone revision that requires an explicit future restore.
    case tombstone(Int64)
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

/// A durable Clients deletion that removes the active snapshot before remote delivery.
struct ClientPendingDelete: Identifiable, Codable, Equatable {
    let clientID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ClientRemoteBase

    var id: UUID { operationID }
}

/// One operation in the causal Clients delivery chain.
enum ClientPendingOperation: Identifiable, Codable, Equatable {
    case upsert(ClientPendingUpsert)
    case delete(ClientPendingDelete)

    var id: UUID { operationID }

    var clientID: UUID {
        switch self {
        case .upsert(let operation): operation.clientID
        case .delete(let operation): operation.clientID
        }
    }

    var operationID: UUID {
        switch self {
        case .upsert(let operation): operation.operationID
        case .delete(let operation): operation.operationID
        }
    }

    var predecessorOperationID: UUID? {
        switch self {
        case .upsert(let operation): operation.predecessorOperationID
        case .delete(let operation): operation.predecessorOperationID
        }
    }

    var base: ClientRemoteBase {
        switch self {
        case .upsert(let operation): operation.base
        case .delete(let operation): operation.base
        }
    }
}

/// Why a local Clients operation cannot be applied to the current remote state.
enum ClientSyncConflictReason: String, Codable, Equatable {
    case baseChanged
    case causalPredecessorMissing
    case operationIdentityMismatch
    case tombstoneRequiresExplicitRestore
}

/// Invalid sync metadata that must never be advanced or silently repaired.
enum ClientSyncPolicyError: Error, Codable, Equatable {
    case entityIdentityMismatch
    case invalidRemoteRevision
    case remoteRevisionOverflow
    case invalidChangeSequence
    case changeSequenceOverflow
}

/// The deterministic remote action selected for one immutable Clients operation.
enum ClientRemoteMutationDecision: Codable, Equatable {
    /// Commit the supplied next authoritative record after assigning its feed sequence.
    case apply(ClientRemoteRecord)

    /// The desired operation or deletion is already authoritative remotely.
    case alreadyApplied(ClientRemoteRecord)

    /// Preserve both snapshots for explicit conflict resolution.
    case conflict(ClientSyncConflictReason, ClientRemoteRecord?)

    /// Reject invalid metadata without writing or discarding local work.
    case invalid(ClientSyncPolicyError)
}

/// The remotely acknowledged outcome returned after a mutation attempt.
enum ClientRemoteMutationResult: Codable, Equatable {
    case applied(ClientRemoteRecord)
    case alreadyApplied(ClientRemoteRecord)
    case conflict(ClientSyncConflictReason, ClientRemoteRecord?)
}

typealias ClientRemoteUpsertDecision = ClientRemoteMutationDecision
typealias ClientRemoteUpsertResult = ClientRemoteMutationResult
