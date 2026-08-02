import Foundation

/// Applies the accepted Services conflict, tombstone and causal-delivery rules without effects.
struct ServiceSyncPolicy {
    /// Selects the only safe remote action for an immutable local operation.
    ///
    /// Deletes win over concurrent live edits. Upserts can never restore a tombstone without
    /// a future explicit restore operation. Other upserts preserve the causal chain.
    ///
    /// - Parameters:
    ///   - operation: The immutable local operation to evaluate.
    ///   - remoteRecord: The current document read inside the remote transaction.
    /// - Returns: A deterministic apply, idempotent, conflict or invalid decision.
    func decision(
        for operation: ServicePendingOperation,
        against remoteRecord: ServiceRemoteRecord?
    ) -> ServiceRemoteMutationDecision {
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

    /// Evaluates an upsert through the unified operation policy.
    func decision(
        for operation: ServicePendingUpsert,
        against remoteRecord: ServiceRemoteRecord?
    ) -> ServiceRemoteMutationDecision {
        decision(for: .upsert(operation), against: remoteRecord)
    }

    private func identifiersMatch(_ operation: ServicePendingOperation, remoteRecord: ServiceRemoteRecord?) -> Bool {
        switch operation {
        case .upsert(let upsert):
            guard UUID(uuidString: upsert.service.id) == upsert.serviceID else { return false }
        case .delete:
            break
        }

        guard let remoteRecord else { return true }
        return UUID(uuidString: remoteRecord.id) == operation.serviceID
    }

    private func rootBaseMatches(_ base: ServiceRemoteBase, remoteRecord: ServiceRemoteRecord?) -> Bool {
        switch (base, remoteRecord) {
        case (.absent, nil):
            true
        case (.legacy(let baseService), .some(let record)):
            record.version == .legacy && record.liveService == baseService
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
        for operation: ServicePendingOperation,
        after remoteRecord: ServiceRemoteRecord?
    ) -> ServiceRemoteMutationDecision {
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
            ServiceRemoteRecord(
                content: desiredContent(for: operation),
                version: .versioned(
                    revision: currentRevision + 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: nil
            )
        )
    }

    private func desiredContent(for operation: ServicePendingOperation) -> ServiceRemoteContent {
        switch operation {
        case .upsert(let upsert):
            .live(upsert.service)
        case .delete(let delete):
            .tombstone(serviceID: delete.serviceID)
        }
    }
}

private extension ServiceRemoteRecord {
    var revision: Int64? {
        guard case .versioned(let revision, _) = version else { return nil }
        return revision
    }

    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else { return nil }
        return lastOperationID
    }
}
