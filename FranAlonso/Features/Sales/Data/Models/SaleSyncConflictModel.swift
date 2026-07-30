import Foundation
import SwiftData

/// Both snapshots required to resolve one Sales synchronization conflict explicitly.
@Model
final class SaleSyncConflictModel {
    @Attribute(.unique) private(set) var saleID: UUID
    private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var operationKindRawValue: String
    private(set) var reasonRawValue: String
    private(set) var payloadVersion: Int
    private(set) var baseData: Data
    private(set) var localSaleData: Data?
    private(set) var remoteRecordData: Data?

    init(
        saleID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        operationKindRawValue: String,
        reasonRawValue: String,
        payloadVersion: Int,
        baseData: Data,
        localSaleData: Data?,
        remoteRecordData: Data?
    ) {
        self.saleID = saleID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.operationKindRawValue = operationKindRawValue
        self.reasonRawValue = reasonRawValue
        self.payloadVersion = payloadVersion
        self.baseData = baseData
        self.localSaleData = localSaleData
        self.remoteRecordData = remoteRecordData
    }
}

extension SaleSyncConflictModel {
    /// Creates the first supported durable conflict payload.
    ///
    /// - Parameters:
    ///   - operation: The local operation that could not advance.
    ///   - reason: The deterministic policy reason for the conflict.
    ///   - remoteRecord: The remote state observed by the failed attempt, when present.
    /// - Throws: An encoding error when any snapshot cannot be serialized.
    convenience init(
        operation: SalePendingOperation,
        reason: SaleSyncConflictReason,
        remoteRecord: SaleRemoteRecord?
    ) throws {
        self.init(
            saleID: operation.saleID,
            operationID: operation.operationID,
            predecessorOperationID: operation.predecessorOperationID,
            operationKindRawValue: operation.kindRawValue,
            reasonRawValue: reason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(operation.base),
            localSaleData: try operation.localSale.map { sale in
                try JSONEncoder().encode(sale)
            },
            remoteRecordData: try remoteRecord.map { record in
                try JSONEncoder().encode(record)
            }
        )
    }

    /// Replaces a conflict after all new snapshots encode successfully.
    func update(
        operation: SalePendingOperation,
        reason: SaleSyncConflictReason,
        remoteRecord: SaleRemoteRecord?
    ) throws {
        guard operation.saleID == saleID else {
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
        let encodedBase = try JSONEncoder().encode(operation.base)
        let encodedLocalSale = try operation.localSale.map { sale in
            try JSONEncoder().encode(sale)
        }
        let encodedRemoteRecord = try remoteRecord.map { record in
            try JSONEncoder().encode(record)
        }

        operationID = operation.operationID
        predecessorOperationID = operation.predecessorOperationID
        operationKindRawValue = operation.kindRawValue
        reasonRawValue = reason.rawValue
        payloadVersion = 1
        baseData = encodedBase
        localSaleData = encodedLocalSale
        remoteRecordData = encodedRemoteRecord
    }

    /// Decodes the stable conflict classification retained for resolution.
    func decodeReason() throws -> SaleSyncConflictReason {
        guard let reason = SaleSyncConflictReason(rawValue: reasonRawValue) else {
            throw SaleSyncPersistenceError.invalidConflictReason(
                reasonRawValue
            )
        }
        return reason
    }

    /// Decodes the remote base against which the blocked local operation was created.
    func decodeBase() throws -> SaleRemoteBase {
        try requireSupportedVersion()
        return try JSONDecoder().decode(SaleRemoteBase.self, from: baseData)
    }

    /// Decodes the complete local snapshot that could not be applied.
    func decodeLocalSale() throws -> SaleDTO? {
        try requireSupportedVersion()
        return try localSaleData.map { data in
            try JSONDecoder().decode(SaleDTO.self, from: data)
        }
    }

    /// Reconstructs the complete local operation retained for resolution.
    func decodeOperation() throws -> SalePendingOperation {
        let base = try decodeBase()
        switch operationKindRawValue {
        case "upsert":
            guard let sale = try decodeLocalSale() else {
                throw SaleSyncPersistenceError.invalidConflictOperation
            }
            return .upsert(
                SalePendingUpsert(
                    saleID: saleID,
                    operationID: operationID,
                    predecessorOperationID: predecessorOperationID,
                    base: base,
                    sale: sale
                )
            )
        case "discard":
            guard localSaleData == nil else {
                throw SaleSyncPersistenceError.invalidConflictOperation
            }
            return .discard(
                SalePendingDiscard(
                    saleID: saleID,
                    operationID: operationID,
                    predecessorOperationID: predecessorOperationID,
                    base: base
                )
            )
        default:
            throw SaleSyncPersistenceError.invalidConflictOperation
        }
    }

    /// Decodes the complete remote snapshot observed by the conflicting attempt.
    func decodeRemoteRecord() throws -> SaleRemoteRecord? {
        try requireSupportedVersion()
        return try remoteRecordData.map { data in
            try JSONDecoder().decode(SaleRemoteRecord.self, from: data)
        }
    }

    private func requireSupportedVersion() throws {
        guard payloadVersion == 1 else {
            throw SaleSyncPersistenceError.unsupportedConflictVersion(
                payloadVersion
            )
        }
    }
}

/// Failures that prevent persisted Sales synchronization state from being trusted.
enum SaleSyncPersistenceError: Error, Equatable {
    case ambiguousPendingLineage(SaleID)
    case cyclicPendingLineage(SaleID)
    case duplicateOperationIdentity(UUID)
    case entityIdentityMismatch
    case invalidCursor
    case invalidConflictReason(String)
    case invalidConflictOperation
    case unsupportedConflictVersion(Int)
    case unsupportedRecordVersion(Int)
}

private extension SalePendingOperation {
    var kindRawValue: String {
        switch self {
        case .upsert: "upsert"
        case .discard: "discard"
        }
    }

    var localSale: SaleDTO? {
        guard case .upsert(let upsert) = self else { return nil }
        return upsert.sale
    }
}

extension SaleDTO {
    /// Returns the canonical UUID carried by this transport snapshot.
    ///
    /// - Throws: `SaleSyncPersistenceError.entityIdentityMismatch` when `id` is invalid.
    func stableUUID() throws -> UUID {
        guard let identifier = UUID(uuidString: id) else {
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
        return identifier
    }
}
