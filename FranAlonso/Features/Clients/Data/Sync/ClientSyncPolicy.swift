import Foundation

/// Applies the accepted Clients conflict and causal-delivery rules without side effects.
struct ClientSyncPolicy {
    /// Selects the only safe remote action for an immutable local operation.
    ///
    /// Successors must observe their direct predecessor remotely and cannot fall back to
    /// an inherited base. Root operations instead compare the exact absent, legacy or
    /// versioned state captured when the local edit was accepted.
    ///
    /// - Parameters:
    ///   - operation: The immutable local operation to evaluate.
    ///   - remoteRecord: The current document read inside the remote transaction.
    /// - Returns: A deterministic apply, idempotent, conflict or invalid decision.
    func decision(
        for operation: ClientPendingUpsert,
        against remoteRecord: ClientRemoteRecord?
    ) -> ClientRemoteUpsertDecision {
        guard identifiersMatch(operation, remoteRecord: remoteRecord) else {
            return .invalid(.entityIdentityMismatch)
        }

        if case .versioned(let revision, let lastOperationID) = remoteRecord?.version {
            guard revision > 0 else {
                return .invalid(.invalidRemoteRevision)
            }

            if lastOperationID == operation.operationID {
                guard let remoteRecord else {
                    return .invalid(.entityIdentityMismatch)
                }
                guard remoteRecord.client == operation.client else {
                    return .conflict(
                        .operationIdentityMismatch,
                        remoteRecord
                    )
                }

                return .alreadyApplied(remoteRecord)
            }
        }

        if let predecessorOperationID = operation.predecessorOperationID {
            guard remoteRecord?.lastOperationID == predecessorOperationID else {
                return .conflict(.causalPredecessorMissing, remoteRecord)
            }

            return nextRecord(for: operation, after: remoteRecord)
        }

        guard rootBaseMatches(operation.base, remoteRecord: remoteRecord) else {
            return .conflict(.baseChanged, remoteRecord)
        }

        return nextRecord(for: operation, after: remoteRecord)
    }

    private func identifiersMatch(
        _ operation: ClientPendingUpsert,
        remoteRecord: ClientRemoteRecord?
    ) -> Bool {
        guard UUID(uuidString: operation.client.id) == operation.clientID else {
            return false
        }

        guard let remoteRecord else {
            return true
        }

        return UUID(uuidString: remoteRecord.client.id) == operation.clientID
    }

    private func rootBaseMatches(
        _ base: ClientRemoteBase,
        remoteRecord: ClientRemoteRecord?
    ) -> Bool {
        switch (base, remoteRecord) {
        case (.absent, nil):
            return true
        case (.legacy(let baseClient), .some(let record)):
            return record.version == .legacy && record.client == baseClient
        case (.versioned(let baseRevision), .some(let record)):
            guard baseRevision > 0 else {
                return false
            }
            return record.revision == baseRevision
        default:
            return false
        }
    }

    private func nextRecord(
        for operation: ClientPendingUpsert,
        after remoteRecord: ClientRemoteRecord?
    ) -> ClientRemoteUpsertDecision {
        let currentRevision: Int64
        switch remoteRecord?.version {
        case nil, .legacy:
            currentRevision = 0
        case .versioned(let revision, _):
            guard revision > 0 else {
                return .invalid(.invalidRemoteRevision)
            }
            guard revision < Int64.max else {
                return .invalid(.remoteRevisionOverflow)
            }
            currentRevision = revision
        }

        return .apply(
            ClientRemoteRecord(
                client: operation.client,
                version: .versioned(
                    revision: currentRevision + 1,
                    lastOperationID: operation.operationID
                )
            )
        )
    }
}

private extension ClientRemoteRecord {
    var revision: Int64? {
        guard case .versioned(let revision, _) = version else {
            return nil
        }
        return revision
    }

    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else {
            return nil
        }
        return lastOperationID
    }
}
