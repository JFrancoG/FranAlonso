import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing document")
struct BillingDocumentTests {
    @Test("Uses independent ticket and invoice series")
    func usesIndependentTicketAndInvoiceSeries() throws {
        let ticketNumber = try BillingDocumentNumber(series: .ticket, value: 1)
        let invoiceNumber = try BillingDocumentNumber(series: .invoice, value: 1)

        #expect(BillingDocumentKind.ticket.series == .ticket)
        #expect(BillingDocumentKind.invoice.series == .invoice)
        #expect(ticketNumber != invoiceNumber)
        #expect(ticketNumber.value == invoiceNumber.value)
    }

    @Test("Creates a pending document without a definitive number")
    func createsAPendingDocumentWithoutADefinitiveNumber() {
        let requestID = billingRequestID("10000000-0000-0000-0000-000000000001")
        let document = BillingDocument.pendingNumber(
            id: billingDocumentID("10000000-0000-0000-0000-000000000002"),
            saleID: billingSaleID("10000000-0000-0000-0000-000000000003"),
            kind: .ticket,
            requestID: requestID
        )

        #expect(document.kind == .ticket)
        #expect(document.status == .pendingNumber(requestID: requestID))
        #expect(document.status.requestID == requestID)
        #expect(document.status.number == nil)
        #expect(document.status.issuedAt == nil)
        requireBillingSendable(document)
    }

    @Test("Materializes numbered tickets and invoices in their own series")
    func materializesNumberedDocumentsInTheirOwnSeries() throws {
        let issuedAt = billingDate(1)
        let cases: [(BillingDocumentKind, BillingDocumentSeries)] = [
            (.ticket, .ticket),
            (.invoice, .invoice)
        ]

        for (offset, testCase) in cases.enumerated() {
            let requestID = BillingDocumentRequestID(rawValue: billingUUID(offset: offset + 10))
            let number = try BillingDocumentNumber(
                series: testCase.1,
                value: 1
            )
            let document = try BillingDocument.numbered(
                id: BillingDocumentID(rawValue: billingUUID(offset: offset + 20)),
                saleID: SaleID(rawValue: billingUUID(offset: offset + 30)),
                kind: testCase.0,
                requestID: requestID,
                number: number,
                issuedAt: issuedAt
            )

            #expect(document.kind == testCase.0)
            #expect(document.status.requestID == requestID)
            #expect(document.status.number == number)
            #expect(document.status.issuedAt == issuedAt)
        }
    }

    @Test("Rejects a number from another document series")
    func rejectsANumberFromAnotherDocumentSeries() throws {
        let invoiceNumber = try BillingDocumentNumber(series: .invoice, value: 1)

        #expect(
            throws: BillingDocumentError.incompatibleSeries(
                expected: .ticket,
                actual: .invoice
            )
        ) {
            try BillingDocument.numbered(
                id: billingDocumentID("20000000-0000-0000-0000-000000000001"),
                saleID: billingSaleID("20000000-0000-0000-0000-000000000002"),
                kind: .ticket,
                requestID: billingRequestID("20000000-0000-0000-0000-000000000003"),
                number: invoiceNumber,
                issuedAt: billingDate(1)
            )
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
        let requestID = billingRequestID("30000000-0000-0000-0000-000000000001")
        let pending = BillingDocument.pendingNumber(
            id: billingDocumentID("30000000-0000-0000-0000-000000000002"),
            saleID: billingSaleID("30000000-0000-0000-0000-000000000003"),
            kind: .invoice,
            requestID: requestID
        )
        let numbered = try BillingDocument.numbered(
            id: pending.id,
            saleID: pending.saleID,
            kind: pending.kind,
            requestID: requestID,
            number: BillingDocumentNumber(series: .invoice, value: 42),
            issuedAt: billingDate(2)
        )

        #expect(try billingRoundTrip(pending) == pending)
        #expect(try billingRoundTrip(numbered) == numbered)
    }

    @Test("Decoding cannot bypass positive sequence validation")
    func decodingCannotBypassPositiveSequenceValidation() throws {
        let payload = BillingDocumentNumberPayload(series: .ticket, value: 0)

        #expect(throws: BillingDocumentNumberError.nonPositiveValue) {
            try JSONDecoder().decode(
                BillingDocumentNumber.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test("Decoding cannot pair a document with another series")
    func decodingCannotPairADocumentWithAnotherSeries() throws {
        let payload = BillingDocumentPayload(
            id: billingDocumentID("40000000-0000-0000-0000-000000000001"),
            saleID: billingSaleID("40000000-0000-0000-0000-000000000002"),
            kind: .ticket,
            status: .numbered(
                requestID: billingRequestID("40000000-0000-0000-0000-000000000003"),
                number: try BillingDocumentNumber(series: .invoice, value: 1),
                issuedAt: billingDate(3)
            )
        )

        #expect(
            throws: BillingDocumentError.incompatibleSeries(
                expected: .ticket,
                actual: .invoice
            )
        ) {
            try JSONDecoder().decode(
                BillingDocument.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }
}

private struct BillingDocumentNumberPayload: Codable {
    let series: BillingDocumentSeries
    let value: Int
}

private struct BillingDocumentPayload: Codable {
    let id: BillingDocumentID
    let saleID: SaleID
    let kind: BillingDocumentKind
    let status: BillingDocumentStatus
}

private func billingRoundTrip(_ document: BillingDocument) throws -> BillingDocument {
    try JSONDecoder().decode(
        BillingDocument.self,
        from: JSONEncoder().encode(document)
    )
}

private func billingDocumentID(_ value: String) -> BillingDocumentID {
    BillingDocumentID(rawValue: UUID(uuidString: value)!)
}

private func billingRequestID(_ value: String) -> BillingDocumentRequestID {
    BillingDocumentRequestID(rawValue: UUID(uuidString: value)!)
}

private func billingSaleID(_ value: String) -> SaleID {
    SaleID(rawValue: UUID(uuidString: value)!)
}

private func billingUUID(offset: Int) -> UUID {
    UUID(uuidString: String(format: "50000000-0000-0000-0000-%012d", offset))!
}

private func billingDate(_ offset: TimeInterval) -> Date {
    Date(timeIntervalSince1970: 1_800_000_000 + offset)
}

private func requireBillingSendable<Value: Sendable>(_ value: Value) {}
