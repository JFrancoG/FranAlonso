/// Reserves one immutable paid request without becoming a second numbering authority.
struct ReserveBillingDocumentUseCase<Repository: BillingDocumentReservationRepository> {
    private let reservationRepository: Repository

    /// Makes one remote attempt and accepts only a fully correlated numbered result.
    ///
    /// The caller retains the complete request across retries; this use case creates no
    /// identities, timestamps or numbers and keeps no cache. Failure or cancellation may
    /// follow a remote commit, which a later explicit attempt can recover with that request.
    /// Success records allocation only; local materialization, PDF and sale closure follow.
    /// - Throws: A neutral reservation failure, or native cancellation before/after contact.
    func callAsFunction(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        try Task.checkCancellation()
        let document: BillingDocument
        do {
            document = try await reservationRepository.reserve(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw error as? BillingDocumentReservationError ?? .unavailable
        }
        try Task.checkCancellation()
        guard document.request == request else { throw BillingDocumentReservationError.invalidResponse }
        return document
    }
}

extension ReserveBillingDocumentUseCase {
    init(repository: Repository) {
        self.init(reservationRepository: repository)
    }
}
