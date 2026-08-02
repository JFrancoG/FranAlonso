import Foundation
import SwiftData

private let productSyncFeedID = "products"

/// Performs context-confined Products persistence without retaining live SwiftData state.
struct ProductLocalDataSource {}

extension ProductLocalDataSource {
    /// Fetches and maps the locally persisted product snapshot.
    func fetchAll(in context: ModelContext) throws -> [Product] {
        let descriptor = FetchDescriptor<ProductModel>(
            sortBy: [SortDescriptor(\ProductModel.name)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    /// Materializes a product without creating a pending local mutation.
    func upsert(_ product: Product, in context: ModelContext) throws {
        try materialize(product, in: context)
        try saveChanges(in: context)
    }

    /// Commits a product and an immutable causal upsert in the same save boundary.
    ///
    /// A tombstone or pending deletion blocks ordinary upserts so restoration cannot occur
    /// accidentally. A future explicit restore flow owns that separate state transition.
    func persistPendingUpsert(_ product: Product, operationID: UUID, in context: ModelContext) throws {
        try requireClean(context)

        do {
            guard try conflict(for: product.id, in: context) == nil else {
                throw ProductLocalDataSourceError.syncConflictPending(product.id)
            }
            guard try !hasDeletionState(for: product.id, in: context) else {
                throw ProductLocalDataSourceError.restoreRequiresExplicitResolution(
                    product.id
                )
            }

            let payload = ProductDTO(product)
            let operations = try pendingOperations(
                for: product.id,
                in: context
            )
            let head = try pendingHead(
                from: operations,
                productID: product.id
            )
            let headPayload: ProductDTO?
            if case .upsert(let upsert) = head {
                headPayload = upsert.product
            } else {
                headPayload = nil
            }

            if headPayload != payload {
                try ensureOperationIdentityAvailable(
                    operationID,
                    in: context
                )
                context.insert(
                    try ProductPendingUpsertModel(
                        productID: product.id.rawValue,
                        operationID: operationID,
                        predecessorOperationID: head?.operationID,
                        base: try remoteBase(for: product.id, in: context),
                        payload: payload
                    )
                )
            }

            try materialize(product, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes the active product and commits a durable tombstone operation atomically.
    ///
    /// An already deleted product is a no-op only when no live remote state or pending chain
    /// remains. A repeated delete keeps the existing pending operation identity.
    func persistPendingDelete(_ id: ProductID, operationID: UUID, in context: ModelContext) throws {
        try requireClean(context)

        do {
            let operations = try pendingOperations(for: id, in: context)
            if operations.contains(where: { operation in
                if case .delete = operation { return true }
                return false
            }) {
                if let model = try model(for: id, in: context) {
                    context.delete(model)
                    try saveChanges(in: context)
                }
                return
            }

            let localModel = try model(for: id, in: context)
            let remoteRecord = try remoteState(for: id, in: context)?.decodeRecord()
            guard localModel != nil
                    || !operations.isEmpty
                    || remoteRecord?.isLive == true else {
                return
            }

            try ensureOperationIdentityAvailable(operationID, in: context)
            let head = try pendingHead(from: operations, productID: id)
            context.insert(
                try ProductPendingDeleteModel(
                    productID: id.rawValue,
                    operationID: operationID,
                    predecessorOperationID: head?.operationID,
                    base: try remoteBase(for: id, in: context)
                )
            )
            if let localModel {
                context.delete(localModel)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Returns every immutable pending operation in deterministic causal order.
    func pendingOperations(in context: ModelContext) throws -> [ProductPendingOperation] {
        let upserts = try context.fetch(
            FetchDescriptor<ProductPendingUpsertModel>()
        ).map { model in
            ProductPendingOperation.upsert(
                ProductPendingUpsert(
                    productID: model.productID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    product: try model.decodePayload()
                )
            )
        }
        let deletes = try context.fetch(
            FetchDescriptor<ProductPendingDeleteModel>()
        ).map { model in
            ProductPendingOperation.delete(
                ProductPendingDelete(
                    productID: model.productID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        return try causallySorted(upserts + deletes)
    }

    /// Returns only upserts from the complete causal operation chain.
    func pendingUpserts(in context: ModelContext) throws -> [ProductPendingUpsert] {
        try pendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns operations eligible for delivery while preserving delete-wins semantics.
    func deliverablePendingOperations(in context: ModelContext) throws -> [ProductPendingOperation] {
        let conflictedProductIDs = Set(
            try context.fetch(
                FetchDescriptor<ProductSyncConflictModel>()
            ).map(\.productID)
        )

        return try pendingOperations(in: context).filter { operation in
            switch operation {
            case .delete:
                true
            case .upsert:
                !conflictedProductIDs.contains(operation.productID)
            }
        }
    }

    /// Returns only deliverable upserts that are not blocked by conflicts.
    func deliverablePendingUpserts(in context: ModelContext) throws -> [ProductPendingUpsert] {
        try deliverablePendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns the durable Products feed position, or nil before the first bootstrap.
    func cursor(in context: ModelContext) throws -> ProductSyncCursor? {
        try cursorModel(in: context).map { model in
            guard model.changeSequence >= 0 else { throw ProductSyncPersistenceError.invalidCursor }
            return ProductSyncCursor(
                changeSequence: model.changeSequence
            )
        }
    }

    /// Returns the validated durable schedule for one retry scope, when present.
    func retryState(for scope: SyncRetryScope, in context: ModelContext) throws -> SyncRetryState? {
        try retryModel(for: scope, in: context)?.decodeState(for: scope)
    }

    /// Inserts or replaces one durable retry schedule and commits it explicitly.
    func saveRetryState(_ state: SyncRetryState, in context: ModelContext) throws {
        try requireClean(context)
        do {
            if let model = try retryModel(for: state.scope, in: context) {
                try model.update(with: state)
            } else {
                context.insert(ProductSyncRetryModel(state))
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes a transient backoff without discarding its pending sync operation.
    func clearRetryState(for scope: SyncRetryScope, in context: ModelContext) throws {
        try requireClean(context)
        do {
            try deleteRetryState(for: scope, in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Reconciles a complete remote batch and advances its cursor in one local commit.
    ///
    /// Any decoding, policy, identity or save failure rolls back every materialization,
    /// tombstone, conflict, acknowledgement and cursor change from this batch.
    func reconcileRemoteBatch(
        _ batch: ProductRemoteChangeBatch,
        policy: ProductSyncPolicy,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let currentCursor = try cursor(in: context)
            guard batch.nextCursor.changeSequence >= 0,
                  batch.nextCursor.changeSequence
                    >= (currentCursor?.changeSequence ?? 0) else {
                throw ProductSyncPersistenceError.invalidCursor
            }
            for record in batch.records {
                if let sequence = record.changeSequence {
                    guard sequence > 0,
                          sequence <= batch.nextCursor.changeSequence else {
                        throw ProductSyncPersistenceError.invalidCursor
                    }
                } else if currentCursor != nil {
                    throw ProductSyncPersistenceError.invalidCursor
                }
            }
            let receivedMaximum = batch.records
                .compactMap(\.changeSequence)
                .max()
                ?? 0
            let expectedNextSequence = max(
                currentCursor?.changeSequence ?? 0,
                receivedMaximum
            )
            guard batch.nextCursor.changeSequence
                    == expectedNextSequence else {
                throw ProductSyncPersistenceError.invalidCursor
            }

            let orderedRecords = batch.records.sorted { left, right in
                let leftKey = (left.changeSequence ?? 0, left.id)
                let rightKey = (right.changeSequence ?? 0, right.id)
                return leftKey < rightKey
            }
            for record in orderedRecords {
                let productID = ProductID(rawValue: try record.stableProductID())
                if try isStale(record, for: productID, in: context) {
                    continue
                }
                let operation = try pendingOperations(
                    for: productID,
                    in: context
                ).first
                guard let operation else {
                    try applyRemoteObservation(record, in: context)
                    continue
                }

                switch policy.decision(for: operation, against: record) {
                case .apply:
                    try applyRemoteObservation(record, in: context)
                case .alreadyApplied(let acknowledgedRecord):
                    try applyAcknowledgement(
                        operation: operation,
                        record: acknowledgedRecord,
                        in: context
                    )
                    try deleteRetryState(
                        for: .operation(operation.operationID),
                        in: context
                    )
                case .conflict(let reason, let remoteRecord):
                    guard case .upsert(let upsert) = operation else {
                        throw ProductSyncPersistenceError.entityIdentityMismatch
                    }
                    try applyConflict(
                        operation: upsert,
                        reason: reason,
                        remoteRecord: remoteRecord,
                        in: context
                    )
                    try deleteRetryState(
                        for: .operation(operation.operationID),
                        in: context
                    )
                case .invalid(let error):
                    throw error
                }
            }

            try advanceCursor(batch.nextCursor, in: context)
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Persists a remote acknowledgement without overwriting newer local work.
    func acknowledge(
        operationID: UUID,
        record: ProductRemoteRecord,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            let operation = try requirePendingOperation(
                operationID: operationID,
                in: context
            )
            try applyAcknowledgement(
                operation: operation,
                record: record,
                in: context
            )
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Records an authoritative remote observation while preserving pending work.
    func recordRemoteObservation(_ record: ProductRemoteRecord, in context: ModelContext) throws {
        try requireClean(context)
        do {
            try applyRemoteObservation(record, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Preserves the local upsert and complete remote state for explicit resolution.
    func recordConflict(
        operation: ProductPendingUpsert,
        reason: ProductSyncConflictReason,
        remoteRecord: ProductRemoteRecord?,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            try applyConflict(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord,
                in: context
            )
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Deletes a product by stable identity without creating synchronized work.
    func delete(_ id: ProductID, in context: ModelContext) throws {
        guard let model = try model(for: id, in: context) else { return }
        context.delete(model)
        try saveChanges(in: context)
    }

    private func applyAcknowledgement(
        operation: ProductPendingOperation,
        record: ProductRemoteRecord,
        in context: ModelContext
    ) throws {
        guard try record.stableProductID() == operation.productID else {
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
        switch operation {
        case .upsert(let upsert):
            guard record.lastOperationID == upsert.operationID,
                  record.liveProduct == upsert.product else {
                throw ProductSyncPersistenceError.entityIdentityMismatch
            }
        case .delete:
            guard record.isTombstone else { throw ProductSyncPersistenceError.entityIdentityMismatch }
        }

        try persistRemoteState(record, in: context)
        switch operation {
        case .upsert(let upsert):
            if let model = try pendingUpsertModel(
                operationID: upsert.operationID,
                in: context
            ) {
                context.delete(model)
            }
            let descendantsRemain = try pendingOperations(
                for: ProductID(rawValue: upsert.productID),
                in: context
            ).contains { $0.operationID != upsert.operationID }
            if !descendantsRemain,
               try conflict(
                for: ProductID(rawValue: upsert.productID),
                in: context
               ) == nil,
               let product = record.liveProduct {
                try materialize(try product.toDomain(), in: context)
            }
        case .delete(let delete):
            try removePendingChain(
                for: ProductID(rawValue: delete.productID),
                in: context
            )
            if let conflict = try conflict(
                for: ProductID(rawValue: delete.productID),
                in: context
            ) {
                context.delete(conflict)
            }
            if let model = try model(
                for: ProductID(rawValue: delete.productID),
                in: context
            ) {
                context.delete(model)
            }
        }
    }

    private func applyRemoteObservation(_ record: ProductRemoteRecord, in context: ModelContext) throws {
        let productID = ProductID(rawValue: try record.stableProductID())
        try persistRemoteState(record, in: context)
        let hasPending = try !pendingOperations(
            for: productID,
            in: context
        ).isEmpty
        let hasConflict = try conflict(for: productID, in: context) != nil

        switch record.content {
        case .live(let product):
            if !hasPending, !hasConflict {
                try materialize(try product.toDomain(), in: context)
            }
        case .tombstone:
            if let model = try model(for: productID, in: context) {
                context.delete(model)
            }
        }
    }

    private func applyConflict(
        operation: ProductPendingUpsert,
        reason: ProductSyncConflictReason,
        remoteRecord: ProductRemoteRecord?,
        in context: ModelContext
    ) throws {
        if let remoteRecord,
           try remoteRecord.stableProductID() != operation.productID {
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
        let productID = ProductID(rawValue: operation.productID)
        if let model = try conflict(for: productID, in: context) {
            try model.update(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord
            )
        } else {
            context.insert(
                try ProductSyncConflictModel(
                    operation: operation,
                    reason: reason,
                    remoteRecord: remoteRecord
                )
            )
        }
        if let remoteRecord {
            try persistRemoteState(remoteRecord, in: context)
            if remoteRecord.isTombstone,
               let localModel = try model(for: productID, in: context) {
                context.delete(localModel)
            }
        }
    }

    private func isStale(_ record: ProductRemoteRecord, for id: ProductID, in context: ModelContext) throws -> Bool {
        guard let current = try remoteState(for: id, in: context)?.decodeRecord() else {
            return false
        }
        switch (current.changeSequence, record.changeSequence) {
        case (.some(let currentSequence), .some(let incomingSequence)):
            if incomingSequence < currentSequence { return true }
            if incomingSequence == currentSequence, current != record {
                throw ProductSyncPersistenceError.invalidCursor
            }
            return incomingSequence == currentSequence
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return current == record
        }
    }

    private func advanceCursor(_ cursor: ProductSyncCursor, in context: ModelContext) throws {
        if let model = try cursorModel(in: context) {
            model.advance(to: cursor.changeSequence)
        } else {
            context.insert(
                ProductSyncCursorModel(
                    feedID: productSyncFeedID,
                    changeSequence: cursor.changeSequence
                )
            )
        }
    }

    private func cursorModel(in context: ModelContext) throws -> ProductSyncCursorModel? {
        var descriptor = FetchDescriptor<ProductSyncCursorModel>(
            predicate: #Predicate { model in
                model.feedID == productSyncFeedID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func retryModel(for scope: SyncRetryScope, in context: ModelContext) throws -> ProductSyncRetryModel? {
        let scopeID = scope.storageID
        var descriptor = FetchDescriptor<ProductSyncRetryModel>(
            predicate: #Predicate { model in
                model.scopeID == scopeID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func deleteRetryState(for scope: SyncRetryScope, in context: ModelContext) throws {
        if let model = try retryModel(for: scope, in: context) {
            context.delete(model)
        }
    }

    private func requireClean(_ context: ModelContext) throws {
        guard !context.hasChanges else { throw ProductLocalDataSourceError.contextHasUncommittedChanges }
    }

    private func model(for id: ProductID, in context: ModelContext) throws -> ProductModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ProductModel>(
            predicate: #Predicate { model in model.id == rawIdentifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingOperations(for id: ProductID, in context: ModelContext) throws -> [ProductPendingOperation] {
        try pendingOperations(in: context).filter {
            $0.productID == id.rawValue
        }
    }

    private func pendingUpsertModels(
        for id: ProductID,
        in context: ModelContext
    ) throws -> [ProductPendingUpsertModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ProductPendingUpsertModel>(
                predicate: #Predicate { model in
                    model.productID == rawIdentifier
                }
            )
        )
    }

    private func pendingDeleteModels(
        for id: ProductID,
        in context: ModelContext
    ) throws -> [ProductPendingDeleteModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ProductPendingDeleteModel>(
                predicate: #Predicate { model in
                    model.productID == rawIdentifier
                }
            )
        )
    }

    private func pendingUpsertModel(operationID: UUID, in context: ModelContext) throws -> ProductPendingUpsertModel? {
        var descriptor = FetchDescriptor<ProductPendingUpsertModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingDeleteModel(operationID: UUID, in context: ModelContext) throws -> ProductPendingDeleteModel? {
        var descriptor = FetchDescriptor<ProductPendingDeleteModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func requirePendingOperation(
        operationID: UUID,
        in context: ModelContext
    ) throws -> ProductPendingOperation {
        if let model = try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) {
            return .upsert(
                ProductPendingUpsert(
                    productID: model.productID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    product: try model.decodePayload()
                )
            )
        }
        if let model = try pendingDeleteModel(
            operationID: operationID,
            in: context
        ) {
            return .delete(
                ProductPendingDelete(
                    productID: model.productID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        throw ProductSyncPersistenceError.entityIdentityMismatch
    }

    private func ensureOperationIdentityAvailable(_ operationID: UUID, in context: ModelContext) throws {
        guard try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) == nil,
        try pendingDeleteModel(
            operationID: operationID,
            in: context
        ) == nil else {
            throw ProductSyncPersistenceError.duplicateOperationIdentity(
                operationID
            )
        }
    }

    private func pendingHead(
        from operations: [ProductPendingOperation],
        productID: ProductID
    ) throws -> ProductPendingOperation? {
        let predecessorIDs = Set(
            operations.compactMap(\.predecessorOperationID)
        )
        let heads = operations.filter {
            !predecessorIDs.contains($0.operationID)
        }
        guard heads.count <= 1 else {
            throw ProductSyncPersistenceError.ambiguousPendingLineage(productID)
        }
        return heads.first
    }

    private func remoteState(for id: ProductID, in context: ModelContext) throws -> ProductRemoteStateModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ProductRemoteStateModel>(
            predicate: #Predicate { state in
                state.productID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func remoteBase(for id: ProductID, in context: ModelContext) throws -> ProductRemoteBase {
        guard let record = try remoteState(for: id, in: context)?.decodeRecord() else {
            return .absent
        }
        switch (record.version, record.content) {
        case (.legacy, .live(let product)):
            return .legacy(product)
        case (.versioned(let revision, _), .live):
            return .versioned(revision)
        case (.versioned(let revision, _), .tombstone):
            return .tombstone(revision)
        case (.legacy, .tombstone):
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
    }

    private func hasDeletionState(for id: ProductID, in context: ModelContext) throws -> Bool {
        if try !pendingDeleteModels(for: id, in: context).isEmpty {
            return true
        }
        return try remoteState(for: id, in: context)?.decodeRecord().isTombstone
            == true
    }

    private func persistRemoteState(_ record: ProductRemoteRecord, in context: ModelContext) throws {
        let productID = ProductID(rawValue: try record.stableProductID())
        if let state = try remoteState(for: productID, in: context) {
            try state.update(record: record)
        } else {
            context.insert(try ProductRemoteStateModel(record: record))
        }
    }

    private func conflict(for id: ProductID, in context: ModelContext) throws -> ProductSyncConflictModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ProductSyncConflictModel>(
            predicate: #Predicate { conflict in
                conflict.productID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func removePendingChain(for id: ProductID, in context: ModelContext) throws {
        for model in try pendingUpsertModels(for: id, in: context) {
            context.delete(model)
        }
        for model in try pendingDeleteModels(for: id, in: context) {
            context.delete(model)
        }
    }

    private func causallySorted(_ operations: [ProductPendingOperation]) throws -> [ProductPendingOperation] {
        var remaining: [UUID: ProductPendingOperation] = [:]
        for operation in operations {
            guard remaining[operation.operationID] == nil else {
                throw ProductSyncPersistenceError.duplicateOperationIdentity(
                    operation.operationID
                )
            }
            remaining[operation.operationID] = operation
        }
        var sorted: [ProductPendingOperation] = []

        while !remaining.isEmpty {
            let ready = remaining.values.filter { operation in
                guard let predecessor = operation.predecessorOperationID else { return true }
                return remaining[predecessor] == nil
            }.sorted { left, right in
                let leftKey = "\(left.productID.uuidString)/\(left.operationID.uuidString)"
                let rightKey = "\(right.productID.uuidString)/\(right.operationID.uuidString)"
                return leftKey < rightKey
            }

            guard !ready.isEmpty else {
                guard let remainingOperation = remaining.values.first else { return sorted }
                throw ProductSyncPersistenceError.cyclicPendingLineage(
                    ProductID(rawValue: remainingOperation.productID)
                )
            }
            for operation in ready {
                sorted.append(operation)
                remaining.removeValue(forKey: operation.operationID)
            }
        }
        return sorted
    }

    private func materialize(_ product: Product, in context: ModelContext) throws {
        if let model = try model(for: product.id, in: context) {
            model.update(from: product)
        } else {
            context.insert(ProductModel(product))
        }
    }

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

/// Failures that protect the boundary of a caller-owned Products context.
enum ProductLocalDataSourceError: Error, Equatable {
    case contextHasUncommittedChanges
    case syncConflictPending(ProductID)
    case restoreRequiresExplicitResolution(ProductID)
}

private extension ProductRemoteRecord {
    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else { return nil }
        return lastOperationID
    }
}
