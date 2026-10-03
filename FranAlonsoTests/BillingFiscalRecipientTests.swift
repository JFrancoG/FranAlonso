import Foundation
import Synchronization
import Testing
@testable import FranAlonso

@Suite("Billing fiscal recipient and local preparation")
struct BillingFiscalRecipientTests {
    @Test(arguments: [
        BillingFiscalField.displayName, .taxIdentifier, .streetLine, .postalCode, .city, .province
    ])
    func `each whitespace-only invoice field is rejected before generating identities`(
        _ field: BillingFiscalField
    ) throws {
        var input = billingFiscalInput()
        input[field] = " \n\t "
        let identityCalls = FiscalIdentityCalls()
        let prepare = countedFiscalPreparation(identityCalls)
        let sale = try viewModelSale(stage: .awaitingDocument)

        #expect(throws: BillingFiscalRecipientError.required(field)) {
            try prepare(sale: sale, kind: .invoice, recipientInput: input)
        }

        #expect(identityCalls.value == 0)
    }

    @Test
    func `preparing an invoice trims edges preserves Unicode internal spaces and permits manual recipients`() throws {
        var input = billingFiscalInput()
        for field in BillingFiscalField.allCases {
            input[field] = " \t" + input[field] + "\n "
        }
        let sale = try viewModelSale(stage: .awaitingDocument)
        let request = try fiscalPreparation()(sale: sale, kind: .invoice, recipientInput: input)
        let recipient = try #require(request.fiscalRecipient)

        #expect(recipient.displayName == "Ana  Núñez")
        #expect(recipient.taxIdentifier == "doc-ID/Ñ")
        #expect(recipient.billingAddress == BillingAddress(
            streetLine: "Calle  Sol 12",
            postalCode: "SW1A 1AA",
            city: "Madrid",
            province: "Comunidad de Madrid"
        ))
        #expect(request.sale == sale)
        #expect(request.id == BillingDocumentRequestID(rawValue: viewModelUUID(1701)))
        #expect(request.documentID == BillingDocumentID(rawValue: viewModelUUID(1801)))
        #expect(request.requestedAt == Date(timeIntervalSinceReferenceDate: 1))
    }

    @Test
    func `missing invoice input reports the first required field without generating identities`() throws {
        let identityCalls = FiscalIdentityCalls()
        let prepare = countedFiscalPreparation(identityCalls)
        let sale = try viewModelSale(stage: .awaitingDocument)

        #expect(throws: BillingFiscalRecipientError.required(.displayName)) {
            try prepare(sale: sale, kind: .invoice)
        }

        #expect(identityCalls.value == 0)
    }

    @Test(arguments: [
        ViewModelSaleStage.draft, .inProgress, .awaitingPayment, .closed, .voided
    ])
    func `unpaid and terminal sales cannot prepare even with complete recipient input`(
        _ stage: ViewModelSaleStage
    ) throws {
        let identityCalls = FiscalIdentityCalls()
        let prepare = countedFiscalPreparation(identityCalls)
        let expected: BillingDocumentError = stage == .closed || stage == .voided ? .terminalSale : .requiresPayment
        let sale = try viewModelSale(stage: stage)

        #expect(throws: expected) {
            try prepare(sale: sale, kind: .invoice, recipientInput: billingFiscalInput())
        }

        #expect(identityCalls.value == 0)
    }

    @Test
    func `nonfinite preparation time cannot consume identities`() throws {
        let identityCalls = FiscalIdentityCalls()
        let prepare = countedFiscalPreparation(identityCalls, now: Date(timeIntervalSinceReferenceDate: .infinity))
        let sale = try viewModelSale(stage: .awaitingDocument)

        #expect(throws: BillingDocumentError.invalidTimestamp) {
            try prepare(sale: sale, kind: .invoice, recipientInput: billingFiscalInput())
        }

        #expect(identityCalls.value == 0)
    }

    @Test
    func `a ticket ignores unused fiscal input and keeps the paid sale pending`() throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let request = try fiscalPreparation()(sale: sale, kind: .ticket, recipientInput: billingFiscalInput())

        #expect(request.fiscalRecipient == nil)
        #expect(request.sale == sale)
        #expect(request.kind == .ticket)
        #expect(request.sale.status == .awaitingDocument(
            paymentID: PaymentID(rawValue: viewModelUUID(800)),
            method: .cash,
            paidAt: Date(timeIntervalSince1970: 200)
        ))
    }

    @Test
    func `ticket construction and restoration reject a recipient rather than retaining its private data`() throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let recipient = try BillingFiscalRecipient(billingFiscalInput())

        #expect(throws: BillingFiscalRecipientError.unexpectedRecipient) {
            try BillingDocumentRequest(
                id: BillingDocumentRequestID(rawValue: viewModelUUID(1701)),
                documentID: BillingDocumentID(rawValue: viewModelUUID(1801)),
                sale: sale,
                kind: .ticket,
                requestedAt: Date(timeIntervalSinceReferenceDate: 1),
                fiscalRecipient: recipient
            )
        }

        let payload = FiscalDomainRequestPayload(
            id: BillingDocumentRequestID(rawValue: viewModelUUID(1701)),
            documentID: BillingDocumentID(rawValue: viewModelUUID(1801)),
            sale: sale,
            kind: .ticket,
            requestedAt: Date(timeIntervalSinceReferenceDate: 1),
            fiscalRecipient: recipient
        )
        #expect(throws: BillingFiscalRecipientError.unexpectedRecipient) {
            try JSONDecoder().decode(BillingDocumentRequest.self, from: JSONEncoder().encode(payload))
        }
    }

    @Test
    func `restoring a recipient revalidates application completeness`() throws {
        let bytes = Data("""
        {"displayName":"Ana Núñez","taxIdentifier":"manual-id",
        "billingAddress":{"streetLine":"Calle Sol 12","postalCode":"SW1A 1AA","city":" ","province":"Madrid"}}
        """.utf8)

        #expect(throws: BillingFiscalRecipientError.required(.city)) {
            try JSONDecoder().decode(BillingFiscalRecipient.self, from: bytes)
        }
    }
}

