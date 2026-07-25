import Foundation
import SwiftData

/// A durable Clients upsert awaiting remote convergence.
///
/// One row is retained per client. Its operation identifier and versioned payload form
/// an immutable retry pair: an identical write preserves both, while a changed write
/// replaces both before the surrounding context is saved.
@Model
final class ClientPendingUpsertModel {
    @Attribute(.unique) private(set) var clientID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var payloadVersion: Int
    private(set) var payloadData: Data

    init(
        clientID: UUID,
        operationID: UUID,
        payloadVersion: Int,
        payloadData: Data
    ) {
        self.clientID = clientID
        self.operationID = operationID
        self.payloadVersion = payloadVersion
        self.payloadData = payloadData
    }
}

extension ClientPendingUpsertModel {
    /// Creates the first supported durable payload for a client upsert.
    ///
    /// - Parameters:
    ///   - clientID: The stable entity identifier this operation replaces remotely.
    ///   - operationID: The identifier reused by every retry of this payload.
    ///   - payload: The immutable transport snapshot associated with the operation.
    /// - Throws: An encoding error when the transport snapshot cannot be serialized.
    convenience init(
        clientID: UUID,
        operationID: UUID,
        payload: ClientDTO
    ) throws {
        self.init(
            clientID: clientID,
            operationID: operationID,
            payloadVersion: 1,
            payloadData: try JSONEncoder().encode(payload)
        )
    }

    /// Decodes the immutable transport snapshot owned by this operation.
    ///
    /// - Returns: The client payload that every retry of `operationID` must send.
    /// - Throws: `ClientPendingUpsertPayloadError` for an unsupported version, or the
    ///   native decoding error for malformed persisted data.
    func decodePayload() throws -> ClientDTO {
        guard payloadVersion == 1 else {
            throw ClientPendingUpsertPayloadError.unsupportedVersion(
                payloadVersion
            )
        }

        return try JSONDecoder().decode(ClientDTO.self, from: payloadData)
    }

    /// Replaces the retry pair after the client receives a semantically different edit.
    ///
    /// Encoding completes before either stored value changes, so a failure cannot leave
    /// an operation identifier paired with the previous payload.
    ///
    /// - Parameters:
    ///   - operationID: The new identifier for the changed payload.
    ///   - payload: The changed transport snapshot.
    /// - Throws: An encoding error when the changed snapshot cannot be serialized.
    func replaceRetryPair(
        operationID: UUID,
        payload: ClientDTO
    ) throws {
        let encodedPayload = try JSONEncoder().encode(payload)

        self.operationID = operationID
        payloadVersion = 1
        payloadData = encodedPayload
    }
}

/// Failures that prevent a persisted pending upsert from being interpreted safely.
enum ClientPendingUpsertPayloadError: Error, Equatable {
    case unsupportedVersion(Int)
}
