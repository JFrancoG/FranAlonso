import Foundation
import SwiftData

/// The caller-shared owner of all principal-bound materialization checkpoints in one container.
/// Renderers and remote engines run outside this actor; only Sendable snapshots cross its boundary.
@ModelActor
actor BillingDocumentPersistenceActor {
    private var saveChanges: @Sendable (ModelContext) throws -> Void = {
        try $0.save()
    }

    /// Injects a synchronous save failure while retaining the production transaction and rollback path.
    init(
        modelContainer: ModelContainer,
        saveChanges: @escaping @Sendable (ModelContext) throws -> Void
    ) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.saveChanges = saveChanges
    }

    /// Seals one complete request per principal, sale and document family before remote contact.
    /// Identical replay retains every later checkpoint; competing identifiers or terms never replace it.
    func prepare(_ request: BillingDocumentRequest, principalID: String) throws -> BillingDocumentDelivery {
        try transaction {
            try validatePrincipal(principalID)
            if let existing = try documentModel(id: request.id) {
                let retained = try authorizedDelivery(existing, principalID: principalID)
                guard retained.request == request else { throw BillingDocumentPersistenceError.conflict }
                return retained
            }
            if let existing = try documentModel(documentID: request.documentID) {
                _ = try authorizedDelivery(existing, principalID: principalID)
                throw BillingDocumentPersistenceError.conflict
            }
            for existing in try saleModels(saleID: request.saleID) {
                let retained = try authorizedDelivery(existing, principalID: principalID)
                guard retained.request.kind != request.kind else { throw BillingDocumentPersistenceError.conflict }
            }
            let pending = try BillingDocumentDelivery(request: request, principalID: principalID)
            modelContext.insert(try BillingDocumentDeliveryModel(pending))
            return pending
        }
    }

    /// Reads only an intact envelope bound to the caller's captured principal.
    func delivery(id: BillingDocumentRequestID, principalID: String) throws -> BillingDocumentDelivery? {
        try transaction {
            try validatePrincipal(principalID)
            guard let model = try documentModel(id: id) else { return nil }
            return try authorizedDelivery(model, principalID: principalID)
        }
    }

    /// Discovers retained families without relying on an ephemeral request identifier.
    /// A foreign or malformed sale row fails closed rather than being silently omitted.
    func deliveries(saleID: SaleID, principalID: String) throws -> [BillingDocumentDelivery] {
        try transaction {
            try validatePrincipal(principalID)
            return try saleModels(saleID: saleID)
                .map {
                    try authorizedDelivery($0, principalID: principalID)
                }
                .sorted { $0.id.rawValue.uuidString < $1.id.rawValue.uuidString }
        }
    }

    /// Accepts the exact sealed request's confirmed result; changed allocation replay preserves the original.
    func accept(_ document: BillingDocument, principalID: String) throws -> BillingDocumentDelivery {
        try transaction {
            try validatePrincipal(principalID)
            guard let model = try documentModel(id: document.request.id) else {
                if let existing = try documentModel(documentID: document.id) {
                    _ = try authorizedDelivery(existing, principalID: principalID)
                    throw BillingDocumentPersistenceError.conflict
                }
                throw BillingDocumentPersistenceError.notFound
            }
            var delivery = try authorizedDelivery(model, principalID: principalID)
            let retained = delivery
            try delivery.accept(document)
            if delivery != retained {
                try model.update(delivery)
            }
            return delivery
        }
    }

    /// Commits one synchronous checkpoint, rolling back failures before its durable save boundary.
    /// Cancellation after a completed save denies publication and retains that principal-bound checkpoint.
    func transaction<Value>(_ operation: () throws -> Value) throws -> Value {
        try Task.checkCancellation()
        modelContext.autosaveEnabled = false
        guard !modelContext.hasChanges else { throw BillingDocumentPersistenceError.persistenceUnavailable }
        do {
            let result = try operation()
            try Task.checkCancellation()
            if modelContext.hasChanges {
                try saveChanges(modelContext)
            }
            try Task.checkCancellation()
            return result
        } catch {
            modelContext.rollback()
            switch error {
            case let error as BillingDocumentPersistenceError:
                throw error
            case is CancellationError:
                throw CancellationError()
            case is BillingPDFStorageError, is DecodingError:
                throw BillingDocumentPersistenceError.invalidState
            default:
                throw BillingDocumentPersistenceError.persistenceUnavailable
            }
        }
    }

    /// Mutates an intact principal-bound envelope and saves only when the semantic checkpoint changes.
    func mutate(
        id: BillingDocumentRequestID,
        principalID: String,
        _ operation: (inout BillingDocumentDelivery) throws -> Void
    ) throws -> BillingDocumentDelivery {
        try transaction {
            try validatePrincipal(principalID)
            guard let model = try documentModel(id: id) else { throw BillingDocumentPersistenceError.notFound }
            var delivery = try authorizedDelivery(model, principalID: principalID)
            let retained = delivery
            try operation(&delivery)
            if delivery != retained {
                try model.update(delivery)
            }
            return delivery
        }
    }

    private func validatePrincipal(_ principalID: String) throws {
        guard !principalID.isEmpty else { throw BillingDocumentPersistenceError.unauthorized }
    }

    private func authorizedDelivery(
        _ model: BillingDocumentDeliveryModel,
        principalID: String
    ) throws -> BillingDocumentDelivery {
        let delivery = try model.toDomain()
        guard delivery.principalID == principalID else { throw BillingDocumentPersistenceError.unauthorized }
        return delivery
    }

    private func documentModel(id: BillingDocumentRequestID) throws -> BillingDocumentDeliveryModel? {
        let rawID = id.rawValue
        var descriptor = FetchDescriptor<BillingDocumentDeliveryModel>(predicate: #Predicate { $0.id == rawID })
        descriptor.fetchLimit = 2
        let models = try modelContext.fetch(descriptor)
        guard models.count <= 1 else { throw BillingDocumentPersistenceError.conflict }
        return models.first
    }

    private func documentModel(documentID: BillingDocumentID) throws -> BillingDocumentDeliveryModel? {
        let rawID = documentID.rawValue
        var descriptor = FetchDescriptor<BillingDocumentDeliveryModel>(predicate: #Predicate { $0.documentID == rawID })
        descriptor.fetchLimit = 2
        let models = try modelContext.fetch(descriptor)
        guard models.count <= 1 else { throw BillingDocumentPersistenceError.conflict }
        return models.first
    }

    private func saleModels(saleID: SaleID) throws -> [BillingDocumentDeliveryModel] {
        let rawID = saleID.rawValue
        let descriptor = FetchDescriptor<BillingDocumentDeliveryModel>(predicate: #Predicate { $0.saleID == rawID })
        return try modelContext.fetch(descriptor)
    }
}
