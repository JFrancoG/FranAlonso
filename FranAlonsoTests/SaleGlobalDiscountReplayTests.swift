import FirebaseFirestore
import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale global discount replay")
struct SaleGlobalDiscountReplayTests {
    @Test("Firestore replay writes each immutable operation's own v1 or v2 version", arguments: [1, 2])
    func firestoreWriterPreservesSnapshotVersion(_ version: Int) throws {
        let payload = SaleGlobalDiscountDataFixture.salePayload(
            version: version,
            global: version == 1 ? nil : SaleGlobalDiscountDataFixture.global20
        )
        let dto = try JSONDecoder().decode(SaleDTO.self, from: Data(payload.utf8))
        let record = SaleRemoteRecord(
            sale: dto,
            version: .versioned(revision: 7, lastOperationID: SaleGlobalDiscountDataFixture.operationA),
            changeSequence: 8
        )

        let fields = try Firestore.Encoder().encode(FirestoreSaleWriteDTO(record))
        let global = fields["globalDiscount"] as? [String: Any]

        #expect(fields["payloadVersion"] as? Int == version)
        #expect(global?["policy"] as? String == (version == 1 ? nil : "lineThenGlobalV1"))
        #expect(global?["percentage"] as? String == (version == 1 ? nil : "20"))
        let decoded = try Firestore.Decoder().decode(FirestoreSaleDocumentDTO.self, from: fields)
        let remote = try decoded.toRemoteRecord(documentID: SaleGlobalDiscountDataFixture.saleID.uuidString)
        #expect(remote == record)
        let sale = try #require(remote.liveSale).toDomain()
        #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == (version == 1 ? 90 : 72))
    }

    @Test("Tombstones retain v1 after the commercial payload advances to v2")
    func tombstoneWriterRetainsVersionOne() throws {
        let record = SaleRemoteRecord(
            content: .tombstone(saleID: SaleGlobalDiscountDataFixture.saleID),
            version: .versioned(revision: 9, lastOperationID: SaleGlobalDiscountDataFixture.operationB),
            changeSequence: 10
        )
        let fields = try Firestore.Encoder().encode(FirestoreSaleWriteDTO(record))
        let document = try Firestore.Decoder().decode(FirestoreSaleDocumentDTO.self, from: fields)

        #expect(fields["payloadVersion"] as? Int == 1)
        #expect(Set(fields.keys) == ["payloadVersion", "id", "_deleted", "_sync"])
        #expect(try document.toRemoteRecord(documentID: record.id) == record)
    }

