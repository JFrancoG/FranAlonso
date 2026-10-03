import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing document")
struct BillingDocumentTests {
    @Test("Uses independent ticket and invoice series")
    func usesIndependentTicketAndInvoiceSeries() throws {
        let ticket = try billingNumberedDocument(kind: .ticket)
        let invoice = try billingNumberedDocument(kind: .invoice)

        #expect(ticket.number != invoice.number)
        #expect(ticket.number.value == invoice.number.value)
        #expect(ticket.number.series == .ticket)
        #expect(invoice.number.series == .invoice)
    }

    @Test("Creates a pending document without a definitive number")
    func createsAPendingDocumentWithoutADefinitiveNumber() throws {
        let request = try billingPaidRequest()
        var state = BillingDocumentLocalState.pendingNumber(request)

        try state.retryNumbering()

        #expect(state == .pendingNumber(request))
        #expect(state.document == nil)
        #expect(state.document?.number == nil)
    }

    @Test("Materializes numbered tickets and invoices in their own series")
    func materializesNumberedDocumentsInTheirOwnSeries() throws {
        let cases: [(BillingDocumentKind, BillingDocumentSeries)] = [(.ticket, .ticket), (.invoice, .invoice)]

        for testCase in cases {
            let document = try billingNumberedDocument(kind: testCase.0)
            var state = BillingDocumentLocalState.pendingNumber(document.request)

            try state.accept(document)

            let accepted = try #require(state.document)
            #expect(accepted.number.series == testCase.1)
            #expect(accepted.issuedAt == billingDate(202))
            #expect(accepted.id == document.request.documentID)
            #expect(accepted.saleID == document.request.saleID)
            #expect(state.request == document.request)
        }
    }