func billingFiscalInput() -> BillingFiscalRecipientInput {
    BillingFiscalRecipientInput(
        displayName: "Ana  Núñez",
        taxIdentifier: "doc-ID/Ñ",
        streetLine: "Calle  Sol 12",
        postalCode: "SW1A 1AA",
        city: "Madrid",
        province: "Comunidad de Madrid"
    )
}

func fiscalPreparation() -> PrepareBillingDocumentRequestUseCase {
    PrepareBillingDocumentRequestUseCase(
        makeRequestID: { BillingDocumentRequestID(rawValue: viewModelUUID(1701)) },
        makeDocumentID: { BillingDocumentID(rawValue: viewModelUUID(1801)) },
        now: { Date(timeIntervalSinceReferenceDate: 1) }
    )
}

private func countedFiscalPreparation(
    _ calls: FiscalIdentityCalls,
    now: Date = Date(timeIntervalSinceReferenceDate: 1)
) -> PrepareBillingDocumentRequestUseCase {
    PrepareBillingDocumentRequestUseCase(
        makeRequestID: {
            calls.increment()
            return BillingDocumentRequestID(rawValue: viewModelUUID(1701))
        },
        makeDocumentID: {
            calls.increment()
            return BillingDocumentID(rawValue: viewModelUUID(1801))
        },
        now: { now }
    )
}

private struct FiscalDomainRequestPayload: Encodable {
    let id: BillingDocumentRequestID
    let documentID: BillingDocumentID
    let sale: Sale
    let kind: BillingDocumentKind
    let requestedAt: Date
    let fiscalRecipient: BillingFiscalRecipient
}

private final class FiscalIdentityCalls: Sendable {
    private let count = Mutex(0)

    var value: Int { count.withLock { $0 } }

    func increment() {
        count.withLock {
            $0 += 1
        }
    }
}
