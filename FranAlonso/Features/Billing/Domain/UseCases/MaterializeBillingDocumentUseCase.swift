import Foundation

/// Advances one durable request through existing motors without rerendering an accepted PDF or closing its sale.
struct MaterializeBillingDocumentUseCase<Repository: BillingDocumentReservationRepository> {
    private let localRepository: any BillingDocumentLocalRepository
    private let reserveDocument: ReserveBillingDocumentUseCase<Repository>
    private let renderDocument: RenderBillingDocumentUseCase
    private let uploadDocument: UploadBillingDocumentPDFUseCase
    private let access: BillingAssetAccess

    /// Saves the complete principal-bound request before any remote motor can be contacted.
    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        try await authorize()
        let delivery = try await localRepository.prepare(request)
        try await authorize()
        guard delivery.principalID == access.principalID, delivery.request == request else {
            throw BillingDocumentPersistenceError.conflict
        }
        return delivery
    }

    /// Recovers a local checkpoint, denying publication after capability revocation or cancellation.
    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        try await authorize()
        let delivery = try await localRepository.delivery(id: id)
        try await authorize()
        if let delivery {
            guard delivery.id == id, delivery.principalID == access.principalID else {
                throw BillingDocumentPersistenceError.invalidState
            }
        }
        return delivery
    }

    /// Returns every retained family for explicit selection without generating new identities.
    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        try await authorize()
        let deliveries = try await localRepository.deliveries(saleID: saleID)
        try await authorize()
        guard deliveries.allSatisfy({ $0.principalID == access.principalID && $0.request.sale.id == saleID }) else {
            throw BillingDocumentPersistenceError.invalidState
        }
        return deliveries
    }

    /// Reserves the retained request once per explicit attempt and saves its allocation before rendering is allowed.
    func reserveNumber(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        let delivery = try await required(id)
        guard delivery.document == nil else { return delivery }
        do {
            let document = try await reserveDocument(delivery.request)
            try await authorize()
            let accepted = try await localRepository.accept(document)
            try await authorize()
            return accepted
        } catch {
            try await retainFailure(id: id, phase: .numbering, attempt: nil, error: error)
            throw normalized(error)
        }
    }

    /// Returns only a final locally saved checkpoint; remote acceptance alone is never final presentation.
    func callAsFunction(_ id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        var delivery = try await reserveNumber(id: id)
        guard !delivery.isFinal else { return delivery }
        var phase: BillingDocumentDeliveryPhase = .rendering
        var attempt: Int?
        do {
            guard let document = delivery.document else { throw BillingDocumentPersistenceError.invalidState }
            if delivery.pdf == nil {
                try await authorize()
                let pdf = try await renderDocument(document)
                try await authorize()
                delivery = try await localRepository.acceptPDF(id: id, pdf: pdf)
                try await authorize()
            }
            phase = .upload
            delivery = try await localRepository.beginUpload(id: id)
            try await authorize()
            guard !delivery.isFinal else { return delivery }
            attempt = delivery.uploadAttempts
            guard let pdf = delivery.pdf else { throw BillingDocumentPersistenceError.invalidState }
            let receipt = try await uploadDocument(document, pdf: pdf, access: access)
            try await authorize()
            let final = try await localRepository.completeUpload(id: id, receipt: receipt)
            try await authorize()
            guard final.isFinal else { throw BillingDocumentPersistenceError.invalidState }
            return final
        } catch {
            try await retainFailure(id: id, phase: phase, attempt: attempt, error: error)
            throw normalized(error)
        }
    }
}

private extension MaterializeBillingDocumentUseCase {
    func authorize() async throws {
        do {
            try await access.validate()
            guard localRepository.principalID == access.principalID else {
                throw BillingDocumentPersistenceError.unauthorized
            }
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw CancellationError()
            }
            throw BillingDocumentPersistenceError.unauthorized
        }
    }

    func required(_ id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        guard let delivery = try await delivery(id: id) else { throw BillingDocumentPersistenceError.notFound }
        return delivery
    }

    func retainFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        attempt: Int?,
        error: any Error
    ) async throws {
        try Task.checkCancellation()
        if error is CancellationError {
            throw CancellationError()
        }
        try await authorize()
        let reason: BillingDocumentFailure
        switch error {
        case BillingDocumentReservationError.permissionDenied, BillingPDFStorageError.permissionDenied,
             BillingAssetError.unauthorized, BillingDocumentPersistenceError.unauthorized:
            reason = .permissionDenied
        case BillingDocumentReservationError.conflict, BillingPDFStorageError.conflict,
             BillingDocumentPersistenceError.conflict:
            reason = .conflict
        default:
            reason = .unavailable
        }
        try? await localRepository.recordFailure(id: id, phase: phase, reason: reason, attempt: attempt)
        try await authorize()
    }

    func normalized(_ error: any Error) -> any Error {
        switch error {
        case is BillingDocumentReservationError, is BillingDocumentPersistenceError, is BillingPDFStorageError,
             is BillingAssetError, is BillingPDFRenderError, is BillingDocumentError:
            error
        default:
            BillingDocumentPersistenceError.persistenceUnavailable
        }
    }
}

extension MaterializeBillingDocumentUseCase {
    init(
        local: any BillingDocumentLocalRepository,
        reserve: ReserveBillingDocumentUseCase<Repository>,
        render: RenderBillingDocumentUseCase,
        upload: UploadBillingDocumentPDFUseCase,
        access: BillingAssetAccess
    ) {
        self.init(
            localRepository: local,
            reserveDocument: reserve,
            renderDocument: render,
            uploadDocument: upload,
            access: access
        )
    }
}
