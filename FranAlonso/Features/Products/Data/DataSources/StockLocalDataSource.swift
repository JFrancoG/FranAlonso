import Foundation
import SwiftData

/// Owns the synchronous acceptance boundary shared by every local stock write route.
/// It requires a clean caller-owned context and never suspends between checking and committing.
struct StockLocalDataSource {
    private let commitChanges: (ModelContext) throws -> Void
}

extension StockLocalDataSource {
    /// Injects the commit boundary while retaining context confinement.
    init(
        save: @escaping (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.init(commitChanges: save)
    }

    /// Accepts a new event or returns its immutable equivalent without writing on an exact retry.
    /// Identity conflicts are checked before the Product's current eligibility.
    func append(_ movement: StockMovement, in context: ModelContext) throws -> StockMovement {
        try performOperation {
            guard !context.hasChanges else { throw StockError.storageFailure }
            if let existing = try model(id: movement.id, in: context)?.toDomain() {
                guard existing == movement else { throw StockError.identityConflict }
                return existing
            }
            try requireProduct(movement.productID, in: context)
            guard try !hasProductConflict(movement.productID, in: context) else { throw StockError.productConflict }
            let deltas = try movements(for: movement.productID, in: context).map(\.quantityDelta)
            let policy = StockQuantityPolicy()
            _ = try policy.quantity(deltas: deltas)
            _ = try policy.quantity(deltas: deltas + [movement.quantityDelta])
            let row = try StockMovementModel(movement)
            try Task.checkCancellation()
            context.insert(row)
            do {
                try commitChanges(context)
            } catch {
                context.rollback()
                throw error
            }
            return movement
        }
    }

    /// Reads accepted history independently of subsequent Product metadata changes.
    func movement(id: StockMovementID, in context: ModelContext) throws -> StockMovement? {
        try performOperation {
            try model(id: id, in: context)?.toDomain()
        }
    }

    /// Derives the exact current quantity for a present Product, including inactive or conflicted metadata.
    func quantity(for productID: ProductID, in context: ModelContext) throws -> Int {
        try performOperation {
            try requireProduct(productID, in: context)
            let deltas = try movements(for: productID, in: context).map(\.quantityDelta)
            return try StockQuantityPolicy().quantity(deltas: deltas)
        }
    }
}

private extension StockLocalDataSource {
    func performOperation<Value>(
        _ operation: () throws -> Value
    ) throws -> Value {
        try Task.checkCancellation()
        do {
            return try operation()
        } catch let error as StockError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw StockError.storageFailure
        }
    }

    func model(id: StockMovementID, in context: ModelContext) throws -> StockMovementModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<StockMovementModel>(predicate: #Predicate { $0.id == rawIdentifier })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func movements(for productID: ProductID, in context: ModelContext) throws -> [StockMovement] {
        let rawIdentifier = productID.rawValue
        let descriptor = FetchDescriptor<StockMovementModel>(predicate: #Predicate { $0.productID == rawIdentifier })
        return try context.fetch(descriptor).map {
            try $0.toDomain()
        }
    }

    func requireProduct(_ productID: ProductID, in context: ModelContext) throws {
        guard try ProductLocalDataSource().product(id: productID, in: context) != nil else {
            throw StockError.productNotFound
        }
    }

    func hasProductConflict(_ productID: ProductID, in context: ModelContext) throws -> Bool {
        let rawIdentifier = productID.rawValue
        var descriptor = FetchDescriptor<ProductSyncConflictModel>(
            predicate: #Predicate { $0.productID == rawIdentifier }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }
}