    @Test("Rejects a number from another document series")
    func rejectsANumberFromAnotherDocumentSeries() throws {
        let request = try billingPaidRequest(kind: .ticket)
        let invoiceNumber = try BillingDocumentNumber(series: .invoice, value: 1)

        #expect(throws: BillingDocumentError.incompatibleSeries(expected: .ticket, actual: .invoice)) {
            try BillingDocument.numbered(request: request, number: invoiceNumber, issuedAt: billingDate(202))
        }
    }

    @Test("Requires a positive sequence value", arguments: [0, -1])
    func requiresAPositiveSequenceValue(_ value: Int) {
        #expect(throws: BillingDocumentNumberError.nonPositiveValue) {
            try BillingDocumentNumber(series: .ticket, value: value)
        }
    }

    @Test("Preserves pending and numbered states through Codable")
    func preservesStatesThroughCodable() throws {
        let document = try billingNumberedDocument(kind: .invoice, value: 42)
        let states: [BillingDocumentLocalState] = [
            .pendingNumber(document.request),
            .failed(document.request, reason: .unavailable),
            .numbered(document)
        ]

        for original in states {
            var recovered = try billingRoundTrip(original)
            #expect(recovered == original)

            try recovered.accept(document)
            try recovered.accept(document)

            #expect(recovered == .numbered(document))
            #expect(recovered.document?.number.value == 42)
        }
    }

    @Test("Decoding cannot bypass positive sequence validation")
    func decodingCannotBypassPositiveSequenceValidation() throws {
        let payload = BillingDocumentNumberPayload(series: .ticket, value: 0)

        #expect(throws: BillingDocumentNumberError.nonPositiveValue) {
            try JSONDecoder().decode(BillingDocumentNumber.self, from: JSONEncoder().encode(payload))
        }
    }

    @Test("Decoding cannot pair a document with another series")
    func decodingCannotPairADocumentWithAnotherSeries() throws {
        let payload = BillingDocumentPayload(
            request: try billingPaidRequest(kind: .ticket),
            number: try BillingDocumentNumber(series: .invoice, value: 1),
            issuedAt: billingDate(202)
        )

        #expect(throws: BillingDocumentError.incompatibleSeries(expected: .ticket, actual: .invoice)) {
            try billingDecodeDocument(payload)
        }
    }

    @Test
    func `legacy records without a paid request cannot restore a confirmed document`() throws {
        let request = try billingPaidRequest()
        let states: [LegacyBillingDocumentStatus] = [
            .pendingNumber(requestID: request.id),
            .numbered(
                requestID: request.id,
                number: try BillingDocumentNumber(series: .ticket, value: 1),
                issuedAt: billingDate(202)
            )
        ]

        for status in states {
            let payload = LegacyBillingDocumentPayload(
                id: request.documentID,
                saleID: request.saleID,
                kind: .ticket,
                status: status
            )

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(BillingDocument.self, from: JSONEncoder().encode(payload))
            }
        }
    }

    @Test(arguments: [BillingDocumentFailure.unavailable, .permissionDenied, .conflict])
    func `a failed attempt has no number and retry retains its complete request`(
        _ reason: BillingDocumentFailure
    ) throws {
        let request = try billingPaidRequest(kind: .invoice)
        var state = BillingDocumentLocalState.pendingNumber(request)

        try state.failNumbering(reason: reason)
        try state.failNumbering(reason: reason)

        #expect(state == .failed(request, reason: reason))
        #expect(state.document == nil)
        #expect(state.document?.number == nil)

        state = try billingRoundTrip(state)
        try state.retryNumbering()
        try state.retryNumbering()

        #expect(state == .pendingNumber(request))
        #expect(state.request.id == request.id)
        #expect(state.request.documentID == request.documentID)
        #expect(state.request.sale == request.sale)
        #expect(state.document == nil)
    }

    @Test
    func `remote confirmation recovers a failed attempt and its identical replay is harmless`() throws {
        let document = try billingNumberedDocument(value: 7)
        var state = BillingDocumentLocalState.pendingNumber(document.request)
        try state.failNumbering(reason: .unavailable)

        try state.accept(document)
        try state.accept(document)

        #expect(state == .numbered(document))
        #expect(state.document?.request.sale == document.request.sale)
        #expect(state.document?.number.value == 7)
    }

    @Test(arguments: [false, true])
    func `confirmation rejects any changed request and preserves pending or failed state`(_ failed: Bool) throws {
        let request = try billingPaidRequest()
        let changedRequests = try billingConflictingRequests()

        for changedRequest in changedRequests {
            let document = try BillingDocument.numbered(
                request: changedRequest,
                number: BillingDocumentNumber(series: changedRequest.kind.series, value: 7),
                issuedAt: billingDate(203)
            )
            var state = BillingDocumentLocalState.pendingNumber(request)
            if failed {
                try state.failNumbering(reason: .unavailable)
            }
            let retained = state

            #expect(throws: BillingDocumentError.conflictingRequest) {
                try state.accept(document)
            }

            #expect(state == retained)
            #expect(state.document == nil)
        }
    }

    @Test
    func `a numbered result rejects changed number or timestamp without replacing its confirmation`() throws {
        let document = try billingNumberedDocument(value: 7)
        let changedNumber = try billingNumberedDocument(value: 8)
        let changedTimestamp = try billingNumberedDocument(value: 7, issuedAt: billingDate(203))
        var state = BillingDocumentLocalState.pendingNumber(document.request)
        try state.accept(document)

        for conflict in [changedNumber, changedTimestamp] {
            #expect(throws: BillingDocumentError.conflictingDocument) {
                try state.accept(conflict)
            }
            #expect(state == .numbered(document))
        }
    }

    @Test
    func `a numbered document cannot return to failed or pending`() throws {
        let document = try billingNumberedDocument(value: 7)
        var state = BillingDocumentLocalState.pendingNumber(document.request)
        try state.accept(document)

        #expect(throws: BillingDocumentError.invalidLocalTransition) {
            try state.failNumbering(reason: .unavailable)
        }
        #expect(throws: BillingDocumentError.invalidLocalTransition) {
            try state.retryNumbering()
        }

        #expect(state == .numbered(document))
    }

    @Test
    func `a recovered allocation tolerates an authority clock behind the recorded payment`() throws {
        let request = try billingPaidRequest()
        let number = try BillingDocumentNumber(series: .ticket, value: 1)
        let authorityTime = billingDate(199)
        let document = try BillingDocument.numbered(request: request, number: number, issuedAt: authorityTime)
        let payload = BillingDocumentPayload(request: request, number: number, issuedAt: authorityTime)
        let recovered = try billingDecodeDocument(payload)
        var state = BillingDocumentLocalState.pendingNumber(request)
        try state.failNumbering(reason: .unavailable)
        try state.accept(recovered)
        try state.accept(document)

        #expect(state == .numbered(document))
        #expect(state.document?.issuedAt == authorityTime)
        #expect(state.document?.request == request)
    }

    @Test(arguments: [Double.infinity, -.infinity, .nan])
    func `numbering rejects a nonfinite timestamp in factories and decoded records`(_ interval: Double) throws {
        let request = try billingPaidRequest()
        let number = try BillingDocumentNumber(series: .ticket, value: 1)
        let issuedAt = billingDate(interval)

        #expect(throws: BillingDocumentError.invalidTimestamp) {
            try BillingDocument.numbered(request: request, number: number, issuedAt: issuedAt)
        }
        let payload = BillingDocumentPayload(request: request, number: number, issuedAt: issuedAt)
        #expect(throws: BillingDocumentError.invalidTimestamp) {
            try billingDecodeDocument(payload)
        }
    }
}

