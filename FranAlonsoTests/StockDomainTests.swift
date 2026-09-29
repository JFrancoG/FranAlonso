import Foundation
import Testing
@testable import FranAlonso

@Suite("Stock movement domain")
struct StockDomainTests {
    @Test
    func `manual acceptance retains canonical payload and stable identity on retry`() async throws {
        let repository = StockDomainRecordingRepository()
        let adjust = AdjustStockUseCase(repository: repository)
        let first = try await adjust(
            id: stockDomainID,
            productID: stockDomainProductID,
            quantityDelta: -3,
            reason: "  Recuento físico \n",
            occurredAt: stockDomainDate
        )
        let retry = try await adjust(
            id: stockDomainID,
            productID: stockDomainProductID,
            quantityDelta: -3,
            reason: "Recuento físico",
            occurredAt: stockDomainDate
        )
        #expect(first == retry)
        #expect(first.reason == "Recuento físico")
        #expect(first.quantityDelta == -3)
        #expect(first.id == stockDomainID)
        #expect(first.productID == stockDomainProductID)
        #expect(first.occurredAt == stockDomainDate)
        #expect(first.origin == .manual(reference: stockDomainID))
        #expect(await repository.accepted == [first, first])
    }

    @Test(arguments: [Int.min, -1, 1, Int.max])
    func `nonzero signed deltas survive Codable`(_ delta: Int) throws {
        let movement = try stockDomainMovement(delta: delta)
        let data = try JSONEncoder().encode(movement)
        let decoded = try JSONDecoder().decode(StockMovement.self, from: data)
        #expect(decoded == movement)
        #expect(decoded.quantityDelta == delta)
    }

    @Test
    func `zero delta cannot be constructed or decoded`() throws {
        #expect(throws: StockError.invalidDelta) {
            try stockDomainMovement(delta: 0)
        }
        let invalid = try JSONEncoder().encode(StockDomainRawPayload(quantityDelta: 0, reason: "Recuento"))
        #expect(throws: StockError.invalidDelta) {
            try JSONDecoder().decode(StockMovement.self, from: invalid)
        }
    }

    @Test(arguments: ["", " ", "\n\t"])
    func `blank reasons are rejected`(_ reason: String) {
        #expect(throws: StockError.invalidReason) {
            try stockDomainMovement(reason: reason)
        }
    }

    @Test
    func `decoding validates and normalizes reason`() throws {
        let invalid = try JSONEncoder().encode(StockDomainRawPayload(quantityDelta: 1, reason: " \n "))
        #expect(throws: StockError.invalidReason) {
            try JSONDecoder().decode(StockMovement.self, from: invalid)
        }
        let normalized = try JSONEncoder().encode(StockDomainRawPayload(quantityDelta: 1, reason: "  Nuevo motivo  "))
        #expect(try JSONDecoder().decode(StockMovement.self, from: normalized).reason == "Nuevo motivo")
    }

    @Test(arguments: [Double.infinity, -.infinity, .nan])
    func `nonfinite timestamps are rejected`(_ timestamp: Double) {
        #expect(throws: StockError.invalidDate) {
            try stockDomainMovement(date: Date(timeIntervalSinceReferenceDate: timestamp))
        }
    }

    @Test(arguments: [
        ([], 0), ([6, -6], 0), ([2, -5], -3), ([Int.max], Int.max), ([Int.min], Int.min),
        ([Int.max, 1, -1], Int.max), ([1, -1, Int.max], Int.max), ([-1, Int.max, 1], Int.max),
        ([Int.min, -1, 1], Int.min), ([-1, 1, Int.min], Int.min), ([1, Int.min, -1], Int.min)
    ])
    func `quantity is exact independently of intermediate overflow`(_ deltas: [Int], expected: Int) throws {
        #expect(try StockQuantityPolicy().quantity(deltas: deltas) == expected)
    }

    @Test(arguments: [[Int.max, 1], [Int.min, -1], [Int.max, Int.max], [Int.min, Int.min]])
    func `unrepresentable final balances fail without wrapping`(_ deltas: [Int]) {
        #expect(throws: StockError.quantityOverflow) {
            try StockQuantityPolicy().quantity(deltas: deltas)
        }
    }

    @Test
    func `invalid request reaches no repository`() async {
        let repository = StockDomainRecordingRepository()
        await #expect(throws: StockError.invalidDelta) {
            try await AdjustStockUseCase(repository: repository)(
                id: stockDomainID,
                productID: stockDomainProductID,
                quantityDelta: 0,
                reason: "Recuento",
                occurredAt: stockDomainDate
            )
        }
        #expect(await repository.accepted.isEmpty)
    }

    @Test
    func `prior cancellation reaches no repository`() async {
        let repository = StockDomainRecordingRepository()
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await AdjustStockUseCase(repository: repository)(
                id: stockDomainID,
                productID: stockDomainProductID,
                quantityDelta: 1,
                reason: "Recuento",
                occurredAt: stockDomainDate
            )
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await repository.accepted.isEmpty)
    }

    @Test
    func `cancellation after acceptance preserves successful result`() async throws {
        let accepted = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let repository = StockDomainDelayedRepository(accepted: accepted.continuation, release: release.stream)
        let task = Task {
            try await AdjustStockUseCase(repository: repository)(
                id: stockDomainID,
                productID: stockDomainProductID,
                quantityDelta: 1,
                reason: "Recuento",
                occurredAt: stockDomainDate
            )
        }
        var iterator = accepted.stream.makeAsyncIterator()
        _ = await iterator.next()
        task.cancel()
        release.continuation.finish()
        #expect(try await task.value == stockDomainMovement())
    }
}

private actor StockDomainRecordingRepository: StockRepository {
    private(set) var accepted: [StockMovement] = []

    func append(_ movement: StockMovement) -> StockMovement {
        accepted.append(movement)
        return movement
    }

    func movement(id: StockMovementID) -> StockMovement? { accepted.first { $0.id == id } }
    func quantity(for productID: ProductID) -> Int { 0 }
}

private struct StockDomainDelayedRepository: StockRepository {
    let accepted: AsyncStream<Void>.Continuation
    let release: AsyncStream<Void>

    func append(_ movement: StockMovement) async -> StockMovement {
        accepted.yield(())
        accepted.finish()
        var iterator = release.makeAsyncIterator()
        _ = await iterator.next()
        return movement
    }

    func movement(id: StockMovementID) -> StockMovement? { nil }
    func quantity(for productID: ProductID) -> Int { 0 }
}

private let stockDomainID = StockMovementID(rawValue: UUID(uuidString: "09050000-0000-0000-0000-000000000001")!)
private let stockDomainProductID = ProductID(rawValue: UUID(uuidString: "09050000-0000-0000-0000-000000000002")!)
private let stockDomainDate = Date(timeIntervalSinceReferenceDate: 100)

private func stockDomainMovement(
    delta: Int = 1,
    reason: String = "Recuento",
    date: Date = stockDomainDate
) throws -> StockMovement {
    try StockMovement(
        id: stockDomainID,
        productID: stockDomainProductID,
        quantityDelta: delta,
        reason: reason,
        occurredAt: date,
        origin: .manual(reference: stockDomainID)
    )
}

private struct StockDomainRawPayload: Encodable {
    let id = stockDomainID
    let productID = stockDomainProductID
    let quantityDelta: Int
    let reason: String
    let occurredAt = stockDomainDate
    let origin = StockMovementOrigin.manual(reference: stockDomainID)
}
