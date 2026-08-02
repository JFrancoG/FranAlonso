import Foundation
import SwiftData

/// One immutable Services upsert in a durable causal delivery chain.
///
/// Changed local snapshots append a successor instead of mutating an in-flight operation.
/// This lets a remote acknowledgement delete only the exact operation it confirms while a
/// newer edit remains independently durable.
@Model
final class ServicePendingUpsertModel {
    private(set) var serviceID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var baseVersion: Int?
    private(set) var baseData: Data?
    private(set) var payloadVersion: Int
    private(set) var payloadData: Data

    init(
        serviceID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        baseVersion: Int?,
        baseData: Data?,
        payloadVersion: Int,
        payloadData: Data
    ) {
        self.serviceID = serviceID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.baseVersion = baseVersion
        self.baseData = baseData
        self.payloadVersion = payloadVersion
        self.payloadData = payloadData
    }
}

extension ServicePendingUpsertModel {
    /// Creates the first supported durable causal operation for a service upsert.
    ///
    /// - Parameters:
    ///   - serviceID: The stable entity identifier this operation replaces remotely.
    ///   - operationID: The identifier reused by every retry of this payload.
    ///   - predecessorOperationID: The operation that must already be remote, when present.
    ///   - base: The exact remote state captured for a root operation.
    ///   - payload: The immutable transport snapshot associated with the operation.
    /// - Throws: An encoding error when the transport snapshot cannot be serialized.
    convenience init(
        serviceID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID? = nil,
        base: ServiceRemoteBase = .absent,
        payload: ServiceDTO
    ) throws {
        let encodedBase = try JSONEncoder().encode(base)
        let encodedPayload = try JSONEncoder().encode(payload)
        self.init(
            serviceID: serviceID,
            operationID: operationID,
            predecessorOperationID: predecessorOperationID,
            baseVersion: 1,
            baseData: encodedBase,
            payloadVersion: 1,
            payloadData: encodedPayload
        )
    }

    /// Decodes the immutable remote base captured by this operation.
    ///
    /// - Returns: The absent, legacy or versioned state required by a root operation.
    /// - Throws: `ServicePendingUpsertPayloadError` for an unsupported version, or the
    ///   native decoding error for malformed persisted data.
    func decodeBase() throws -> ServiceRemoteBase {
        if baseVersion == nil, baseData == nil {
            return .absent
        }
        guard let baseVersion, let baseData else { throw ServicePendingUpsertPayloadError.incompleteBaseMetadata }
        guard baseVersion == 1 else {
            throw ServicePendingUpsertPayloadError.unsupportedBaseVersion(
                baseVersion
            )
        }

        return try JSONDecoder().decode(ServiceRemoteBase.self, from: baseData)
    }

    /// Decodes the immutable transport snapshot owned by this operation.
    ///
    /// - Returns: The service payload that every retry of `operationID` must send.
    /// - Throws: `ServicePendingUpsertPayloadError` for an unsupported version, or the
    ///   native decoding error for malformed persisted data.
    func decodePayload() throws -> ServiceDTO {
        guard payloadVersion == 1 else {
            throw ServicePendingUpsertPayloadError.unsupportedVersion(
                payloadVersion
            )
        }

        return try JSONDecoder().decode(ServiceDTO.self, from: payloadData)
    }

}

/// Failures that prevent a persisted pending upsert from being interpreted safely.
enum ServicePendingUpsertPayloadError: Error, Equatable {
    case incompleteBaseMetadata
    case unsupportedBaseVersion(Int)
    case unsupportedVersion(Int)
}
