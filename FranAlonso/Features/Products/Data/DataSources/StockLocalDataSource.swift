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
            let rows = try prepareAppend([movement], in: context)
            guard let row = rows.first else { return movement }
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

    /// Prepares only missing immutable events without inserting or saving in the owning context.
    /// A caller must retain confinement and commit the complete batch without suspension.
    /// Equivalent identities precede Product eligibility; balances include every new event for each Product.
    func prepareAppend(_ batch: [StockMovement], in context: ModelContext) throws -> [StockMovementModel] {
        try performOperation {
            guard !context.hasChanges else { throw StockError.storageFailure }
            var identities: [StockMovementID: StockMovement] = [:]
            var deltas: [ProductID: [Int]] = [:]
            var rows: [StockMovementModel] = []
            for movement in batch {
                try Task.checkCancellation()
                if let duplicate = identities[movement.id] {
                    guard duplicate == movement else { throw StockError.identityConflict }
                    continue
                }
                identities[movement.id] = movement
                if let existing = try model(id: movement.id, in: context)?.toDomain() {
                    guard existing == movement else { throw StockError.identityConflict }
                    continue
                }
                if deltas[movement.productID] == nil {
                    try requireProduct(movement.productID, in: context)
                    guard try !hasProductConflict(movement.productID, in: context) else {
                        throw StockError.productConflict
                    }
                    let history = try movements(for: movement.productID, in: context).map(\.quantityDelta)
                    _ = try StockQuantityPolicy().quantity(deltas: history)
                    deltas[movement.productID] = history
                }
                deltas[movement.productID, default: []].append(movement.quantityDelta)
                rows.append(try StockMovementModel(movement))
            }
            for balance in deltas.values {
                _ = try StockQuantityPolicy().quantity(deltas: balance)
            }
            return rows
        }
    }

    /// Prepares inverses only after verifying every original and both identities' conflict fences.
    /// Catalogue eligibility does not govern compensation of immutable history; no Product is created or restored.
    /// All touched histories and final balances are checked before returning unsaved rows to the owning transaction.
    func prepareSaleReversal(
        _ sale: Sale,
        reversalID: SaleReversalID,
        in context: ModelContext
    ) throws -> [StockMovementModel] {
        try performOperation {
            guard !context.hasChanges else { throw StockError.storageFailure }
            guard case let .voided(paymentID, _, _, _, _, _, _) = sale.status else {
                throw SaleError.invalidSaleTransition
            }
            let originals = try SaleStockMovementPolicy()(sale: sale, paymentID: paymentID)
            let inverses = try SaleStockReversalPolicy()(sale: sale, reversalID: reversalID)
            var balances: [ProductID: [Int]] = [:]
            var rows: [StockMovementModel] = []
            for (original, inverse) in zip(originals, inverses) {
                try Task.checkCancellation()
                guard try !hasStockConflict(original.id, in: context),
                      try !hasStockConflict(inverse.id, in: context),
                      try model(id: original.id, in: context)?.toDomain() == original
                else {
                    throw StockError.identityConflict
                }
                if balances[original.productID] == nil {
                    let history = try movements(for: original.productID, in: context).map(\.quantityDelta)
                    _ = try StockQuantityPolicy().quantity(deltas: history)
                    balances[original.productID] = history
                }
                if let existing = try model(id: inverse.id, in: context)?.toDomain() {
                    guard existing == inverse else { throw StockError.identityConflict }
                } else {
                    rows.append(try StockMovementModel(inverse))
                    balances[inverse.productID, default: []].append(inverse.quantityDelta)
                }
            }
            for balance in balances.values {
                _ = try StockQuantityPolicy().quantity(deltas: balance)
            }
            return rows
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
    func hasStockConflict(_ id: StockMovementID, in context: ModelContext) throws -> Bool {
        let rawID = id.rawValue
        let descriptor = FetchDescriptor<StockSyncConflictModel>(predicate: #Predicate { $0.movementID == rawID })
        return try context.fetchCount(descriptor) > 0
    }
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
