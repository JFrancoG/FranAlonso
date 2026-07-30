import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale DTO conversion")
struct SaleDTOConversionTests {
    @Test(
        "Every lifecycle state round trips through the explicit v1 payload",
        arguments: saleDTOAllStates
    )
    func everyLifecycleStateRoundTrips(_ sale: Sale) throws {
        let dto = try SaleDTO(sale)

        #expect(dto.payloadVersion == 1)
        #expect(try dto.toDomain() == sale)

        let encoded = try JSONEncoder().encode(dto)
        let decoded = try JSONDecoder().decode(SaleDTO.self, from: encoded)
        #expect(decoded == dto)
        #expect(try decoded.toDomain() == sale)
    }

    @Test("The voided status uses exact nested payment document and reversal payloads")
    func voidedStatusUsesExactNestedPayloads() throws {
        let dto = try SaleDTO(saleDTOVoided())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let payload = String(decoding: try encoder.encode(dto.status), as: UTF8.self)

        #expect(
            payload
                == #"{"document":{"closedAt":"c10fa40000000000","id":"00000000-0000-0000-0000-000000000604"},"kind":"voided","payment":{"id":"00000000-0000-0000-0000-000000000603","method":"card","paidAt":"c10a5e0000000000"},"reversal":{"id":"00000000-0000-0000-0000-000000000605","voidedAt":"c112750000000000"}}"#
        )
    }

    @Test(
        "Invalid status shapes fail closed",
        arguments: [
            #"{"kind":"draft","payment":{"id":"00000000-0000-0000-0000-000000000001","method":"cash","paidAt":"0000000000000000"}}"#,
            #"{"kind":"awaitingDocument"}"#,
            #"{"kind":"closed","payment":{"id":"00000000-0000-0000-0000-000000000001","method":"cash","paidAt":"0000000000000000"}}"#,
            #"{"kind":"future"}"#,
            #"{"kind":"draft","unexpected":true}"#,
            #"{"kind":"awaitingDocument","payment":{"id":"00000000-0000-0000-0000-000000000001","method":"cash","paidAt":"0000000000000000","unexpected":true}}"#
        ]
    )
    func invalidStatusShapesFailClosed(_ payload: String) {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                SaleStatusDTO.self,
                from: Data(payload.utf8)
            )
        }
    }

    @Test("Additional line snapshot keys fail closed")
    func additionalLineSnapshotKeysFailClosed() {
        let payload = #"{"id":"00000000-0000-0000-0000-000000000010","serviceID":"00000000-0000-0000-0000-000000000011","serviceName":"Snapshot","quantity":1,"unitPrice":{"amount":"29.95","currency":"EUR"},"taxRate":{"percentage":"21"},"status":"upcoming","unexpected":true}"#

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                SaleLineDTO.self,
                from: Data(payload.utf8)
            )
        }
    }

    @Test("Unsupported payload versions fail before Domain reconstruction")
    func unsupportedPayloadVersionsFail() throws {
        let valid = try SaleDTO(saleDTODraft())
        let unsupported = SaleDTO(
            payloadVersion: 2,
            id: valid.id,
            clientID: valid.clientID,
            createdAt: valid.createdAt,
            lines: valid.lines,
            status: valid.status
        )

        #expect(throws: SaleMappingError.unsupportedPayloadVersion(2)) {
            _ = try unsupported.toDomain()
        }
    }

    @Test("Invalid identifiers and incoherent line progress fail closed")
    func invalidIdentifiersAndLifecycleFailClosed() throws {
        let valid = try SaleDTO(saleDTODraft())
        let invalidID = SaleDTO(
            payloadVersion: 1,
            id: "not-a-uuid",
            clientID: valid.clientID,
            createdAt: valid.createdAt,
            lines: valid.lines,
            status: valid.status
        )
        let progressedDraft = SaleDTO(
            payloadVersion: 1,
            id: valid.id,
            clientID: valid.clientID,
            createdAt: valid.createdAt,
            lines: valid.lines.map {
                SaleLineDTO(
                    id: $0.id,
                    serviceID: $0.serviceID,
                    serviceName: $0.serviceName,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice,
                    taxRate: $0.taxRate,
                    discount: $0.discount,
                    linkedProductID: $0.linkedProductID,
                    status: .completed
                )
            },
            status: .draft
        )

        #expect(
            throws: SaleMappingError.invalidIdentifier(
                "not-a-uuid",
                location: .sale
            )
        ) {
            _ = try invalidID.toDomain()
        }
        #expect(throws: SaleMappingError.invalidLifecycle) {
            _ = try progressedDraft.toDomain()
        }
    }

    @Test("Invalid identifiers retain their exact aggregate location")
    func invalidIdentifiersRetainExactLocation() throws {
        let invalid = "not-a-uuid"
        let draft = try SaleDTO(saleDTODraft())
        let invalidSale = SaleDTO(
            payloadVersion: draft.payloadVersion,
            id: invalid,
            clientID: draft.clientID,
            createdAt: draft.createdAt,
            lines: draft.lines,
            status: draft.status
        )
        let invalidClient = SaleDTO(
            payloadVersion: draft.payloadVersion,
            id: draft.id,
            clientID: invalid,
            createdAt: draft.createdAt,
            lines: draft.lines,
            status: draft.status
        )
        let invalidLine = replacingSaleLineIdentifier(
            in: draft,
            at: 1,
            id: invalid
        )
        let invalidService = replacingSaleLineIdentifier(
            in: draft,
            at: 0,
            serviceID: invalid
        )
        let invalidLinkedProduct = replacingSaleLineIdentifier(
            in: draft,
            at: 1,
            linkedProductID: invalid
        )

        let awaitingDocument = try SaleDTO(saleDTOAwaitingDocument())
        guard case .awaitingDocument(let payment) = awaitingDocument.status else {
            Issue.record("Expected awaiting-document fixture")
            return
        }
        let invalidPayment = replacingSaleStatus(
            in: awaitingDocument,
            with: .awaitingDocument(
                payment: SalePaymentDTO(
                    id: invalid,
                    method: payment.method,
                    paidAt: payment.paidAt
                )
            )
        )

        let closed = try SaleDTO(saleDTOClosed())
        guard case .closed(let closedPayment, let document) = closed.status else {
            Issue.record("Expected closed fixture")
            return
        }
        let invalidDocument = replacingSaleStatus(
            in: closed,
            with: .closed(
                payment: closedPayment,
                document: SaleDocumentDTO(
                    id: invalid,
                    closedAt: document.closedAt
                )
            )
        )

        let voided = try SaleDTO(saleDTOVoided())
        guard case .voided(let voidedPayment, let voidedDocument, let reversal)
                = voided.status else {
            Issue.record("Expected voided fixture")
            return
        }
        let invalidReversal = replacingSaleStatus(
            in: voided,
            with: .voided(
                payment: voidedPayment,
                document: voidedDocument,
                reversal: SaleReversalDTO(
                    id: invalid,
                    voidedAt: reversal.voidedAt
                )
            )
        )

        let cases: [(SaleDTO, SaleIdentifierLocation)] = [
            (invalidSale, .sale),
            (invalidClient, .client),
            (invalidLine, .line(index: 1)),
            (invalidService, .service(lineIndex: 0)),
            (invalidLinkedProduct, .linkedProduct(lineIndex: 1)),
            (invalidPayment, .payment),
            (invalidDocument, .document),
            (invalidReversal, .reversal)
        ]
        for (dto, location) in cases {
            #expect(
                throws: SaleMappingError.invalidIdentifier(
                    invalid,
                    location: location
                )
            ) {
                _ = try dto.toDomain()
            }
        }
    }
}

