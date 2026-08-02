import Foundation

/// The provider-neutral version carried by a remote Products document.
enum ProductRemoteVersion: Codable, Equatable {
    /// A document created before authoritative sync metadata existed.
    case legacy

    /// A document advanced atomically by the synchronized write path.
    case versioned(revision: Int64, lastOperationID: UUID)
}

/// The business state represented by a remote Products document.
enum ProductRemoteContent: Codable, Equatable {
    /// A materialized product snapshot.
    case live(ProductDTO)

    /// A retained deletion marker containing no product PII.
    case tombstone(productID: UUID)
}

/// A complete remote Products state and its authoritative ordering metadata.
struct ProductRemoteRecord: Identifiable, Codable, Equatable {
    let content: ProductRemoteContent
    let version: ProductRemoteVersion
    let changeSequence: Int64?

    var id: String {
        switch content {
        case .live(let product):
            product.id
        case .tombstone(let productID):
            productID.uuidString
        }
    }

    var isLive: Bool {
        if case .live = content {
            return true
        }
        return false
    }

    var isTombstone: Bool { !isLive }

    var liveProduct: ProductDTO? {
        guard case .live(let product) = content else { return nil }
        return product
    }
}

extension ProductRemoteRecord {
    /// Creates a live remote record from its transport snapshot and metadata.
    init(product: ProductDTO, version: ProductRemoteVersion, changeSequence: Int64? = nil) {
        self.init(
            content: .live(product),
            version: version,
            changeSequence: changeSequence
        )
    }

    /// Returns the stable product identity carried by live content or a tombstone.
    ///
    /// - Throws: `ProductSyncPersistenceError.entityIdentityMismatch` for an invalid live ID.
    func stableProductID() throws -> UUID {
        switch content {
        case .live(let product):
            try product.stableUUID()
        case .tombstone(let productID):
            productID
        }
    }
}

extension ProductRemoteRecord {
    private enum CodingKeys: String, CodingKey {
        case content
        case product
        case version
        case changeSequence
    }

    /// Decodes the current representation or a compact live-record payload.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedContent: ProductRemoteContent
        if let legacyProduct = try container.decodeIfPresent(
            ProductDTO.self,
            forKey: .product
        ) {
            decodedContent = .live(legacyProduct)
        } else {
            decodedContent = try container.decode(
                ProductRemoteContent.self,
                forKey: .content
            )
        }

        self.init(
            content: decodedContent,
            version: try container.decode(
                ProductRemoteVersion.self,
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

/// The durable position of the Products incremental remote feed.
struct ProductSyncCursor: Codable, Equatable {
    let changeSequence: Int64
}

/// One complete remote pull and the cursor that becomes durable with it.
struct ProductRemoteChangeBatch: Codable, Equatable {
    let records: [ProductRemoteRecord]
    let nextCursor: ProductSyncCursor
}

/// The immutable remote state against which a root local operation was created.
enum ProductRemoteBase: Codable, Equatable {
    /// No remote document had been observed for this entity.
    case absent

    /// The exact business snapshot observed before version metadata existed.
    case legacy(ProductDTO)

    /// The authoritative live remote revision observed when the local edit was accepted.
    case versioned(Int64)

    /// The authoritative tombstone revision that requires an explicit future restore.
    case tombstone(Int64)
}

/// A durable, immutable Products upsert ready for causal remote delivery.
struct ProductPendingUpsert: Identifiable, Codable, Equatable {
    let productID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ProductRemoteBase
    let product: ProductDTO

    var id: UUID { operationID }
}

/// A durable Products deletion that removes the active snapshot before remote delivery.
struct ProductPendingDelete: Identifiable, Codable, Equatable {
    let productID: UUID
    let operationID: UUID
    let predecessorOperationID: UUID?
    let base: ProductRemoteBase

    var id: UUID { operationID }
}

/// One operation in the causal Products delivery chain.
enum ProductPendingOperation: Identifiable, Codable, Equatable {
    case upsert(ProductPendingUpsert)
    case delete(ProductPendingDelete)

    var id: UUID { operationID }

    var productID: UUID {
        switch self {
        case .upsert(let operation): operation.productID
        case .delete(let operation): operation.productID
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

    var base: ProductRemoteBase {
        switch self {
        case .upsert(let operation): operation.base
        case .delete(let operation): operation.base
        }
    }
}

/// Why a local Products operation cannot be applied to the current remote state.
enum ProductSyncConflictReason: String, Codable, Equatable {
    case baseChanged
    case causalPredecessorMissing
    case operationIdentityMismatch
    case tombstoneRequiresExplicitRestore
}

/// Invalid sync metadata that must never be advanced or silently repaired.
enum ProductSyncPolicyError: Error, Codable, Equatable {
    case entityIdentityMismatch
    case invalidRemoteRevision
    case remoteRevisionOverflow
    case invalidChangeSequence
    case changeSequenceOverflow
}

/// The deterministic remote action selected for one immutable Products operation.
enum ProductRemoteMutationDecision: Codable, Equatable {
    /// Commit the supplied next authoritative record after assigning its feed sequence.
    case apply(ProductRemoteRecord)

    /// The desired operation or deletion is already authoritative remotely.
    case alreadyApplied(ProductRemoteRecord)

    /// Preserve both snapshots for explicit conflict resolution.
    case conflict(ProductSyncConflictReason, ProductRemoteRecord?)

    /// Reject invalid metadata without writing or discarding local work.
    case invalid(ProductSyncPolicyError)
}

/// The remotely acknowledged outcome returned after a mutation attempt.
enum ProductRemoteMutationResult: Codable, Equatable {
    case applied(ProductRemoteRecord)
    case alreadyApplied(ProductRemoteRecord)
    case conflict(ProductSyncConflictReason, ProductRemoteRecord?)
}
