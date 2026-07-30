import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale synchronization policy")
struct SaleSyncPolicyTests {
    private let policy = SaleSyncPolicy()

    @Test("The same operation and whole snapshot is idempotent")
    func sameOperationAndSnapshotIsIdempotent() throws {
        let sale = try syncPolicySale(progressed: false)
        let operationID = syncPolicyUUID("30000000-0000-0000-0000-000000000001")
        let operation = SalePendingOperation.upsert(
            SalePendingUpsert(
                saleID: sale.id.rawValue,
                operationID: operationID,
                predecessorOperationID: nil,
                base: .absent,
                sale: try SaleDTO(sale)
            )
        )
        let remote = SaleRemoteRecord(
            sale: try SaleDTO(sale),
            version: .versioned(revision: 1, lastOperationID: operationID)
        )

        #expect(policy.decision(for: operation, against: remote) == .alreadyApplied(remote))
    }

    @Test("Reusing an operation identity for another snapshot is a conflict")
    func operationIdentityWithDifferentSnapshotIsConflict() throws {
        let local = try syncPolicySale(progressed: false, name: "Local")
        let remoteSale = try syncPolicySale(progressed: false, name: "Remote")
        let operationID = syncPolicyUUID("30000000-0000-0000-0000-000000000002")
        let operation = SalePendingOperation.upsert(
            SalePendingUpsert(
                saleID: local.id.rawValue,
                operationID: operationID,
                predecessorOperationID: nil,
                base: .absent,
                sale: try SaleDTO(local)
            )
        )
        let remote = SaleRemoteRecord(
            sale: try SaleDTO(remoteSale),
            version: .versioned(revision: 1, lastOperationID: operationID)
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .conflict(.operationIdentityMismatch, remote)
        )
    }

    @Test("A concurrent whole-snapshot branch is retained as a conflict")
    func concurrentWholeSnapshotBranchIsConflict() throws {
        let local = try syncPolicySale(progressed: false, name: "Local")
        let remoteSale = try syncPolicySale(progressed: false, name: "Remote")
        let baseOperationID = syncPolicyUUID("30000000-0000-0000-0000-000000000003")
        let operation = SalePendingOperation.upsert(
            SalePendingUpsert(
                saleID: local.id.rawValue,
                operationID: syncPolicyUUID("30000000-0000-0000-0000-000000000004"),
                predecessorOperationID: baseOperationID,
                base: .versioned(1),
                sale: try SaleDTO(local)
            )
        )
        let remote = SaleRemoteRecord(
            sale: try SaleDTO(remoteSale),
            version: .versioned(
                revision: 2,
                lastOperationID: syncPolicyUUID("30000000-0000-0000-0000-000000000005")
            )
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .conflict(.causalPredecessorMissing, remote)
        )
    }

    @Test("Discard applies only while the authoritative Sale remains a draft")
    func discardAppliesOnlyToAuthoritativeDraft() throws {
        let draft = try syncPolicySale(progressed: false)
        let progressed = try syncPolicySale(progressed: true)
        let operation = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: draft.id.rawValue,
                operationID: syncPolicyUUID("30000000-0000-0000-0000-000000000006"),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let draftRemote = SaleRemoteRecord(
            sale: try SaleDTO(draft),
            version: .versioned(
                revision: 1,
                lastOperationID: syncPolicyUUID("30000000-0000-0000-0000-000000000007")
            )
        )
        let progressedRemote = SaleRemoteRecord(
            sale: try SaleDTO(progressed),
            version: draftRemote.version
        )

        guard case .apply(let tombstone) = policy.decision(
            for: operation,
            against: draftRemote
        ) else {
            Issue.record("Expected draft discard to apply")
            return
        }
        #expect(tombstone.isTombstone)
        #expect(
            policy.decision(for: operation, against: progressedRemote)
                == .conflict(.discardRequiresDraft, progressedRemote)
        )
    }

    @Test("Draft discard still requires its captured base and causal predecessor")
    func draftDiscardRequiresBaseAndPredecessor() throws {
        let draft = try syncPolicySale(progressed: false)
        let remoteOperationID = syncPolicyUUID(
            "30000000-0000-0000-0000-000000000008"
        )
        let concurrentDraft = SaleRemoteRecord(
            sale: try SaleDTO(draft),
            version: .versioned(
                revision: 2,
                lastOperationID: remoteOperationID
            )
        )
        let staleRoot = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: draft.id.rawValue,
                operationID: syncPolicyUUID(
                    "30000000-0000-0000-0000-000000000009"
                ),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let divergentDescendant = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: draft.id.rawValue,
                operationID: syncPolicyUUID(
                    "30000000-0000-0000-0000-000000000010"
                ),
                predecessorOperationID: syncPolicyUUID(
                    "30000000-0000-0000-0000-000000000011"
                ),
                base: .versioned(1)
            )
        )
        let matchingDescendant = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: draft.id.rawValue,
                operationID: syncPolicyUUID(
                    "30000000-0000-0000-0000-000000000012"
                ),
                predecessorOperationID: remoteOperationID,
                base: .versioned(1)
            )
        )

        #expect(
            policy.decision(for: staleRoot, against: concurrentDraft)
                == .conflict(.baseChanged, concurrentDraft)
        )
        #expect(
            policy.decision(for: divergentDescendant, against: concurrentDraft)
                == .conflict(.causalPredecessorMissing, concurrentDraft)
        )
        guard case .apply(let tombstone) = policy.decision(
            for: matchingDescendant,
            against: concurrentDraft
        ) else {
            Issue.record("Expected a causally matching draft discard to apply")
            return
        }
        #expect(tombstone.isTombstone)
    }
}

private func syncPolicySale(progressed: Bool, name: String = "Snapshot") throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(rawValue: syncPolicyUUID("31000000-0000-0000-0000-000000000001")),
        serviceID: ServiceID(rawValue: syncPolicyUUID("31000000-0000-0000-0000-000000000002")),
        serviceName: name,
        quantity: 1,
        unitPrice: Money(amount: 10, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
    var sale = try Sale.draft(
        id: SaleID(rawValue: syncPolicyUUID("31000000-0000-0000-0000-000000000003")),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 1),
        lines: [line]
    )
    if progressed {
        try sale.start()
    }
    return sale
}

private func syncPolicyUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
