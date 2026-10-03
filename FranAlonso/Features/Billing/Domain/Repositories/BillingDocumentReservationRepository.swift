/// Reserves one paid request through a provider-independent numbering authority.
///
/// Implementations compare and create the complete document and its positive series
/// number atomically. Repeating an identical request returns its original allocation,
/// including timestamp, without consuming another number. Reusing a request ID with
/// changed input or a document ID belonging to another request must conflict without
/// replacing history. Ticket and invoice sequences remain independent.
///
/// Errors and cancellation do not prove that the authority failed to commit. Callers
/// retain the complete request and retry it explicitly to recover an accepted result.
/// This remote capability does not persist local state, render a PDF, or close a sale.
protocol BillingDocumentReservationRepository: Sendable {
    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument
}

/// Neutral reservation failures without provider details or business payloads.
enum BillingDocumentReservationError: Error, Equatable {
    case unavailable
    case permissionDenied
    case conflict
    case invalidResponse
}
