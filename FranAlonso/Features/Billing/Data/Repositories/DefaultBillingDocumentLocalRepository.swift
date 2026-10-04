import Foundation

/// Validates the captured shell capability before and after each local persistence operation.
/// Knowing the principal alone grants no access; only immutable principal-bound snapshots leave the actor.
struct DefaultBillingDocumentLocalRepository: BillingDocumentLocalRepository {
    let persistence: BillingDocumentPersistenceActor
    let access: BillingAssetAccess
    var principalID: String { access.principalID }

    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        try await authorized {
            try await persistence.prepare(request, principalID: principalID)
        }
    }

    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        try await authorized {
            try await persistence.delivery(id: id, principalID: principalID)
        }
    }

    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        try await authorized {
            try await persistence.deliveries(saleID: saleID, principalID: principalID)
        }
    }

    func accept(_ document: BillingDocument) async throws -> BillingDocumentDelivery {
        try await authorized {
            try await persistence.accept(document, principalID: principalID)
        }
    }

    func acceptPDF(id: BillingDocumentRequestID, pdf: Data) async throws -> BillingDocumentDelivery {
        try await authorized {
            try await persistence.acceptPDF(id: id, pdf: pdf, principalID: principalID)
        }
    }

    func beginUpload(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        try await authorized {
            try await persistence.beginUpload(id: id, principalID: principalID)
        }
    }

    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt
    ) async throws -> BillingDocumentDelivery {
        try await authorized {
            try await persistence.completeUpload(id: id, receipt: receipt, principalID: principalID)
        }
    }

    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) async throws {
        try await authorized {
            try await persistence.recordFailure(
                id: id,
                phase: phase,
                reason: reason,
                attempt: attempt,
                principalID: principalID
            )
        }
    }

    private func authorized<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await validateAccess()
        do {
            let result = try await operation()
            try await validateAccess()
            return result
        } catch {
            // Revocation also fences an unsuccessful operation; cancellation propagates unchanged.
            try await validateAccess()
            throw error
        }
    }

    private func validateAccess() async throws {
        do {
            try await access.validate()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BillingDocumentPersistenceError.unauthorized
        }
    }
}
