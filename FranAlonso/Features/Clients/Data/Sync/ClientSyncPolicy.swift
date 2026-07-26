import Foundation

/// Applies the accepted Clients conflict, tombstone and causal-delivery rules without effects.
struct ClientSyncPolicy {
    /// Selects the only safe remote action for an immutable local operation.
    ///
    /// Deletes win over concurrent live edits. Upserts can never restore a tombstone without
    /// a future explicit restore operation. Other upserts preserve the causal rules from 05.7.
    ///
    /// - Parameters:
    ///   - operation: The immutable local operation to evaluate.
    ///   - remoteRecord: The current document read inside the remote transaction.
    /// - Returns: A deterministic apply, idempotent, conflict or invalid decision.
    func decision(
        for operation: ClientPendingOperation,
        against remoteRecord: ClientRemoteRecord?
    ) -> ClientRemoteMutationDecision {
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
                guard remoteRecord.content == desiredContent(for: operation) else {
                    return .conflict(
                        .operationIdentityMismatch,
                        remoteRecord
                    )
                }
                return .alreadyApplied(remoteRecord)
            }
        }

        switch operation {
        case .delete:
            if let remoteRecord, remoteRecord.isTombstone {
                return .alreadyApplied(remoteRecord)
            }
            return nextRecord(for: operation, after: remoteRecord)
        case .upsert:
            if let remoteRecord, remoteRecord.isTombstone {
                return .conflict(
                    .tombstoneRequiresExplicitRestore,
                    remoteRecord
                )
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

    /// Preserves the 05.7 upsert call boundary while using the unified operation policy.
    func decision(
        for operation: ClientPendingUpsert,
        against remoteRecord: ClientRemoteRecord?
    ) -> ClientRemoteMutationDecision {
        decision(for: .upsert(operation), against: remoteRecord)
    }

    private func identifiersMatch(
        _ operation: ClientPendingOperation,
        remoteRecord: ClientRemoteRecord?
    ) -> Bool {
        switch operation {
        case .upsert(let upsert):
            guard UUID(uuidString: upsert.client.id) == upsert.clientID else {
                return false
            }
        case .delete:
            break
        }

        guard let remoteRecord else {
            return true
        }
        return UUID(uuidString: remoteRecord.id) == operation.clientID
    }

    private func rootBaseMatches(
        _ base: ClientRemoteBase,
        remoteRecord: ClientRemoteRecord?
    ) -> Bool {
        switch (base, remoteRecord) {
        case (.absent, nil):
            true
        case (.legacy(let baseClient), .some(let record)):
            record.version == .legacy && record.liveClient == baseClient
        case (.versioned(let baseRevision), .some(let record)):
            baseRevision > 0
                && record.isLive
                && record.revision == baseRevision
        case (.tombstone(let baseRevision), .some(let record)):
            baseRevision > 0
                && record.isTombstone
                && record.revision == baseRevision
        default:
            false
        }
    }

    private func nextRecord(
        for operation: ClientPendingOperation,
        after remoteRecord: ClientRemoteRecord?
    ) -> ClientRemoteMutationDecision {
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
                content: desiredContent(for: operation),
                version: .versioned(
                    revision: currentRevision + 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: nil
            )
        )
    }

    private func desiredContent(
        for operation: ClientPendingOperation
    ) -> ClientRemoteContent {
        switch operation {
        case .upsert(let upsert):
            .live(upsert.client)
        case .delete(let delete):
            .tombstone(clientID: delete.clientID)
        }
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
