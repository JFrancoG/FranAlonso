import Foundation
import Testing
@testable import FranAlonso

@Suite("Services synchronization policy")
struct ServiceSyncPolicyTests {
    private let policy = ServiceSyncPolicy()

    @Test("An absent root is applied with the first authoritative revision")
    func absentRootIsAppliedWithFirstRevision() throws {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000001",
            service: try syncService(name: "First local snapshot"),
            base: .absent
        )

        #expect(
            policy.decision(for: operation, against: nil) == .apply(
                ServiceRemoteRecord(
                    service: operation.service,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("A successor cannot skip its predecessor even when its inherited base matches")
    func successorCannotSkipItsPredecessor() throws {
        let predecessorID = syncUUID("51000000-0000-0000-0000-000000000002")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000003",
            service: try syncService(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .versioned(4)
        )
        let remote = ServiceRemoteRecord(
            service: try syncService(name: "Unrelated remote"),
            version: .versioned(
                revision: 4,
                lastOperationID: syncUUID(
                    "51000000-0000-0000-0000-000000000004"
                )
            )
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .conflict(.causalPredecessorMissing, remote)
        )
    }

    @Test("A successor advances only after its predecessor")
    func successorAdvancesOnlyAfterItsPredecessor() throws {
        let predecessorID = syncUUID("51000000-0000-0000-0000-000000000005")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000006",
            service: try syncService(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .absent
        )
        let remote = ServiceRemoteRecord(
            service: try syncService(name: "Predecessor"),
            version: .versioned(
                revision: 8,
                lastOperationID: predecessorID
            )
        )

        #expect(
            policy.decision(for: operation, against: remote) == .apply(
                ServiceRemoteRecord(
                    service: operation.service,
                    version: .versioned(
                        revision: 9,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("The same operation and payload is already applied")
    func sameOperationAndPayloadIsAlreadyApplied() throws {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000007",
            service: try syncService(name: "Stable snapshot"),
            base: .versioned(2)
        )
        let remote = ServiceRemoteRecord(
            service: operation.service,
            version: .versioned(
                revision: 3,
                lastOperationID: operation.operationID
            )
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .alreadyApplied(remote)
        )
    }

    @Test("The same operation with another payload is an identity conflict")
    func sameOperationWithAnotherPayloadIsIdentityConflict() throws {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000008",
            service: try syncService(name: "Local payload"),
            base: .versioned(2)
        )
        let remote = ServiceRemoteRecord(
            service: try syncService(name: "Different payload"),
            version: .versioned(
                revision: 3,
                lastOperationID: operation.operationID
            )
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .conflict(.operationIdentityMismatch, remote)
        )
    }

    @Test("A legacy base must still match its exact business snapshot")
    func legacyBaseMustStillMatchItsExactSnapshot() throws {
        let baseService = try syncService(name: "Known legacy snapshot")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000009",
            service: try syncService(name: "Local edit"),
            base: .legacy(baseService)
        )
        let changedLegacy = ServiceRemoteRecord(
            service: try syncService(name: "Changed by a legacy writer"),
            version: .legacy
        )

        #expect(
            policy.decision(for: operation, against: changedLegacy)
                == .conflict(.baseChanged, changedLegacy)
        )
        #expect(
            policy.decision(
                for: operation,
                against: ServiceRemoteRecord(
                    service: baseService,
                    version: .legacy
                )
            ) == .apply(
                ServiceRemoteRecord(
                    service: operation.service,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("The maximum remote revision cannot overflow")
    func maximumRemoteRevisionCannotOverflow() throws {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000010",
            service: try syncService(name: "Overflow"),
            base: .versioned(Int64.max)
        )
        let remote = ServiceRemoteRecord(
            service: try syncService(name: "Remote maximum"),
            version: .versioned(
                revision: Int64.max,
                lastOperationID: syncUUID(
                    "51000000-0000-0000-0000-000000000011"
                )
            )
        )

        #expect(
            policy.decision(for: operation, against: remote)
                == .invalid(.remoteRevisionOverflow)
        )
    }

    @Test("A pending delete wins over a concurrent remote edit")
    func pendingDeleteWinsOverConcurrentRemoteEdit() throws {
        let delete = syncDeleteOperation(
            id: "51000000-0000-0000-0000-000000000012",
            base: .versioned(3)
        )
        let remote = ServiceRemoteRecord(
            service: try syncService(name: "Concurrent remote edit"),
            version: .versioned(
                revision: 4,
                lastOperationID: syncUUID(
                    "51000000-0000-0000-0000-000000000013"
                )
            ),
            changeSequence: 6
        )

        #expect(
            policy.decision(for: .delete(delete), against: remote)
                == .apply(
                    ServiceRemoteRecord(
                        content: .tombstone(serviceID: delete.serviceID),
                        version: .versioned(
                            revision: 5,
                            lastOperationID: delete.operationID
                        ),
                        changeSequence: nil
                    )
                )
        )
    }

    @Test("Any remote tombstone requires explicit restoration before an upsert")
    func remoteTombstoneBlocksOrdinaryUpsert() throws {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000014",
            service: try syncService(name: "Accidental restore"),
            base: .versioned(2)
        )
        let tombstone = ServiceRemoteRecord(
            content: .tombstone(serviceID: operation.serviceID),
            version: .versioned(
                revision: 3,
                lastOperationID: syncUUID(
                    "51000000-0000-0000-0000-000000000015"
                )
            ),
            changeSequence: 7
        )

        #expect(
            policy.decision(for: operation, against: tombstone)
                == .conflict(
                    .tombstoneRequiresExplicitRestore,
                    tombstone
                )
        )
    }

    @Test("A remote tombstone makes a repeated deletion converged")
    func remoteTombstoneMakesRepeatedDeleteConverged() {
        let delete = syncDeleteOperation(
            id: "51000000-0000-0000-0000-000000000016",
            base: .absent
        )
        let tombstone = ServiceRemoteRecord(
            content: .tombstone(serviceID: delete.serviceID),
            version: .versioned(
                revision: 8,
                lastOperationID: syncUUID(
                    "51000000-0000-0000-0000-000000000017"
                )
            ),
            changeSequence: 9
        )

        #expect(
            policy.decision(for: .delete(delete), against: tombstone)
                == .alreadyApplied(tombstone)
        )
    }
}

private func syncOperation(
    id: String,
    service: ServiceDTO,
    predecessorOperationID: UUID? = nil,
    base: ServiceRemoteBase
) -> ServicePendingUpsert {
    ServicePendingUpsert(
        serviceID: UUID(uuidString: service.id)!,
        operationID: syncUUID(id),
        predecessorOperationID: predecessorOperationID,
        base: base,
        service: service
    )
}

private func syncDeleteOperation(id: String, base: ServiceRemoteBase) -> ServicePendingDelete {
    ServicePendingDelete(
        serviceID: UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!,
        operationID: syncUUID(id),
        predecessorOperationID: nil,
        base: base
    )
}

private func syncService(name: String) throws -> ServiceDTO {
    try makeServiceDTO(
        id: UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!,
        name: name,
        discountPercentage: nil
    )
}

private func syncUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
