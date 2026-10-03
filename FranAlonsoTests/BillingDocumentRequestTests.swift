import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing document request")
struct BillingDocumentRequestTests {
    @Test(arguments: [ViewModelSaleStage.draft, .inProgress, .awaitingPayment])
    func `unpaid sales cannot request a ticket or invoice`(_ stage: ViewModelSaleStage) throws {
        let sale = try viewModelSale(stage: stage)

        for kind in [BillingDocumentKind.ticket, .invoice] {
            #expect(throws: BillingDocumentError.requiresPayment) {
                try billingRequest(sale: sale, kind: kind)
            }
            let payload = requestPayload(sale: sale, kind: kind)
            #expect(throws: BillingDocumentError.requiresPayment) {
                try decodeBillingRequest(payload)
            }
        }
    }

    @Test(arguments: [ViewModelSaleStage.closed, .voided])
    func `terminal sales cannot open a new ticket or invoice request`(_ stage: ViewModelSaleStage) throws {
        let sale = try viewModelSale(stage: stage)

        for kind in [BillingDocumentKind.ticket, .invoice] {
            #expect(throws: BillingDocumentError.terminalSale) {
                try billingRequest(sale: sale, kind: kind)
            }
            let payload = requestPayload(sale: sale, kind: kind)
            #expect(throws: BillingDocumentError.terminalSale) {
                try decodeBillingRequest(payload)
            }
        }
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `a paid sale can request either family and proceed to matching confirmation`(
        _ kind: BillingDocumentKind
    ) throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let request = try billingRequest(sale: sale, kind: kind)
        let recovered = try decodeBillingRequest(requestPayload(sale: sale, kind: kind))
        let document = try BillingDocument.numbered(
            request: recovered,
            number: BillingDocumentNumber(series: kind.series, value: 1),
            issuedAt: Date(timeIntervalSince1970: 202)
        )
        var state = BillingDocumentLocalState.pendingNumber(request)

        try state.accept(document)

        #expect(state == .numbered(document))
        #expect(state.document?.kind == kind)
        #expect(state.document?.saleID == sale.id)
    }

    @Test
    func `a request retains the paid snapshot after its source sale closes and is voided`() throws {
        var sale = try viewModelSale(stage: .awaitingDocument)
        let capturedSale = sale
        let request = try billingRequest(sale: sale, kind: .invoice)
        var state = BillingDocumentLocalState.pendingNumber(request)

        try sale.close(
            documentID: BillingDocumentID(rawValue: viewModelUUID(702)),
            closedAt: Date(timeIntervalSince1970: 300)
        )
        try sale.void(
            reversalID: SaleReversalID(rawValue: viewModelUUID(999)),
            voidedAt: Date(timeIntervalSince1970: 400)
        )
        try state.failNumbering(reason: .unavailable)
        state = try JSONDecoder().decode(BillingDocumentLocalState.self, from: JSONEncoder().encode(state))
        try state.retryNumbering()

        #expect(state.request.sale == capturedSale)
        #expect(state.request.sale != sale)
        #expect(state.request.sale.lines == capturedSale.lines)
        #expect(state.request.sale.status == .awaitingDocument(
            paymentID: PaymentID(rawValue: viewModelUUID(800)),
            method: .cash,
            paidAt: Date(timeIntervalSince1970: 200)
        ))
        #expect(state.request.id == request.id)
        #expect(state.request.documentID == request.documentID)
    }

    @Test
    func `request recovery tolerates a caller clock behind the recorded payment`() throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let callerTime = Date(timeIntervalSince1970: 199)
        let request = try billingRequest(sale: sale, kind: .ticket, requestedAt: callerTime)
        let payload = requestPayload(sale: sale, kind: .ticket, requestedAt: callerTime)
        let recovered = try decodeBillingRequest(payload)
        let document = try BillingDocument.numbered(
            request: recovered,
            number: BillingDocumentNumber(series: .ticket, value: 1),
            issuedAt: Date(timeIntervalSince1970: 202)
        )
        var state = BillingDocumentLocalState.pendingNumber(request)
        try state.accept(document)

        #expect(state == .numbered(document))
        #expect(state.request.requestedAt == callerTime)
        #expect(state.request.sale == sale)
    }

    @Test(arguments: [Double.infinity, -.infinity, .nan])
    func `nonfinite request timestamps cannot enter through construction or decoding`(_ interval: Double) throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let requestedAt = Date(timeIntervalSince1970: interval)

        #expect(throws: BillingDocumentError.invalidTimestamp) {
            try billingRequest(sale: sale, kind: .ticket, requestedAt: requestedAt)
        }
        let payload = requestPayload(sale: sale, kind: .ticket, requestedAt: requestedAt)
        #expect(throws: BillingDocumentError.invalidTimestamp) {
            try decodeBillingRequest(payload)
        }
    }
}

private struct BillingRequestPayload: Encodable {
    let id: BillingDocumentRequestID
    let documentID: BillingDocumentID
    let sale: Sale
    let kind: BillingDocumentKind
    let requestedAt: Date
}

private func billingRequest(
    sale: Sale,
    kind: BillingDocumentKind,
    requestedAt: Date = Date(timeIntervalSince1970: 201)
) throws -> BillingDocumentRequest {
    try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(701)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(702)),
        sale: sale,
        kind: kind,
        requestedAt: requestedAt
    )
}

private func requestPayload(
    sale: Sale,
    kind: BillingDocumentKind,
    requestedAt: Date = Date(timeIntervalSince1970: 201)
) -> BillingRequestPayload {
    BillingRequestPayload(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(701)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(702)),
        sale: sale,
        kind: kind,
        requestedAt: requestedAt
    )
}

private func decodeBillingRequest(_ payload: BillingRequestPayload) throws -> BillingDocumentRequest {
    let encoder = JSONEncoder()
    encoder.nonConformingFloatEncodingStrategy = .convertToString(
        positiveInfinity: "Infinity",
        negativeInfinity: "-Infinity",
        nan: "NaN"
    )
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
        positiveInfinity: "Infinity",
        negativeInfinity: "-Infinity",
        nan: "NaN"
    )
    return try decoder.decode(BillingDocumentRequest.self, from: encoder.encode(payload))
}
