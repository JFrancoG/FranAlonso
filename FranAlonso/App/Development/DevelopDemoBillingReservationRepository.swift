#if FRANALONSO_AUTH_FIXTURE
import Foundation

/// Isolates coherent synthetic numbering to one Debug-Develop launch without contacting a real series.
actor DevelopDemoBillingReservationRepository: BillingDocumentReservationRepository {
    private var records: [BillingDocumentRequestID: BillingDocument] = [:]
    private var documentClaims: [BillingDocumentID: BillingDocumentRequestID] = [:]
    private var counters: [BillingDocumentSeries: Int] = [.ticket: 900_000, .invoice: 950_000]

    var documentCount: Int { records.count }

    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        try Task.checkCancellation()
        if let retained = records[request.id] {
            guard retained.request == request else { throw BillingDocumentReservationError.conflict }
            return retained
        }
        guard documentClaims[request.documentID] == nil else { throw BillingDocumentReservationError.conflict }
        let previous = counters[request.kind.series] ?? 0
        guard previous < 999_999 else { throw BillingDocumentReservationError.unavailable }
        let value = previous + 1
        let document = try BillingDocument.numbered(
            request: request,
            number: BillingDocumentNumber(series: request.kind.series, value: value),
            issuedAt: Date(timeIntervalSince1970: 1_790_010_000)
        )
        counters[request.kind.series] = value
        records[request.id] = document
        documentClaims[request.documentID] = request.id
        return document
    }
}
#endif
