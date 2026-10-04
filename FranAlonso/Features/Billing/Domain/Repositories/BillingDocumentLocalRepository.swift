import Foundation

/// One principal-scoped local authority stores complete checkpoints before external work or publication.
/// Implementations serialize all writes through one container-owned actor and preserve accepted artifacts on conflicts.
protocol BillingDocumentLocalRepository: Sendable {
    var principalID: String { get }
    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery
    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery?
    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery]
    func accept(_ document: BillingDocument) async throws -> BillingDocumentDelivery
    func acceptPDF(id: BillingDocumentRequestID, pdf: Data) async throws -> BillingDocumentDelivery
    func beginUpload(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery
    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt
    ) async throws -> BillingDocumentDelivery
    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) async throws
}
