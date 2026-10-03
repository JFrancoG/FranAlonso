/// Explicitly inactive composition for local selection; it cannot reserve or fabricate a document number.
struct UnavailableBillingDocumentReservationRepository: BillingDocumentReservationRepository {
    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        try Task.checkCancellation()
        throw BillingDocumentReservationError.unavailable
    }
}
