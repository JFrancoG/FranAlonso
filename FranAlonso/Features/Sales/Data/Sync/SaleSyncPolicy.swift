import Foundation

/// Applies the accepted Sales conflict, tombstone and causal-delivery rules without effects.
struct SaleSyncPolicy {
    /// Selects the only safe remote action for an immutable local operation.
    ///
    /// A discard applies only while the authoritative aggregate is still a draft. Upserts can
    /// never restore a tombstone without a future explicit restore operation.
    ///
    /// - Parameters:
    ///   - operation: The immutable local operation to evaluate.
    ///   - remoteRecord: The current document read inside the remote transaction.
    /// - Returns: A deterministic apply, idempotent, conflict or invalid decision.
    func decision(
        for operation: SalePendingOperation,
        against remoteRecord: SaleRemoteRecord?
    ) -> SaleRemoteMutationDecision {
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
        case .discard:
            if let remoteRecord, remoteRecord.isTombstone {
                return .alreadyApplied(remoteRecord)
            }
            if let remoteSale = remoteRecord?.liveSale {
                guard let sale = try? remoteSale.toDomain() else {
                    return .invalid(.invalidSalePayload)
                }
                guard sale.status == .draft else {
                    return .conflict(.discardRequiresDraft, remoteRecord)
                }
            }
            break
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
        for operation: SalePendingUpsert,
        against remoteRecord: SaleRemoteRecord?
    ) -> SaleRemoteMutationDecision {
        decision(for: .upsert(operation), against: remoteRecord)
    }

    private func identifiersMatch(
        _ operation: SalePendingOperation,
        remoteRecord: SaleRemoteRecord?
    ) -> Bool {
        switch operation {
        case .upsert(let upsert):
            guard UUID(uuidString: upsert.sale.id) == upsert.saleID else {
                return false
            }
        case .discard:
            break
        }

        guard let remoteRecord else {
            return true
        }
        return UUID(uuidString: remoteRecord.id) == operation.saleID
    }

    private func rootBaseMatches(
        _ base: SaleRemoteBase,
        remoteRecord: SaleRemoteRecord?
    ) -> Bool {
        switch (base, remoteRecord) {
        case (.absent, nil):
            true
        case (.legacy(let baseSale), .some(let record)):
            record.version == .legacy && record.liveSale == baseSale
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
        for operation: SalePendingOperation,
        after remoteRecord: SaleRemoteRecord?
    ) -> SaleRemoteMutationDecision {
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
            SaleRemoteRecord(
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
        for operation: SalePendingOperation
    ) -> SaleRemoteContent {
        switch operation {
        case .upsert(let upsert):
            .live(upsert.sale)
        case .discard(let discard):
            .tombstone(saleID: discard.saleID)
        }
    }
}

private extension SaleRemoteRecord {
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
