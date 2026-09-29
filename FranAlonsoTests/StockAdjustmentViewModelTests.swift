import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Stock adjustment presentation")
@MainActor
struct StockAdjustmentViewModelTests {
    @Test
    func `loading a known inactive product enables an adjustment with its current balance`() async throws {
        let fixture = try StockAdjustmentFixture(status: .inactive)
        await fixture.model.load()
        #expect(fixture.model.loadedProduct?.status == .inactive)
        #expect(fixture.model.quantity == 8)
        #expect(fixture.model.state == .editing)
        #expect(fixture.model.canSubmit)
        #expect(!fixture.model.hasUnsavedChanges)
    }

    @Test
    func `validation never submits and successful correction accepts the canonical withdrawal`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "0"
        fixture.model.reason = "Count"
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.validation, .invalidQuantity))
        #expect(fixture.writes.movements.isEmpty)
        #expect(fixture.model.canEdit)
        fixture.model.unitsText = " 11 "
        fixture.model.direction = .withdrawal
        fixture.model.reason = " \n "
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.validation, .invalidReason))
        #expect(fixture.writes.movements.isEmpty)
        fixture.model.reason = "  Damaged goods \n"
        await fixture.quantity.set(-3)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .saved)
        #expect(fixture.model.balanceState == .loaded(-3))
        #expect(fixture.model.acceptedMovement?.quantityDelta == -11)
        #expect(fixture.model.acceptedMovement?.reason == "Damaged goods")
        #expect(!fixture.model.canSubmit)
        #expect(!fixture.model.hasUnsavedChanges)
        #expect(fixture.writes.contexts == [ObjectIdentifier(fixture.context)])
    }

    @Test
    func `failed save retries the frozen command even if draft values subsequently change`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        fixture.writes.failure = StockError.storageFailure
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .storageFailure))
        #expect(!fixture.model.canEdit)
        #expect(fixture.model.canSubmit)
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.unitsText = "99"
        fixture.model.direction = .withdrawal
        fixture.model.reason = "Later changes"
        fixture.writes.failure = nil
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.movements.count == 2)
        let first = try #require(fixture.writes.movements.first)
        #expect(fixture.writes.movements.last == first)
        #expect(first.quantityDelta == 2)
        #expect(first.reason == "Received")
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.movements.count == 2)
    }

    @Test
    func `failed balance refresh cannot reopen an accepted adjustment`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        await fixture.quantity.setFailure(.storageFailure)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .saved)
        #expect(fixture.model.isAccepted)
        #expect(fixture.model.balanceState == .failed(.storageFailure))
        #expect(!fixture.model.canEdit)
        await fixture.model.save(in: fixture.context)
        await fixture.quantity.setFailure(nil)
        await fixture.quantity.set(10)
        await fixture.model.refreshQuantity()
        #expect(fixture.model.balanceState == .loaded(10))
        #expect(fixture.writes.movements.count == 1)
    }

    @Test
    func `missing product and failed balance read stay noneditable until a successful retry`() async throws {
        let fixture = try StockAdjustmentFixture(present: false)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .productNotFound))
        fixture.model.unitsText = "4"
        fixture.model.reason = "Cannot save unread product"
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.movements.isEmpty)
        try await fixture.repository.saveProduct(Product(
            id: fixture.model.destination.productID,
            name: "Recovered",
            status: .active
        ))
        await fixture.quantity.setFailure(.storageFailure)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .storageFailure))
        #expect(!fixture.model.canEdit)
        #expect(fixture.model.loadedProduct == nil)
        await fixture.quantity.setFailure(nil)
        await fixture.model.load()
        #expect(fixture.model.state == .editing)
        #expect(fixture.model.quantity == 8)
    }

    @Test
    func `suspended submission freezes input and excludes overlapping saves`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "3"
        fixture.model.reason = "Received"
        let gate = StockAdjustmentGate()
        fixture.writes.gate = gate
        let saving = Task {
            await fixture.model.save(in: fixture.context)
        }
        await gate.waitUntilBlocked()
        #expect(fixture.model.state == .saving)
        #expect(!fixture.model.canEdit)
        #expect(!fixture.model.canSubmit)
        #expect(!fixture.model.canClose)
        fixture.model.unitsText = "9"
        fixture.model.reason = "Later text"
        await fixture.model.save(in: fixture.context)
        gate.release()
        await saving.value
        #expect(fixture.writes.movements.count == 1)
        #expect(fixture.model.acceptedMovement?.quantityDelta == 3)
        #expect(fixture.model.acceptedMovement?.reason == "Received")
    }

    @Test
    func `prior cancellation neither freezes nor submits a command`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        let saving = Task {
            await fixture.model.save(in: fixture.context)
        }
        saving.cancel()
        await saving.value
        #expect(fixture.writes.movements.isEmpty)
        #expect(fixture.model.canEdit)
        #expect(fixture.model.state == .editing)
    }

    @Test(arguments: [StockAdjustmentInterruption.cancelled, .cooperative, .closed])
    func `late submission responses preserve accepted outcomes and closed sessions`(
        interruption: StockAdjustmentInterruption
    ) async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        let gate = StockAdjustmentGate()
        fixture.writes.gate = gate
        let saving = Task {
            await fixture.model.save(in: fixture.context)
        }
        await gate.waitUntilBlocked()
        switch interruption {
        case .cancelled:
            saving.cancel()
        case .cooperative:
            saving.cancel()
            fixture.writes.failure = CancellationError()
        case .closed:
            fixture.model.close()
        }
        gate.release()
        await saving.value
        switch interruption {
        case .cancelled:
            #expect(fixture.model.state == .saved)
            #expect(fixture.model.isAccepted)
            #expect(!fixture.model.canSubmit)
        case .cooperative:
            #expect(fixture.model.state == .failed(.save, .storageFailure))
            #expect(!fixture.model.isAccepted)
            #expect(!fixture.model.canEdit)
            fixture.writes.failure = nil
            fixture.writes.gate = nil
            await fixture.model.save(in: fixture.context)
            #expect(fixture.writes.movements.count == 2)
            #expect(fixture.writes.movements.first == fixture.writes.movements.last)
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.unitsText.isEmpty)
            #expect(fixture.model.acceptedMovement == nil)
            await fixture.model.load()
            await fixture.model.save(in: fixture.context)
            #expect(fixture.model.state == .closed)
            #expect(fixture.writes.movements.count == 1)
        }
    }

    @Test(arguments: [StockAdjustmentReadInterruption.replaced, .cancelled, .closed])
    func `obsolete initial balance reads never enable a stale or closed session`(
        interruption: StockAdjustmentReadInterruption
    ) async throws {
        let fixture = try StockAdjustmentFixture()
        let gate = StockAdjustmentGate()
        await fixture.quantity.holdNextRead(gate)
        let loading = Task {
            await fixture.model.load()
        }
        await gate.waitUntilBlocked()
        switch interruption {
        case .replaced:
            await fixture.quantity.set(-4)
            await fixture.model.load()
        case .cancelled:
            loading.cancel()
        case .closed:
            fixture.model.close()
        }
        gate.release()
        await loading.value
        switch interruption {
        case .replaced:
            #expect(fixture.model.state == .editing)
            #expect(fixture.model.quantity == -4)
        case .cancelled:
            #expect(fixture.model.state == .idle)
            #expect(fixture.model.quantity == nil)
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.quantity == nil)
        }
    }

    @Test(arguments: [false, true])
    func `acceptance is terminal while refresh is suspended and closing fences its result`(
        closeDuringRefresh: Bool
    ) async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        let gate = StockAdjustmentGate()
        await fixture.quantity.holdNextRead(gate)
        let saving = Task {
            await fixture.model.save(in: fixture.context)
        }
        await gate.waitUntilBlocked()
        #expect(fixture.model.state == .saved)
        #expect(fixture.model.isAccepted)
        #expect(fixture.model.balanceState == .loading)
        #expect(fixture.model.canClose)
        #expect(!fixture.model.canSubmit)
        await fixture.model.save(in: fixture.context)
        if closeDuringRefresh {
            fixture.model.close()
        } else {
            await fixture.quantity.set(10)
            await fixture.model.refreshQuantity()
        }
        gate.release()
        await saving.value
        #expect(fixture.writes.movements.count == 1)
        if closeDuringRefresh {
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.balanceState == .idle)
            #expect(fixture.model.quantity == nil)
        } else {
            #expect(fixture.model.balanceState == .loaded(10))
            #expect(fixture.model.quantity == 10)
        }
    }

    @Test
    func `draft cancellation writes nothing and terminal sessions cannot revive`() async throws {
        let fixture = try StockAdjustmentFixture()
        await fixture.model.load()
        fixture.model.direction = .withdrawal
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.direction = .entry
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.unitsText = "2"
        fixture.model.reason = "Received"
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.close()
        await fixture.model.save(in: fixture.context)
        await fixture.model.load()
        await fixture.model.refreshQuantity()
        #expect(fixture.writes.movements.isEmpty)
        #expect(fixture.model.state == .closed)
        #expect(!fixture.model.hasUnsavedChanges)
    }

}

