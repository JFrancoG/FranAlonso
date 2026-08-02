import Foundation

/// The provider-neutral version carried by a remote Sales document.
enum SaleRemoteVersion: Codable, Equatable {
    /// A document created before authoritative sync metadata existed.
    case legacy

    /// A document advanced atomically by the synchronized write path.
    case versioned(revision: Int64, lastOperationID: UUID)
}

/// The business state represented by a remote Sales document.
enum SaleRemoteContent: Codable, Equatable {
    /// A materialized sale snapshot.
    case live(SaleDTO)

    /// A retained draft-discard marker containing no sale payload.
    case tombstone(saleID: UUID)
}

/// A complete remote Sales state and its authoritative ordering metadata.
struct SaleRemoteRecord: Identifiable, Codable, Equatable {
    let content: SaleRemoteContent
    let version: SaleRemoteVersion
    let changeSequence: Int64?

    var id: String {
        switch content {
        case .live(let sale):
            sale.id
        case .tombstone(let saleID):
            saleID.uuidString
        }
    }

    var isLive: Bool {
        if case .live = content {
            return true
        }
        return false
    }

    var isTombstone: Bool { !isLive }

    var liveSale: SaleDTO? {
        guard case .live(let sale) = content else { return nil }
        return sale
    }
}

extension SaleRemoteRecord {
    /// Creates a live remote record from its transport snapshot and metadata.
    init(sale: SaleDTO, version: SaleRemoteVersion, changeSequence: Int64? = nil) {
        self.init(
            content: .live(sale),
            version: version,
            changeSequence: changeSequence
        )
    }

    /// Returns the stable sale identity carried by live content or a tombstone.
    ///
    /// - Throws: `SaleSyncPersistenceError.entityIdentityMismatch` for an invalid live ID.
    func stableSaleID() throws -> UUID {
        switch content {
        case .live(let sale):
            try sale.stableUUID()
        case .tombstone(let saleID):
            saleID
        }
    }
}

extension SaleRemoteRecord {
    private enum CodingKeys: String, CodingKey {
        case content
        case sale
        case version
        case changeSequence
    }

    /// Decodes the current representation or a compact live-record payload.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedContent: SaleRemoteContent
        if let legacySale = try container.decodeIfPresent(
            SaleDTO.self,
            forKey: .sale
        ) {
            decodedContent = .live(legacySale)
        } else {
            decodedContent = try container.decode(
                SaleRemoteContent.self,
                forKey: .content
            )
        }

        self.init(
            content: decodedContent,
            version: try container.decode(
                SaleRemoteVersion.self,
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

/// The durable position of the Sales incremental remote feed.
struct SaleSyncCursor: Codable, Equatable {
    let changeSequence: Int64
}

/// One complete remote pull and the cursor that becomes durable with it.
struct SaleRemoteChangeBatch: Codable, Equatable {
    let records: [SaleRemoteRecord]
    let nextCursor: SaleSyncCursor
}

/// The immutable remote state against which a root local operation was created.
enum SaleRemoteBase: Codable, Equatable {
    /// No remote document had been observed for this entity.
    case absent

    /// The exact business snapshot observed before version metadata existed.
    case legacy(SaleDTO)

    /// The authoritative live remote revision observed when the local edit was accepted.
    case versioned(Int64)

    /// The authoritative tombstone revision that requires an explicit future restore.
    case tombstone(Int64)
}

/// A durable, immutable Sales upsert ready for causal remote delivery.
struct SalePendingUpsert: Identifiable, Codable, Equatable {
    let saleID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: SaleRemoteBase
    let sale: SaleDTO

    var id: UUID { operationID }
}

/// A durable Sales draft discard that removes the active snapshot before remote delivery.
struct SalePendingDiscard: Identifiable, Codable, Equatable {
    let saleID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: SaleRemoteBase

    var id: UUID { operationID }
}

/// One operation in the causal Sales delivery chain.
enum SalePendingOperation: Identifiable, Codable, Equatable {
    case upsert(SalePendingUpsert)
    case discard(SalePendingDiscard)

    var id: UUID { operationID }

    var saleID: UUID {
        switch self {
        case .upsert(let operation): operation.saleID
        case .discard(let operation): operation.saleID
        }
    }

    var operationID: UUID {
        switch self {
        case .upsert(let operation): operation.operationID
        case .discard(let operation): operation.operationID
        }
    }

    var predecessorOperationID: UUID? {
        switch self {
        case .upsert(let operation): operation.predecessorOperationID
        case .discard(let operation): operation.predecessorOperationID
        }
    }

    var base: SaleRemoteBase {
        switch self {
        case .upsert(let operation): operation.base
        case .discard(let operation): operation.base
        }
    }
}

/// Why a local Sales operation cannot be applied to the current remote state.
enum SaleSyncConflictReason: String, Codable, Equatable {
    case baseChanged
    case causalPredecessorMissing
    case operationIdentityMismatch
    case tombstoneRequiresExplicitRestore
    case discardRequiresDraft
}

/// Invalid sync metadata that must never be advanced or silently repaired.
enum SaleSyncPolicyError: Error, Codable, Equatable {
    case entityIdentityMismatch
    case invalidRemoteRevision
    case remoteRevisionOverflow
    case invalidChangeSequence
    case changeSequenceOverflow
    case invalidSalePayload
}

/// The deterministic remote action selected for one immutable Sales operation.
enum SaleRemoteMutationDecision: Codable, Equatable {
    /// Commit the supplied next authoritative record after assigning its feed sequence.
    case apply(SaleRemoteRecord)

    /// The desired upsert or draft discard is already authoritative remotely.
    case alreadyApplied(SaleRemoteRecord)

    /// Preserve both snapshots for explicit conflict resolution.
    case conflict(SaleSyncConflictReason, SaleRemoteRecord?)

    /// Reject invalid metadata without writing or discarding local work.
    case invalid(SaleSyncPolicyError)
}

/// The remotely acknowledged outcome returned after a mutation attempt.
enum SaleRemoteMutationResult: Codable, Equatable {
    case applied(SaleRemoteRecord)
    case alreadyApplied(SaleRemoteRecord)
    case conflict(SaleSyncConflictReason, SaleRemoteRecord?)
}
