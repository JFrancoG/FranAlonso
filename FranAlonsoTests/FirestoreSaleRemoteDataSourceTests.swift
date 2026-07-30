import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore Sale remote data source")
struct FirestoreSaleRemoteDataSourceTests {
    @Test(
        "Environments resolve Sales and sync metadata paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveApprovedPaths(_ environment: FirestoreEnvironment) {
        #expect(
            environment.collectionPath(for: .sales)
                == "\(environment.rawValue)/collections/sales"
        )
        #expect(
            environment.syncMetadataDocumentPath(for: .sales)
                == "\(environment.rawValue)/collections/syncMetadata/sales"
        )
    }

    @Test("A live write contains payload v1 nested lines exact dates and sync metadata")
    func liveWriteContainsCompleteSaleSnapshot() throws {
        let record = try firestoreSaleRecord(progressed: false, sequence: 9)

        let fields = try Firestore.Encoder().encode(FirestoreSaleWriteDTO(record))
        let lines = try #require(fields["lines"] as? [[String: Any]])
        let firstLine = try #require(lines.first)
        let price = try #require(firstLine["unitPrice"] as? [String: Any])
        let status = try #require(fields["status"] as? [String: Any])
        let sync = try #require(fields["_sync"] as? [String: Any])

        #expect(fields["payloadVersion"] as? Int == 1)
        #expect(fields["id"] as? String == record.id)
        #expect(fields["_deleted"] as? Bool == false)
        #expect(fields["createdAt"] as? String == "3ff0000000000000")
        #expect(lines.count == 1)
        #expect(firstLine["serviceName"] as? String == "Snapshot")
        #expect(price["amount"] as? String == "10")
        #expect(status["kind"] as? String == "draft")
        #expect(sync["revision"] as? Int64 == 2)
        #expect(sync["changeSequence"] as? Int64 == 9)
    }

    @Test("The Firestore read projection reconstructs the exact Sale payload")
    func readProjectionReconstructsExactSalePayload() throws {
        let expected = try firestoreSaleRecord(progressed: false, sequence: 9)
        let dto = try #require(expected.liveSale)
        let document = FirestoreSaleDocumentDTO(
            payloadVersion: dto.payloadVersion,
            id: dto.id,
            isDeleted: false,
            clientID: dto.clientID,
            createdAt: dto.createdAt,
            lines: dto.lines,
            status: dto.status,
            syncMetadata: FirestoreSaleSyncMetadataDTO(
                revision: 2,
                lastOperationID: firestoreSaleOperationID.uuidString,
                changeSequence: 9
            )
        )

        #expect(try document.toRemoteRecord(documentID: dto.id) == expected)
    }

    @Test("Unsupported document payload versions fail closed")
    func unsupportedDocumentPayloadVersionFailsClosed() throws {
        let expected = try firestoreSaleRecord(progressed: false, sequence: 9)
        let dto = try #require(expected.liveSale)
        let document = FirestoreSaleDocumentDTO(
            payloadVersion: 2,
            id: dto.id,
            isDeleted: false,
            clientID: dto.clientID,
            createdAt: dto.createdAt,
            lines: dto.lines,
            status: dto.status,
            syncMetadata: nil
        )

        #expect(throws: DecodingError.self) {
            _ = try document.toRemoteRecord(documentID: dto.id)
        }
    }

    @Test("A tombstone contains no Sale business payload")
    func tombstoneContainsNoSaleBusinessPayload() throws {
        let record = SaleRemoteRecord(
            content: .tombstone(saleID: firestoreSaleID),
            version: .versioned(revision: 3, lastOperationID: firestoreSaleOperationID),
            changeSequence: 10
        )

        let fields = try Firestore.Encoder().encode(FirestoreSaleWriteDTO(record))

        #expect(fields["payloadVersion"] as? Int == 1)
        #expect(fields["_deleted"] as? Bool == true)
        #expect(Set(fields.keys) == ["payloadVersion", "id", "_deleted", "_sync"])
    }

    @Test("A tombstone carrying Sale business fields fails closed")
    func tombstoneWithBusinessFieldsFailsClosed() throws {
        let liveRecord = try firestoreSaleRecord(progressed: false, sequence: 9)
        let sale = try #require(liveRecord.liveSale)
        let document = FirestoreSaleDocumentDTO(
            payloadVersion: sale.payloadVersion,
            id: sale.id,
            isDeleted: true,
            clientID: sale.clientID,
            createdAt: sale.createdAt,
            lines: sale.lines,
            status: sale.status,
            syncMetadata: FirestoreSaleSyncMetadataDTO(
                revision: 2,
                lastOperationID: firestoreSaleOperationID.uuidString,
                changeSequence: 9
            )
        )

        #expect(throws: DecodingError.self) {
            _ = try document.toRemoteRecord(documentID: sale.id)
        }
    }

    @Test("Transaction planning writes draft discard atomically and rejects progressed discard")
    func transactionPlanningChecksDraftBeforeDiscard() throws {
        let draftRemote = try firestoreSaleRecord(progressed: false, sequence: 1)
        let progressedRemote = try firestoreSaleRecord(progressed: true, sequence: 1)
        let discard = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: firestoreSaleID,
                operationID: firestoreSaleUUID("40000000-0000-0000-0000-000000000099"),
                predecessorOperationID: nil,
                base: .versioned(2)
            )
        )

        let draftPlan = try FirestoreSaleRemoteDataSource.transactionPlan(
            for: discard,
            against: draftRemote,
            counter: .value(1),
            policy: SaleSyncPolicy()
        )
        let write = try #require(draftPlan.atomicWrite)
        #expect(write.record.isTombstone)
        #expect(write.record.changeSequence == 2)

        let progressedPlan = try FirestoreSaleRemoteDataSource.transactionPlan(
            for: discard,
            against: progressedRemote,
            counter: .unread,
            policy: SaleSyncPolicy()
        )
        #expect(
            progressedPlan
                == .result(.conflict(.discardRequiresDraft, progressedRemote))
        )
        #expect(progressedPlan.atomicWrite == nil)

        let staleRoot = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: firestoreSaleID,
                operationID: firestoreSaleUUID(
                    "40000000-0000-0000-0000-000000000100"
                ),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let stalePlan = try FirestoreSaleRemoteDataSource.transactionPlan(
            for: staleRoot,
            against: draftRemote,
            counter: .unread,
            policy: SaleSyncPolicy()
        )
        #expect(stalePlan == .result(.conflict(.baseChanged, draftRemote)))
        #expect(stalePlan.atomicWrite == nil)

        let divergentDescendant = SalePendingOperation.discard(
            SalePendingDiscard(
                saleID: firestoreSaleID,
                operationID: firestoreSaleUUID(
                    "40000000-0000-0000-0000-000000000101"
                ),
                predecessorOperationID: firestoreSaleUUID(
                    "40000000-0000-0000-0000-000000000102"
                ),
                base: .versioned(1)
            )
        )
        let divergentPlan = try FirestoreSaleRemoteDataSource.transactionPlan(
            for: divergentDescendant,
            against: draftRemote,
            counter: .unread,
            policy: SaleSyncPolicy()
        )
        #expect(
            divergentPlan
                == .result(.conflict(.causalPredecessorMissing, draftRemote))
        )
        #expect(divergentPlan.atomicWrite == nil)
    }

    @Test("Unknown Firestore Sale root fields fail closed for live and tombstone documents")
    func unknownRootFieldsFailClosed() throws {
        let liveRecord = try firestoreSaleRecord(progressed: false, sequence: 9)
        let sale = try #require(liveRecord.liveSale)
        let syncMetadata = FirestoreSaleSyncWriteDTO(
            revision: 2,
            lastOperationID: firestoreSaleOperationID.uuidString,
            changeSequence: 9
        )
        let live = FirestoreSaleDocumentFixture(
            payloadVersion: sale.payloadVersion,
            id: sale.id,
            isDeleted: false,
            clientID: sale.clientID,
            createdAt: sale.createdAt,
            lines: sale.lines,
            status: sale.status,
            syncMetadata: syncMetadata,
            unexpected: true
        )
        let tombstone = FirestoreSaleDocumentFixture(
            payloadVersion: 1,
            id: sale.id,
            isDeleted: true,
            clientID: nil,
            createdAt: nil,
            lines: nil,
            status: nil,
            syncMetadata: syncMetadata,
            unexpected: true
        )

        for fixture in [live, tombstone] {
            #expect(throws: DecodingError.self) {
                _ = try JSONDecoder().decode(
                    FirestoreSaleDocumentDTO.self,
                    from: JSONEncoder().encode(fixture)
                )
            }
        }
    }

    @Test("Strict Firestore decoding retains valid modern and legacy shapes")
    func strictDecodingRetainsValidShapes() throws {
        let expected = try firestoreSaleRecord(progressed: false, sequence: 9)
        let sale = try #require(expected.liveSale)
        let modern = FirestoreSaleDocumentFixture(
            payloadVersion: sale.payloadVersion,
            id: sale.id,
            isDeleted: false,
            clientID: sale.clientID,
            createdAt: sale.createdAt,
            lines: sale.lines,
            status: sale.status,
            syncMetadata: FirestoreSaleSyncWriteDTO(
                revision: 2,
                lastOperationID: firestoreSaleOperationID.uuidString,
                changeSequence: 9
            ),
            unexpected: nil
        )
        let legacy = FirestoreSaleDocumentFixture(
            payloadVersion: sale.payloadVersion,
            id: sale.id,
            isDeleted: false,
            clientID: sale.clientID,
            createdAt: sale.createdAt,
            lines: sale.lines,
            status: sale.status,
            syncMetadata: nil,
            unexpected: nil
        )

        let modernDocument = try JSONDecoder().decode(
            FirestoreSaleDocumentDTO.self,
            from: JSONEncoder().encode(modern)
        )
        let legacyDocument = try JSONDecoder().decode(
            FirestoreSaleDocumentDTO.self,
            from: JSONEncoder().encode(legacy)
        )

        #expect(try modernDocument.toRemoteRecord(documentID: sale.id) == expected)
        #expect(
            try legacyDocument.toRemoteRecord(documentID: sale.id).version
                == .legacy
        )
    }

    @Test("Invalid Sale identifiers retain their exact Firestore coding path")
    func invalidIdentifiersRetainExactCodingPath() throws {
        for testCase in try invalidFirestoreSaleIdentifierCases() {
            let document = FirestoreSaleDocumentDTO(
                payloadVersion: testCase.payload.payloadVersion,
                id: testCase.payload.id,
                isDeleted: false,
                clientID: testCase.payload.clientID,
                createdAt: testCase.payload.createdAt,
                lines: testCase.payload.lines,
                status: testCase.payload.status,
                syncMetadata: nil
            )

            do {
                _ = try document.toRemoteRecord(documentID: testCase.documentID)
                Issue.record("Expected invalid identifier at \(testCase.expectedPath)")
            } catch DecodingError.dataCorrupted(let context) {
                #expect(
                    firestoreCodingPath(context.codingPath)
                        == testCase.expectedPath
                )
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test("Bootstrap and incremental fetch preserve exact cursor semantics")
    func fetchPreservesCursorSemantics() async throws {
        let record = try firestoreSaleRecord(progressed: false, sequence: 7)
        let gate = FirestoreSaleFetchGate(record: record)
        let source = FirestoreSaleRemoteDataSource(
            fetch: { cursor in await gate.fetch(after: cursor) },
            transact: { _ in throw SaleRemoteDataSourceError.unexpected }
        )

        let batch = try await source.fetchChanges(
            after: SaleSyncCursor(changeSequence: 3)
        )

        #expect(await gate.received == [SaleSyncCursor(changeSequence: 3)])
        #expect(batch.records == [record])
        #expect(batch.nextCursor == SaleSyncCursor(changeSequence: 7))
    }
}

private actor FirestoreSaleFetchGate {
    let record: SaleRemoteRecord
    private(set) var received: [SaleSyncCursor?] = []

    init(record: SaleRemoteRecord) {
        self.record = record
    }

    func fetch(
        after cursor: SaleSyncCursor?
    ) -> [(documentID: String, record: SaleRemoteRecord)] {
        received.append(cursor)
        return [(record.id, record)]
    }
}

private struct FirestoreSaleDocumentFixture: Encodable {
    let payloadVersion: Int
    let id: String
    let isDeleted: Bool
    let clientID: String?
    let createdAt: SaleTimestampDTO?
    let lines: [SaleLineDTO]?
    let status: SaleStatusDTO?
    let syncMetadata: FirestoreSaleSyncWriteDTO?
    let unexpected: Bool?

    private enum CodingKeys: String, CodingKey {
        case payloadVersion
        case id
        case isDeleted = "_deleted"
        case clientID
        case createdAt
        case lines
        case status
        case syncMetadata = "_sync"
        case unexpected
    }
}

private struct InvalidFirestoreSaleIdentifierCase {
    let payload: SaleDTO
    let documentID: String
    let expectedPath: [String]
}

private func invalidFirestoreSaleIdentifierCases() throws
    -> [InvalidFirestoreSaleIdentifierCase] {
    let invalid = "not-a-uuid"
    let draft = try #require(
        firestoreSaleRecord(progressed: false, sequence: 1).liveSale
    )
    let validID = draft.id
    let invalidSale = firestoreSaleDTO(draft, id: invalid)
    let invalidClient = firestoreSaleDTO(draft, clientID: invalid)
    let invalidLine = firestoreSaleDTO(
        draft,
        lines: [firestoreSaleLineDTO(draft.lines[0], id: invalid)]
    )
    let invalidService = firestoreSaleDTO(
        draft,
        lines: [firestoreSaleLineDTO(draft.lines[0], serviceID: invalid)]
    )
    let invalidLinkedProduct = firestoreSaleDTO(
        draft,
        lines: [firestoreSaleLineDTO(draft.lines[0], linkedProductID: invalid)]
    )

    let completedLines = draft.lines.map {
        SaleLineDTO(
            id: $0.id,
            serviceID: $0.serviceID,
            serviceName: $0.serviceName,
            quantity: $0.quantity,
            unitPrice: $0.unitPrice,
            taxRate: $0.taxRate,
            discount: $0.discount,
            linkedProductID: $0.linkedProductID,
            status: .completed
        )
    }
    let timestamp = try SaleTimestampDTO(
        Date(timeIntervalSinceReferenceDate: 2)
    )
    let payment = SalePaymentDTO(
        id: firestoreSaleUUID("40000000-0000-0000-0000-000000000110").uuidString,
        method: .card,
        paidAt: timestamp
    )
    let document = SaleDocumentDTO(
        id: firestoreSaleUUID("40000000-0000-0000-0000-000000000111").uuidString,
        closedAt: timestamp
    )
    let invalidPayment = firestoreSaleDTO(
        draft,
        lines: completedLines,
        status: .awaitingDocument(
            payment: SalePaymentDTO(
                id: invalid,
                method: payment.method,
                paidAt: payment.paidAt
            )
        )
    )
    let invalidDocument = firestoreSaleDTO(
        draft,
        lines: completedLines,
        status: .closed(
            payment: payment,
            document: SaleDocumentDTO(
                id: invalid,
                closedAt: document.closedAt
            )
        )
    )
    let invalidReversal = firestoreSaleDTO(
        draft,
        lines: completedLines,
        status: .voided(
            payment: payment,
            document: document,
            reversal: SaleReversalDTO(id: invalid, voidedAt: timestamp)
        )
    )

    return [
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidSale,
            documentID: invalid,
            expectedPath: ["id"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidClient,
            documentID: validID,
            expectedPath: ["clientID"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidLine,
            documentID: validID,
            expectedPath: ["lines", "[0]", "id"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidService,
            documentID: validID,
            expectedPath: ["lines", "[0]", "serviceID"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidLinkedProduct,
            documentID: validID,
            expectedPath: ["lines", "[0]", "linkedProductID"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidPayment,
            documentID: validID,
            expectedPath: ["status", "payment", "id"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidDocument,
            documentID: validID,
            expectedPath: ["status", "document", "id"]
        ),
        InvalidFirestoreSaleIdentifierCase(
            payload: invalidReversal,
            documentID: validID,
            expectedPath: ["status", "reversal", "id"]
        )
    ]
}

private func firestoreSaleDTO(
    _ dto: SaleDTO,
    id: String? = nil,
    clientID: String? = nil,
    lines: [SaleLineDTO]? = nil,
    status: SaleStatusDTO? = nil
) -> SaleDTO {
    SaleDTO(
        payloadVersion: dto.payloadVersion,
        id: id ?? dto.id,
        clientID: clientID ?? dto.clientID,
        createdAt: dto.createdAt,
        lines: lines ?? dto.lines,
        status: status ?? dto.status
    )
}

private func firestoreSaleLineDTO(
    _ line: SaleLineDTO,
    id: String? = nil,
    serviceID: String? = nil,
    linkedProductID: String? = nil
) -> SaleLineDTO {
    SaleLineDTO(
        id: id ?? line.id,
        serviceID: serviceID ?? line.serviceID,
        serviceName: line.serviceName,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        taxRate: line.taxRate,
        discount: line.discount,
        linkedProductID: linkedProductID ?? line.linkedProductID,
        status: line.status
    )
}

private func firestoreCodingPath(_ codingPath: [any CodingKey]) -> [String] {
    codingPath.map { key in
        if let index = key.intValue {
            return "[\(index)]"
        }
        return key.stringValue
    }
}

private let firestoreSaleID = firestoreSaleUUID(
    "40000000-0000-0000-0000-000000000001"
)
private let firestoreSaleOperationID = firestoreSaleUUID(
    "40000000-0000-0000-0000-000000000002"
)

private func firestoreSaleRecord(
    progressed: Bool,
    sequence: Int64
) throws -> SaleRemoteRecord {
    SaleRemoteRecord(
        sale: try SaleDTO(firestoreSale(progressed: progressed)),
        version: .versioned(revision: 2, lastOperationID: firestoreSaleOperationID),
        changeSequence: sequence
    )
}

private func firestoreSale(progressed: Bool) throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(rawValue: firestoreSaleUUID("40000000-0000-0000-0000-000000000003")),
        serviceID: ServiceID(rawValue: firestoreSaleUUID("40000000-0000-0000-0000-000000000004")),
        serviceName: "Snapshot",
        quantity: 1,
        unitPrice: Money(amount: 10, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil,
        linkedProductID: nil
    )
    var sale = try Sale.draft(
        id: SaleID(rawValue: firestoreSaleID),
        clientID: nil,
        createdAt: Date(timeIntervalSinceReferenceDate: 1),
        lines: [line]
    )
    if progressed {
        try sale.start()
    }
    return sale
}

private func firestoreSaleUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