@MainActor
private struct StockAdjustmentFixture {
    let container: ModelContainer
    let repository: InMemoryProductRepository
    let quantity: StockAdjustmentRead
    let writes: StockAdjustmentWrites
    let model: StockAdjustmentViewModel
    var context: ModelContext { container.mainContext }
}

private extension StockAdjustmentFixture {
    init(status: ProductStatus = .active, present: Bool = true) throws {
        let container = try stockTestContainer()
        let product = Product(id: ProductID(rawValue: UUID()), name: "Product fixture", status: status)
        let repository = InMemoryProductRepository(products: present ? [product] : [])
        let quantity = StockAdjustmentRead()
        let writes = StockAdjustmentWrites()
        self.init(
            container: container,
            repository: repository,
            quantity: quantity,
            writes: writes,
            model: StockAdjustmentViewModel(
                destination: StockAdjustmentDestination(id: UUID(), productID: product.id),
                getProduct: GetProductUseCase(repository: repository),
                getQuantity: { id in
                    try await quantity.read(id)
                },
                accept: { movement, context in
                    try await writes.append(movement, in: context)
                },
                now: { Date(timeIntervalSinceReferenceDate: 42) }
            )
        )
    }
}

private actor StockAdjustmentRead {
    private var value = 8
    private var failure: StockError?
    private var gate: StockAdjustmentGate?

    func holdNextRead(_ gate: StockAdjustmentGate) {
        self.gate = gate
    }

    func set(_ value: Int) {
        self.value = value
    }
    func setFailure(_ failure: StockError?) {
        self.failure = failure
    }

    func read(_ id: ProductID) async throws -> Int {
        let value = value
        let failure = failure
        let gate = gate
        self.gate = nil
        await gate?.block()
        if let failure {
            throw failure
        }
        return value
    }
}

@MainActor
private final class StockAdjustmentWrites {
    var failure: (any Error)?
    var gate: StockAdjustmentGate?
    private(set) var movements: [StockMovement] = []
    private(set) var contexts: [ObjectIdentifier] = []

    func append(_ movement: StockMovement, in context: ModelContext) async throws -> StockMovement {
        movements.append(movement)
        contexts.append(ObjectIdentifier(context))
        await gate?.block()
        if let failure {
            throw failure
        }
        return movement
    }
}


enum StockAdjustmentInterruption {
    case cancelled, cooperative, closed
}

enum StockAdjustmentReadInterruption {
    case replaced, cancelled, closed
}

@MainActor
private final class StockAdjustmentGate {
    private var blocked = false
    private var waiting: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func block() async {
        blocked = true
        waiting?.resume()
        waiting = nil
        await withCheckedContinuation {
            releaseContinuation = $0
        }
    }

    func waitUntilBlocked() async {
        guard !blocked else { return }
        await withCheckedContinuation {
            waiting = $0
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}