private struct BillingDocumentNumberPayload: Encodable {
    let series: BillingDocumentSeries
    let value: Int
}

private struct BillingDocumentPayload: Encodable {
    let request: BillingDocumentRequest
    let number: BillingDocumentNumber
    let issuedAt: Date
}

private struct LegacyBillingDocumentPayload: Encodable {
    let id: BillingDocumentID
    let saleID: SaleID
    let kind: BillingDocumentKind
    let status: LegacyBillingDocumentStatus
}

private enum LegacyBillingDocumentStatus: Encodable {
    case pendingNumber(requestID: BillingDocumentRequestID)
    case numbered(requestID: BillingDocumentRequestID, number: BillingDocumentNumber, issuedAt: Date)
}

private func billingRoundTrip(_ state: BillingDocumentLocalState) throws -> BillingDocumentLocalState {
    try JSONDecoder().decode(BillingDocumentLocalState.self, from: JSONEncoder().encode(state))
}

private func billingDecodeDocument(_ payload: BillingDocumentPayload) throws -> BillingDocument {
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
    return try decoder.decode(BillingDocument.self, from: encoder.encode(payload))
}

private func billingNumberedDocument(
    kind: BillingDocumentKind = .ticket,
    value: Int = 1,
    issuedAt: Date = Date(timeIntervalSince1970: 202)
) throws -> BillingDocument {
    try BillingDocument.numbered(
        request: billingPaidRequest(kind: kind),
        number: BillingDocumentNumber(series: kind.series, value: value),
        issuedAt: issuedAt
    )
}

private func billingPaidRequest(kind: BillingDocumentKind = .ticket) throws -> BillingDocumentRequest {
    try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(701)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(702)),
        sale: viewModelSale(stage: .awaitingDocument),
        kind: kind,
        requestedAt: billingDate(201)
    )
}

private func billingConflictingRequests() throws -> [BillingDocumentRequest] {
    let sale = try viewModelSale(stage: .awaitingDocument)
    let changedSale = try viewModelSale(index: 2, stage: .awaitingDocument)
    let changedSnapshot = try viewModelSale(stage: .awaitingDocument, clientID: ClientID(rawValue: viewModelUUID(601)))
    let changedTerms = try billingSaleWithChangedTerms()
    let variants: [(Int, Int, Sale, BillingDocumentKind, TimeInterval)] = [
        (703, 702, sale, .ticket, 201),
        (701, 704, sale, .ticket, 201),
        (701, 702, changedSale, .ticket, 201),
        (701, 702, sale, .invoice, 201),
        (701, 702, changedSnapshot, .ticket, 201),
        (701, 702, changedTerms, .ticket, 201),
        (701, 702, sale, .ticket, 202)
    ]
    return try variants.map { variant in
        try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: viewModelUUID(variant.0)),
            documentID: BillingDocumentID(rawValue: viewModelUUID(variant.1)),
            sale: variant.2,
            kind: variant.3,
            requestedAt: billingDate(variant.4)
        )
    }
}

private func billingSaleWithChangedTerms() throws -> Sale {
    let line = try viewModelLine(quantity: 2)
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(1)),
        clientID: nil,
        createdAt: billingDate(100),
        lines: [line]
    )
    try sale.start()
    try sale.startLine(id: line.id)
    try sale.completeLine(id: line.id)
    try sale.registerPayment(id: PaymentID(rawValue: viewModelUUID(800)), method: .cash, paidAt: billingDate(200))
    return sale
}

private func billingDate(_ interval: TimeInterval) -> Date {
    Date(timeIntervalSince1970: interval)
}
