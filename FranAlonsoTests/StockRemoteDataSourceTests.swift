import Foundation
import Testing

@testable import FranAlonso

@Suite("Immutable Stock transport")
struct StockRemoteDataSourceTests {
    @Test
    func `new identity receives one event and matching next counter`() throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: -4, ordinal: 1)
        let plan = try FirestoreStockRemoteDataSource.transactionPlan(for: movement, against: nil, counter: .value(40))
        guard case .atomic(let pair) = plan else {
            Issue.record("Expected atomic create")
            return
        }
        #expect(pair.record.changeSequence == 41)
        #expect(pair.counter.changeSequence == 41)
        #expect(pair.record.revision == 1)
        #expect(pair.record.operationID == movement.id.rawValue)
        #expect(try pair.record.validatedMovement() == movement)
    }

    @Test
    func `replay after lost acknowledgement never needs a counter write`() throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 9, ordinal: 1)
        let remote = try stockSyncTestRecord(movement, sequence: 7)
        let plan = try FirestoreStockRemoteDataSource.transactionPlan(for: movement, against: remote, counter: .unread)
        guard case .result(.alreadyApplied(let record)) = plan else {
            Issue.record("Expected exact replay")
            return
        }
        #expect(record == remote)
    }

    @Test
    func `divergent identity keeps original and consumes no sequence`() throws {
        let productID = ProductID(rawValue: UUID())
        let local = try stockTestMovement(productID: productID, delta: 1, ordinal: 1)
        let remote = try stockSyncTestRecord(stockTestMovement(productID: productID, delta: 2, ordinal: 1), sequence: 7)
        let plan = try FirestoreStockRemoteDataSource.transactionPlan(for: local, against: remote, counter: .malformed)
        guard case .result(.conflict(let record)) = plan else {
            Issue.record("Expected preserved conflict")
            return
        }
        #expect(record == remote)
    }

    @Test(arguments: [-1, Int64.max])
    func `invalid and exhausted counters create no write plan`(counter: Int64) throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        #expect(throws: StockSyncError.invalidMetadata) {
            try FirestoreStockRemoteDataSource.transactionPlan(for: movement, against: nil, counter: .value(counter))
        }
    }

    @Test
    func `feed computes durable maximum and preserves empty incremental cursor`() async throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        let record = try stockSyncTestRecord(movement, sequence: 17)
        let source = FirestoreStockRemoteDataSource(
            fetch: { cursor in
                cursor == nil ? [(movement.id.rawValue.uuidString, record)] : []
            },
            transact: { _ in .alreadyApplied(record) }
        )
        let bootstrap = try await source.fetchChanges(after: nil)
        #expect(bootstrap.records == [record])
        #expect(bootstrap.nextCursor.changeSequence == 17)
        let incremental = try await source.fetchChanges(after: bootstrap.nextCursor)
        #expect(incremental.records.isEmpty)
        #expect(incremental.nextCursor.changeSequence == 17)
    }

    @Test
    func `mismatched document path fails before feed acceptance`() async throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        let record = try stockSyncTestRecord(movement, sequence: 1)
        let source = FirestoreStockRemoteDataSource(
            fetch: { _ in [(UUID().uuidString, record)] },
            transact: { _ in .applied(record) }
        )
        await #expect(throws: StockSyncError.invalidMetadata) { try await source.fetchChanges(after: nil) }
    }
}