private let saleDTOAllStates: [Sale] = {
    do {
        return [
            try saleDTODraft(),
            try saleDTOInProgress(),
            try saleDTOAwaitingPayment(),
            try saleDTOAwaitingDocument(),
            try saleDTOClosed(),
            try saleDTOVoided()
        ]
    } catch {
        preconditionFailure("Invalid Sale DTO fixtures: \(error)")
    }
}()

private func saleDTODraft() throws -> Sale {
    try saleDTOBaseSale()
}

private func saleDTOInProgress() throws -> Sale {
    var sale = try saleDTOBaseSale()
    try sale.start()
    try sale.startLine(id: sale.lines[0].id)
    return sale
}

private func saleDTOAwaitingPayment() throws -> Sale {
    var sale = try saleDTOInProgress()
    try sale.completeLine(id: sale.lines[0].id)
    try sale.startLine(id: sale.lines[1].id)
    try sale.completeLine(id: sale.lines[1].id)
    return sale
}

private func saleDTOAwaitingDocument() throws -> Sale {
    var sale = try saleDTOAwaitingPayment()
    try sale.registerPayment(
        id: PaymentID(rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000603")),
        method: .card,
        paidAt: Date(timeIntervalSinceReferenceDate: -216_000)
    )
    return sale
}

private func saleDTOClosed() throws -> Sale {
    var sale = try saleDTOAwaitingDocument()
    try sale.close(
        documentID: BillingDocumentID(
            rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000604")
        ),
        closedAt: Date(timeIntervalSinceReferenceDate: -259_200)
    )
    return sale
}

private func saleDTOVoided() throws -> Sale {
    var sale = try saleDTOClosed()
    try sale.void(
        reversalID: SaleReversalID(
            rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000605")
        ),
        voidedAt: Date(timeIntervalSinceReferenceDate: -302_400)
    )
    return sale
}

private func saleDTOBaseSale() throws -> Sale {
    try Sale.draft(
        id: SaleID(rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000600")),
        clientID: ClientID(
            rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000601")
        ),
        createdAt: Date(timeIntervalSinceReferenceDate: 0.000_000_123_456_789),
        lines: [
            try saleDTOLine(
                id: "00000000-0000-0000-0000-000000000610",
                quantity: 1,
                linkedProductID: nil
            ),
            try saleDTOLine(
                id: "00000000-0000-0000-0000-000000000611",
                quantity: 2,
                linkedProductID: ProductID(
                    rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000612")
                )
            )
        ]
    )
}

private func saleDTOLine(
    id: String,
    quantity: Int,
    linkedProductID: ProductID?
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: saleDTOUUID(id)),
        serviceID: ServiceID(
            rawValue: saleDTOUUID("00000000-0000-0000-0000-000000000602")
        ),
        serviceName: "Corte histórico",
        quantity: quantity,
        unitPrice: Money(amount: saleDTODecimal("29.95"), currency: .eur),
        taxRate: TaxRate(percentage: saleDTODecimal("21")),
        discount: Discount(percentage: saleDTODecimal("10")),
        linkedProductID: linkedProductID
    )
}

private func replacingSaleLineIdentifier(
    in dto: SaleDTO,
    at index: Int,
    id: String? = nil,
    serviceID: String? = nil,
    linkedProductID: String? = nil
) -> SaleDTO {
    var lines = dto.lines
    let line = lines[index]
    lines[index] = SaleLineDTO(
        id: id ?? line.id,
        serviceID: serviceID ?? line.serviceID,
        serviceName: line.serviceName,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        taxRate: line.taxRate,
        discount: line.discount,
        linkedProductID: linkedProductID ?? line.linkedProductID,
        status: line.status
    )
    return SaleDTO(
        payloadVersion: dto.payloadVersion,
        id: dto.id,
        clientID: dto.clientID,
        createdAt: dto.createdAt,
        lines: lines,
        status: dto.status
    )
}

private func replacingSaleStatus(
    in dto: SaleDTO,
    with status: SaleStatusDTO
) -> SaleDTO {
    SaleDTO(
        payloadVersion: dto.payloadVersion,
        id: dto.id,
        clientID: dto.clientID,
        createdAt: dto.createdAt,
        lines: dto.lines,
        status: status
    )
}

private func saleDTOUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private func saleDTODecimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
}
