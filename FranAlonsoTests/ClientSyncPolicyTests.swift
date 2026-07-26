import Foundation
import Testing
@testable import FranAlonso

@Suite("Clients synchronization policy")
struct ClientSyncPolicyTests {
    private let policy = ClientSyncPolicy()

    @Test("An absent root is applied with the first authoritative revision")
    func absentRootIsAppliedWithFirstRevision() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000001",
            client: syncClient(name: "First local snapshot"),
            base: .absent
        )

        #expect(
            policy.decision(for: operation, against: nil) == .apply(
                ClientRemoteRecord(
                    client: operation.client,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("A successor cannot skip its predecessor even when its inherited base matches")
    func successorCannotSkipItsPredecessor() {
        let predecessorID = syncUUID("51000000-0000-0000-0000-000000000002")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000003",
            client: syncClient(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .versioned(4)
        )
        let remote = ClientRemoteRecord(
            client: syncClient(name: "Unrelated remote"),
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
    func successorAdvancesOnlyAfterItsPredecessor() {
        let predecessorID = syncUUID("51000000-0000-0000-0000-000000000005")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000006",
            client: syncClient(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .absent
        )
        let remote = ClientRemoteRecord(
            client: syncClient(name: "Predecessor"),
            version: .versioned(
                revision: 8,
                lastOperationID: predecessorID
            )
        )

        #expect(
            policy.decision(for: operation, against: remote) == .apply(
                ClientRemoteRecord(
                    client: operation.client,
                    version: .versioned(
                        revision: 9,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("The same operation and payload is already applied")
    func sameOperationAndPayloadIsAlreadyApplied() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000007",
            client: syncClient(name: "Stable snapshot"),
            base: .versioned(2)
        )
        let remote = ClientRemoteRecord(
            client: operation.client,
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
    func sameOperationWithAnotherPayloadIsIdentityConflict() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000008",
            client: syncClient(name: "Local payload"),
            base: .versioned(2)
        )
        let remote = ClientRemoteRecord(
            client: syncClient(name: "Different payload"),
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
    func legacyBaseMustStillMatchItsExactSnapshot() {
        let baseClient = syncClient(name: "Known legacy snapshot")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000009",
            client: syncClient(name: "Local edit"),
            base: .legacy(baseClient)
        )
        let changedLegacy = ClientRemoteRecord(
            client: syncClient(name: "Changed by a legacy writer"),
            version: .legacy
        )

        #expect(
            policy.decision(for: operation, against: changedLegacy)
                == .conflict(.baseChanged, changedLegacy)
        )
        #expect(
            policy.decision(
                for: operation,
                against: ClientRemoteRecord(
                    client: baseClient,
                    version: .legacy
                )
            ) == .apply(
                ClientRemoteRecord(
                    client: operation.client,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("The maximum remote revision cannot overflow")
    func maximumRemoteRevisionCannotOverflow() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000010",
            client: syncClient(name: "Overflow"),
            base: .versioned(Int64.max)
        )
        let remote = ClientRemoteRecord(
            client: syncClient(name: "Remote maximum"),
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
}

private func syncOperation(
    id: String,
    client: ClientDTO,
    predecessorOperationID: UUID? = nil,
    base: ClientRemoteBase
) -> ClientPendingUpsert {
    ClientPendingUpsert(
        clientID: UUID(uuidString: client.id)!,
        operationID: syncUUID(id),
        predecessorOperationID: predecessorOperationID,
        base: base,
        client: client
    )
}

private func syncClient(name: String) -> ClientDTO {
    ClientDTO(
        id: "50000000-0000-0000-0000-000000000001",
        displayName: name,
        taxIdentifier: nil,
        billingAddress: nil,
        status: .draft,
        consentReference: nil
    )
}

private func syncUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
