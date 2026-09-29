import Foundation
import Observation
import SwiftData

/// Coordinates one manual adjustment, freezing the accepted command across retries.
@Observable
@MainActor
final class StockAdjustmentViewModel {
    typealias QuantityOperation = @Sendable (ProductID) async throws -> Int
    typealias AcceptOperation = @MainActor (StockMovement, ModelContext) async throws -> StockMovement

    enum Operation: Equatable {
        case load
        case validation
        case save
    }

    enum State: Equatable {
        case idle
        case loading
        case editing
        case saving
        case failed(Operation, StockError)
        case saved
        case closed
    }

    /// A post-commit read has its own state and can never make an accepted movement writable again.
    enum BalanceState: Equatable {
        case idle
        case loading
        case loaded(Int)
        case failed(StockError)
    }

    let destination: StockAdjustmentDestination
    var direction: StockAdjustmentDirection = .entry
    var unitsText = ""
    var reason = ""
    private(set) var loadedProduct: Product?
    private(set) var quantity: Int?
    private(set) var acceptedMovement: StockMovement?
    private(set) var state: State = .idle
    private(set) var balanceState: BalanceState = .idle

    private let getProduct: GetProductUseCase
    private let getQuantity: QuantityOperation
    private let accept: AcceptOperation
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> StockMovementID
    @ObservationIgnored private var pendingMovement: StockMovement?
    @ObservationIgnored private var operationGeneration = UUID()
    @ObservationIgnored private var balanceGeneration = UUID()

    /// Injects reads and contextual acceptance without retaining a ModelContext or a View task.
    init(
        destination: StockAdjustmentDestination,
        getProduct: GetProductUseCase,
        getQuantity: @escaping QuantityOperation,
        accept: @escaping AcceptOperation,
        now: @escaping @Sendable () -> Date = { Date() },
        makeID: @escaping @Sendable () -> StockMovementID = { StockMovementID(rawValue: UUID()) }
    ) {
        self.destination = destination
        self.getProduct = getProduct
        self.getQuantity = getQuantity
        self.accept = accept
        self.now = now
        self.makeID = makeID
    }

    var canEdit: Bool {
        switch state {
        case .editing, .failed(.validation, _): true
        default: false
        }
    }

    var canSubmit: Bool {
        switch state {
        case .editing, .failed(.validation, _), .failed(.save, _): true
        default: false
        }
    }

    var canClose: Bool { state != .saving }
    var isAccepted: Bool { acceptedMovement != nil }

    /// Submitted commands still require explicit discard after failure, even if draft fields are changed later.
    var hasUnsavedChanges: Bool {
        guard canSubmit else { return false }
        return pendingMovement != nil || !unitsText.isEmpty || !reason.isEmpty || direction != .entry
    }

    /// Loads both snapshots before enabling mutation; replaced or closed requests cannot publish late data.
    func load() async {
        switch state {
        case .idle, .loading, .failed(.load, _): break
        default: return
        }
        let generation = UUID()
        operationGeneration = generation
        loadedProduct = nil
        quantity = nil
        state = .loading
        do {
            guard let product = try await getProduct(destination.productID) else {
                try Task.checkCancellation()
                guard operationGeneration == generation else { return }
                state = .failed(.load, .productNotFound)
                return
            }
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            let quantity = try await getQuantity(destination.productID)
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            loadedProduct = product
            self.quantity = quantity
            state = .editing
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError || Task.isCancelled ? .idle : .failed(.load, stockError(error))
        }
    }

    /// Captures a valid command once and reuses its full identity and payload after failure.
    /// Durable acceptance is terminal before the independent balance read starts; late cancellation cannot undo it.
    func save(in context: ModelContext) async {
        guard canSubmit, !Task.isCancelled else { return }
        let movement: StockMovement
        do {
            if let pendingMovement {
                movement = pendingMovement
            } else {
                let quantity = try StockAdjustmentQuantity(unitsText: unitsText, direction: direction)
                movement = try PrepareStockAdjustmentUseCase()(
                    id: makeID(),
                    productID: destination.productID,
                    quantityDelta: quantity.delta,
                    reason: reason,
                    occurredAt: now()
                )
                pendingMovement = movement
            }
        } catch {
            state = .failed(.validation, stockError(error))
            return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .saving
        do {
            let accepted = try await accept(movement, context)
            guard operationGeneration == generation else { return }
            acceptedMovement = accepted
            state = .saved
            await refreshQuantity()
        } catch {
            guard operationGeneration == generation else { return }
            state = .failed(.save, stockError(error))
        }
    }

    /// Refreshes only presentation after acceptance. Failure never reenables submitting the movement.
    func refreshQuantity() async {
        guard state == .saved else { return }
        let generation = UUID()
        balanceGeneration = generation
        balanceState = .loading
        do {
            let quantity = try await getQuantity(destination.productID)
            try Task.checkCancellation()
            guard balanceGeneration == generation, state == .saved else { return }
            self.quantity = quantity
            balanceState = .loaded(quantity)
        } catch {
            guard balanceGeneration == generation, state == .saved else { return }
            balanceState = .failed(stockError(error))
        }
    }

    /// Invalidates presentation responses without claiming to roll back an accepted adjustment.
    func close() {
        operationGeneration = UUID()
        balanceGeneration = UUID()
        pendingMovement = nil
        acceptedMovement = nil
        loadedProduct = nil
        quantity = nil
        direction = .entry
        unitsText = ""
        reason = ""
        balanceState = .idle
        state = .closed
    }

    private func stockError(_ error: any Error) -> StockError {
        if let error = error as? StockError {
            return error
        }
        if let error = error as? ProductError, error == .notFound {
            return .productNotFound
        }
        return .storageFailure
    }
}
