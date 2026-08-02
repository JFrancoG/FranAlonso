import Foundation

/// The provider-neutral version carried by a remote Services document.
enum ServiceRemoteVersion: Codable, Equatable {
    /// A document created before authoritative sync metadata existed.
    case legacy

    /// A document advanced atomically by the synchronized write path.
    case versioned(revision: Int64, lastOperationID: UUID)
}

/// The business state represented by a remote Services document.
enum ServiceRemoteContent: Codable, Equatable {
    /// A materialized service snapshot.
    case live(ServiceDTO)

    /// A retained deletion marker containing no service PII.
    case tombstone(serviceID: UUID)
}

/// A complete remote Services state and its authoritative ordering metadata.
struct ServiceRemoteRecord: Identifiable, Codable, Equatable {
    let content: ServiceRemoteContent
    let version: ServiceRemoteVersion
    let changeSequence: Int64?

    var id: String {
        switch content {
        case .live(let service):
            service.id
        case .tombstone(let serviceID):
            serviceID.uuidString
        }
    }

    var isLive: Bool {
        if case .live = content {
            return true
        }
        return false
    }

    var isTombstone: Bool { !isLive }

    var liveService: ServiceDTO? {
        guard case .live(let service) = content else { return nil }
        return service
    }
}

extension ServiceRemoteRecord {
    /// Creates a live remote record from its transport snapshot and metadata.
    init(
        service: ServiceDTO,
        version: ServiceRemoteVersion,
        changeSequence: Int64? = nil
    ) {
        self.init(
            content: .live(service),
            version: version,
            changeSequence: changeSequence
        )
    }

    /// Returns the stable service identity carried by live content or a tombstone.
    ///
    /// - Throws: `ServiceSyncPersistenceError.entityIdentityMismatch` for an invalid live ID.
    func stableServiceID() throws -> UUID {
        switch content {
        case .live(let service):
            try service.stableUUID()
        case .tombstone(let serviceID):
            serviceID
        }
    }
}

extension ServiceRemoteRecord {
    private enum CodingKeys: String, CodingKey {
        case content
        case service
        case version
        case changeSequence
    }

    /// Decodes the current representation or a compact live-record payload.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedContent: ServiceRemoteContent
        if let legacyService = try container.decodeIfPresent(
            ServiceDTO.self,
            forKey: .service
        ) {
            decodedContent = .live(legacyService)
        } else {
            decodedContent = try container.decode(
                ServiceRemoteContent.self,
                forKey: .content
            )
        }

        self.init(
            content: decodedContent,
            version: try container.decode(
                ServiceRemoteVersion.self,
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

/// The durable position of the Services incremental remote feed.
struct ServiceSyncCursor: Codable, Equatable {
    let changeSequence: Int64
}

/// One complete remote pull and the cursor that becomes durable with it.
struct ServiceRemoteChangeBatch: Codable, Equatable {
    let records: [ServiceRemoteRecord]
    let nextCursor: ServiceSyncCursor
}

/// The immutable remote state against which a root local operation was created.
enum ServiceRemoteBase: Codable, Equatable {
    /// No remote document had been observed for this entity.
    case absent

    /// The exact business snapshot observed before version metadata existed.
    case legacy(ServiceDTO)

    /// The authoritative live remote revision observed when the local edit was accepted.
    case versioned(Int64)

    /// The authoritative tombstone revision that requires an explicit future restore.
    case tombstone(Int64)
}

/// A durable, immutable Services upsert ready for causal remote delivery.
struct ServicePendingUpsert: Identifiable, Codable, Equatable {
    let serviceID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ServiceRemoteBase
    let service: ServiceDTO

    var id: UUID { operationID }
}

/// A durable Services deletion that removes the active snapshot before remote delivery.
struct ServicePendingDelete: Identifiable, Codable, Equatable {
    let serviceID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ServiceRemoteBase

    var id: UUID { operationID }
}

/// One operation in the causal Services delivery chain.
enum ServicePendingOperation: Identifiable, Codable, Equatable {
    case upsert(ServicePendingUpsert)
    case delete(ServicePendingDelete)

    var id: UUID { operationID }

    var serviceID: UUID {
        switch self {
        case .upsert(let operation): operation.serviceID
        case .delete(let operation): operation.serviceID
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

    var base: ServiceRemoteBase {
        switch self {
        case .upsert(let operation): operation.base
        case .delete(let operation): operation.base
        }
    }
}

/// Why a local Services operation cannot be applied to the current remote state.
enum ServiceSyncConflictReason: String, Codable, Equatable {
    case baseChanged
    case causalPredecessorMissing
    case operationIdentityMismatch
    case tombstoneRequiresExplicitRestore
}

/// Invalid sync metadata that must never be advanced or silently repaired.
enum ServiceSyncPolicyError: Error, Codable, Equatable {
    case entityIdentityMismatch
    case invalidRemoteRevision
    case remoteRevisionOverflow
    case invalidChangeSequence
    case changeSequenceOverflow
}

/// The deterministic remote action selected for one immutable Services operation.
enum ServiceRemoteMutationDecision: Codable, Equatable {
    /// Commit the supplied next authoritative record after assigning its feed sequence.
    case apply(ServiceRemoteRecord)

    /// The desired operation or deletion is already authoritative remotely.
    case alreadyApplied(ServiceRemoteRecord)

    /// Preserve both snapshots for explicit conflict resolution.
    case conflict(ServiceSyncConflictReason, ServiceRemoteRecord?)

    /// Reject invalid metadata without writing or discarding local work.
    case invalid(ServiceSyncPolicyError)
}

/// The remotely acknowledged outcome returned after a mutation attempt.
enum ServiceRemoteMutationResult: Codable, Equatable {
    case applied(ServiceRemoteRecord)
    case alreadyApplied(ServiceRemoteRecord)
    case conflict(ServiceSyncConflictReason, ServiceRemoteRecord?)
}
