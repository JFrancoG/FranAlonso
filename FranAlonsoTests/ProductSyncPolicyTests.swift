import Foundation
import Testing
@testable import FranAlonso

@Suite("Products synchronization policy")
struct ProductSyncPolicyTests {
    private let policy = ProductSyncPolicy()

    @Test("An absent root is applied with the first authoritative revision")
    func absentRootIsAppliedWithFirstRevision() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000001",
            product: syncProduct(name: "First local snapshot"),
            base: .absent
        )

        #expect(
            policy.decision(for: operation, against: nil) == .apply(
                ProductRemoteRecord(
                    product: operation.product,
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
            product: syncProduct(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .versioned(4)
        )
        let remote = ProductRemoteRecord(
            product: syncProduct(name: "Unrelated remote"),
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
            product: syncProduct(name: "Successor"),
            predecessorOperationID: predecessorID,
            base: .absent
        )
        let remote = ProductRemoteRecord(
            product: syncProduct(name: "Predecessor"),
            version: .versioned(
                revision: 8,
                lastOperationID: predecessorID
            )
        )

        #expect(
            policy.decision(for: operation, against: remote) == .apply(
                ProductRemoteRecord(
                    product: operation.product,
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
            product: syncProduct(name: "Stable snapshot"),
            base: .versioned(2)
        )
        let remote = ProductRemoteRecord(
            product: operation.product,
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
            product: syncProduct(name: "Local payload"),
            base: .versioned(2)
        )
        let remote = ProductRemoteRecord(
            product: syncProduct(name: "Different payload"),
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
        let baseProduct = syncProduct(name: "Known legacy snapshot")
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000009",
            product: syncProduct(name: "Local edit"),
            base: .legacy(baseProduct)
        )
        let changedLegacy = ProductRemoteRecord(
            product: syncProduct(name: "Changed by a legacy writer"),
            version: .legacy
        )

        #expect(
            policy.decision(for: operation, against: changedLegacy)
                == .conflict(.baseChanged, changedLegacy)
        )
        #expect(
            policy.decision(
                for: operation,
                against: ProductRemoteRecord(
                    product: baseProduct,
                    version: .legacy
                )
            ) == .apply(
                ProductRemoteRecord(
                    product: operation.product,
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
            product: syncProduct(name: "Overflow"),
            base: .versioned(Int64.max)
        )
        let remote = ProductRemoteRecord(
            product: syncProduct(name: "Remote maximum"),
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
    func pendingDeleteWinsOverConcurrentRemoteEdit() {
        let delete = syncDeleteOperation(
            id: "51000000-0000-0000-0000-000000000012",
            base: .versioned(3)
        )
        let remote = ProductRemoteRecord(
            product: syncProduct(name: "Concurrent remote edit"),
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
                    ProductRemoteRecord(
                        content: .tombstone(productID: delete.productID),
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
    func remoteTombstoneBlocksOrdinaryUpsert() {
        let operation = syncOperation(
            id: "51000000-0000-0000-0000-000000000014",
            product: syncProduct(name: "Accidental restore"),
            base: .versioned(2)
        )
        let tombstone = ProductRemoteRecord(
            content: .tombstone(productID: operation.productID),
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
        let tombstone = ProductRemoteRecord(
            content: .tombstone(productID: delete.productID),
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
    product: ProductDTO,
    predecessorOperationID: UUID? = nil,
    base: ProductRemoteBase
) -> ProductPendingUpsert {
    ProductPendingUpsert(
        productID: UUID(uuidString: product.id)!,
        operationID: syncUUID(id),
        predecessorOperationID: predecessorOperationID,
        base: base,
        product: product
    )
}

private func syncDeleteOperation(
    id: String,
    base: ProductRemoteBase
) -> ProductPendingDelete {
    ProductPendingDelete(
        productID: UUID(
            uuidString: "50000000-0000-0000-0000-000000000001"
        )!,
        operationID: syncUUID(id),
        predecessorOperationID: nil,
        base: base
    )
}

private func syncProduct(name: String) -> ProductDTO {
    ProductDTO(
        id: "50000000-0000-0000-0000-000000000001",
        name: name,
        status: .active
    )
}

private func syncUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
