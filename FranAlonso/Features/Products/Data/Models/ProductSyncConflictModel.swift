import Foundation
import SwiftData

/// Both snapshots required to resolve one Products synchronization conflict explicitly.
@Model
final class ProductSyncConflictModel {
    @Attribute(.unique) private(set) var productID: UUID
    private(set) var operationID: UUID
    private(set) var reasonRawValue: String
    private(set) var payloadVersion: Int
    private(set) var baseData: Data
    private(set) var localProductData: Data
    private(set) var remoteRecordData: Data?

    init(
        productID: UUID,
        operationID: UUID,
        reasonRawValue: String,
        payloadVersion: Int,
        baseData: Data,
        localProductData: Data,
        remoteRecordData: Data?
    ) {
        self.productID = productID
        self.operationID = operationID
        self.reasonRawValue = reasonRawValue
        self.payloadVersion = payloadVersion
        self.baseData = baseData
        self.localProductData = localProductData
        self.remoteRecordData = remoteRecordData
    }
}

extension ProductSyncConflictModel {
    /// Creates the first supported durable conflict payload.
    ///
    /// - Parameters:
    ///   - operation: The local operation that could not advance.
    ///   - reason: The deterministic policy reason for the conflict.
    ///   - remoteRecord: The remote state observed by the failed attempt, when present.
    /// - Throws: An encoding error when any snapshot cannot be serialized.
    convenience init(
        operation: ProductPendingUpsert,
        reason: ProductSyncConflictReason,
        remoteRecord: ProductRemoteRecord?
    ) throws {
        self.init(
            productID: operation.productID,
            operationID: operation.operationID,
            reasonRawValue: reason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(operation.base),
            localProductData: try JSONEncoder().encode(operation.product),
            remoteRecordData: try remoteRecord.map { record in
                try JSONEncoder().encode(record)
            }
        )
    }

    /// Replaces a conflict after all new snapshots encode successfully.
    func update(
        operation: ProductPendingUpsert,
        reason: ProductSyncConflictReason,
        remoteRecord: ProductRemoteRecord?
    ) throws {
        guard operation.productID == productID else {
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
        let encodedBase = try JSONEncoder().encode(operation.base)
        let encodedLocalProduct = try JSONEncoder().encode(operation.product)
        let encodedRemoteRecord = try remoteRecord.map { record in
            try JSONEncoder().encode(record)
        }

        operationID = operation.operationID
        reasonRawValue = reason.rawValue
        payloadVersion = 1
        baseData = encodedBase
        localProductData = encodedLocalProduct
        remoteRecordData = encodedRemoteRecord
    }

    /// Decodes the stable conflict classification retained for resolution.
    func decodeReason() throws -> ProductSyncConflictReason {
        guard let reason = ProductSyncConflictReason(rawValue: reasonRawValue) else {
            throw ProductSyncPersistenceError.invalidConflictReason(
                reasonRawValue
            )
        }
        return reason
    }

    /// Decodes the remote base against which the blocked local operation was created.
    func decodeBase() throws -> ProductRemoteBase {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ProductRemoteBase.self, from: baseData)
    }

    /// Decodes the complete local snapshot that could not be applied.
    func decodeLocalProduct() throws -> ProductDTO {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ProductDTO.self, from: localProductData)
    }

    /// Decodes the complete remote snapshot observed by the conflicting attempt.
    func decodeRemoteRecord() throws -> ProductRemoteRecord? {
        try requireSupportedVersion()
        return try remoteRecordData.map { data in
            try JSONDecoder().decode(ProductRemoteRecord.self, from: data)
        }
    }

    private func requireSupportedVersion() throws {
        guard payloadVersion == 1 else {
            throw ProductSyncPersistenceError.unsupportedConflictVersion(
                payloadVersion
            )
        }
    }
}

/// Failures that prevent persisted Products synchronization state from being trusted.
enum ProductSyncPersistenceError: Error, Equatable {
    case ambiguousPendingLineage(ProductID)
    case cyclicPendingLineage(ProductID)
    case duplicateOperationIdentity(UUID)
    case entityIdentityMismatch
    case invalidCursor
    case invalidConflictReason(String)
    case unsupportedConflictVersion(Int)
    case unsupportedRecordVersion(Int)
}

extension ProductDTO {
    /// Returns the canonical UUID carried by this transport snapshot.
    ///
    /// - Throws: `ProductSyncPersistenceError.entityIdentityMismatch` when `id` is invalid.
    func stableUUID() throws -> UUID {
        guard let identifier = UUID(uuidString: id) else {
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
        return identifier
    }
}