    @Test("Durable causal A v1 then B v2 replays exactly and converges without recoding A")
    func mixedVersionCausalReplayConverges() async throws {
        let container = try SaleGlobalDiscountDataFixture.memoryContainer()
        let context = ModelContext(container)
        let aBytes = Data(SaleGlobalDiscountDataFixture.saleV1.utf8)
        let bBytes = Data(SaleGlobalDiscountDataFixture.saleV2.utf8)
        let localBytes = Data(#"{"lines":\#(SaleGlobalDiscountDataFixture.linesV1),"globalDiscount":\#(SaleGlobalDiscountDataFixture.global20)}"#.utf8)
        context.insert(SaleGlobalDiscountDataFixture.rawModel(version: 2, bytes: localBytes))
        for (operationID, predecessor, payload) in [
            (SaleGlobalDiscountDataFixture.operationA, nil as UUID?, aBytes),
            (SaleGlobalDiscountDataFixture.operationB, SaleGlobalDiscountDataFixture.operationA, bBytes)
        ] {
            context.insert(
                SalePendingUpsertModel(
                    saleID: SaleGlobalDiscountDataFixture.saleID,
                    operationID: operationID,
                    predecessorOperationID: predecessor,
                    baseVersion: 1,
                    baseData: Data(#"{"absent":{}}"#.utf8),
                    payloadVersion: 1,
                    payloadData: payload
                )
            )
        }
        try context.save()
        let remote = GlobalDiscountReplayTransport()
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            remoteDataSource: remote,
            observationSignal: SaleObservationSignal()
        )

        try await engine.synchronize()
        try await engine.synchronize()

        let verification = ModelContext(container)
        #expect(try verification.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
        let expectedIDs = [SaleGlobalDiscountDataFixture.operationA, SaleGlobalDiscountDataFixture.operationB]
        #expect(await remote.receivedIDs == expectedIDs)
        #expect(await remote.writtenVersions == [1, 2])
        let received = await remote.receivedSales
        #expect(received.map(\.payloadVersion) == [1, 2])
        let receivedTotals = try received.map {
            try SaleCalculator().calculate(sale: $0.toDomain(), currency: .eur).total.amount
        }
        #expect(receivedTotals == [90, 72])
        let record = try #require(await remote.record)
        #expect(record.version == .versioned(revision: 2, lastOperationID: SaleGlobalDiscountDataFixture.operationB))
        let id = SaleID(rawValue: SaleGlobalDiscountDataFixture.saleID)
        let durable = try #require(try SaleLocalDataSource().sale(id: id, in: verification))
        #expect(durable.globalDiscount?.policy == .lineThenGlobalV1)
        #expect(try SaleCalculator().calculate(sale: durable, currency: .eur).total.amount == 72)
    }

    @Test(
        "Invalid incoming policy canonical percentage or version stops the pull without cursor or writes",
        arguments: [
            GlobalInvalidPullCase(version: 2, global: #"{"percentage":"20","policy":"future"}"#),
            GlobalInvalidPullCase(version: 2, global: #"{"percentage":"20.0","policy":"lineThenGlobalV1"}"#),
            GlobalInvalidPullCase(version: 3, global: nil),
            GlobalInvalidPullCase(version: 1, global: "null")
        ]
    )
    func invalidIncomingPayloadCannotAdvanceDurableState(_ testCase: GlobalInvalidPullCase) async throws {
        let container = try SaleGlobalDiscountDataFixture.memoryContainer()
        let context = ModelContext(container)
        let bytes = Data(SaleGlobalDiscountDataFixture.saleV1.utf8)
        context.insert(SaleGlobalDiscountDataFixture.rawModel())
        context.insert(SaleSyncCursorModel(feedID: "sales", changeSequence: 7))
        context.insert(
            SalePendingUpsertModel(
                saleID: SaleGlobalDiscountDataFixture.saleID,
                operationID: SaleGlobalDiscountDataFixture.operationA,
                predecessorOperationID: nil,
                baseVersion: 1,
                baseData: Data(#"{"absent":{}}"#.utf8),
                payloadVersion: 1,
                payloadData: bytes
            )
        )
        try context.save()
        let counter = GlobalInvalidPullWriteCounter()
        let document = globalFirestoreDocument(version: testCase.version, global: testCase.global)
        let source = FirestoreSaleRemoteDataSource(
            fetch: { _ in
                let decoded = try JSONDecoder().decode(FirestoreSaleDocumentDTO.self, from: Data(document.utf8))
                let record = try decoded.toRemoteRecord(documentID: SaleGlobalDiscountDataFixture.saleID.uuidString)
                return [(record.id, record)]
            },
            transact: { _ in
                await counter.recordWrite()
                throw SaleRemoteDataSourceError.unexpected
            }
        )
        let engine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            remoteDataSource: source,
            observationSignal: SaleObservationSignal()
        )

        await #expect(throws: (any Error).self) {
            try await engine.synchronize()
        }

        let verification = ModelContext(container)
        #expect(try SaleLocalDataSource().cursor(in: verification) == SaleSyncCursor(changeSequence: 7))
        #expect(try verification.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 1)
        #expect(try verification.fetch(FetchDescriptor<SalePendingUpsertModel>()).first?.payloadData == bytes)
        #expect(try verification.fetchCount(FetchDescriptor<SaleRemoteStateModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<SaleSyncConflictModel>()) == 0)
        #expect(await counter.writes == 0)
        let localBytes = try verification.fetch(FetchDescriptor<SaleModel>()).first?.linesData
        #expect(localBytes == Data(SaleGlobalDiscountDataFixture.linesV1.utf8))
    }
}

struct GlobalInvalidPullCase {
    let version: Int
    let global: String?
}

private func globalFirestoreDocument(version: Int, global: String?) -> String {
    let extra = global.map { #", "globalDiscount":\#($0)"# } ?? ""
    return #"{"payloadVersion":\#(version),"id":"\#(SaleGlobalDiscountDataFixture.saleID.uuidString)","_deleted":false,"createdAt":"3ff0000000000000","lines":\#(SaleGlobalDiscountDataFixture.linesV1),"status":{"kind":"draft"},"_sync":{"revision":8,"lastOperationID":"\#(SaleGlobalDiscountDataFixture.remoteOperation.uuidString)","changeSequence":8}\#(extra)}"#
}

private actor GlobalInvalidPullWriteCounter {
    private(set) var writes = 0
    func recordWrite() {
        writes += 1
    }
}

private actor GlobalDiscountReplayTransport: SaleRemoteDataSource {
    private(set) var record: SaleRemoteRecord?
    private(set) var receivedIDs: [UUID] = []
    private(set) var writtenVersions: [Int] = []
    private(set) var receivedSales: [SaleDTO] = []

    func fetchChanges(after cursor: SaleSyncCursor?) -> SaleRemoteChangeBatch {
        let sequence = record?.changeSequence ?? 0
        let records = record.map { record in
            sequence > (cursor?.changeSequence ?? 0) ? [record] : []
        } ?? []
        return SaleRemoteChangeBatch(records: records, nextCursor: SaleSyncCursor(changeSequence: sequence))
    }

    func apply(_ operation: SalePendingOperation) throws -> SaleRemoteMutationResult {
        receivedIDs.append(operation.operationID)
        let plan = try FirestoreSaleRemoteDataSource.transactionPlan(
            for: operation,
            against: record,
            counter: .value(record?.changeSequence ?? 0),
            policy: SaleSyncPolicy()
        )
        switch plan {
        case .atomic(let write):
            let fields = try Firestore.Encoder().encode(FirestoreSaleWriteDTO(write.record))
            writtenVersions.append(try #require(fields["payloadVersion"] as? Int))
            if case .upsert(let upsert) = operation {
                receivedSales.append(upsert.sale)
            }
            record = write.record
            return .applied(write.record)
        case .result(let result):
            return result
        case .invalid(let error):
            throw error
        }
    }
}
