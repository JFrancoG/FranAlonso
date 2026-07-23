import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale line domain entity")
struct SaleLineDomainTests {
    @Test("Preserves every historical service snapshot field")
    func preservesEveryHistoricalServiceSnapshotField() throws {
        let productID = ProductID(rawValue: saleUUID("00000000-0000-0000-0000-000000000003"))
        let line = try makeSaleLine(linkedProductID: productID)
        let expectedUnitPrice = try Money(amount: saleDecimal("32.50"), currency: .eur)
        let expectedTaxRate = try TaxRate(percentage: saleDecimal("21"))
        let expectedDiscount = try Discount(percentage: saleDecimal("10"))

        #expect(line.serviceID == ServiceID(rawValue: saleUUID("00000000-0000-0000-0000-000000000002")))
        #expect(line.serviceName == "Corte y peinado")
        #expect(line.quantity == 2)
        #expect(line.unitPrice == expectedUnitPrice)
        #expect(line.taxRate == expectedTaxRate)
        #expect(line.discount == expectedDiscount)
        #expect(line.linkedProductID == productID)
        #expect(line.status == .upcoming)
        #expect(try saleRoundTrip(line) == line)
        requireSaleSendable(line)
    }

    @Test("Rejects quantities that cannot represent a service line")
    func rejectsQuantitiesThatCannotRepresentAServiceLine() {
        #expect(throws: SaleLineError.invalidQuantity) {
            try makeSaleLine(quantity: 0)
        }
    }

    @Test("Decoding cannot bypass the quantity invariant")
    func decodingCannotBypassTheQuantityInvariant() throws {
        let payload = SaleLinePayload(
            id: SaleLineID(rawValue: saleUUID("00000000-0000-0000-0000-000000000001")),
            serviceID: ServiceID(rawValue: saleUUID("00000000-0000-0000-0000-000000000002")),
            serviceName: "Corte y peinado",
            quantity: 0,
            unitPrice: try Money(amount: saleDecimal("32.50"), currency: .eur),
            taxRate: try TaxRate(percentage: saleDecimal("21")),
            discount: nil,
            linkedProductID: nil,
            status: .upcoming
        )

        #expect(throws: SaleLineError.invalidQuantity) {
            try JSONDecoder().decode(
                SaleLine.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test("Allows only upcoming, in-progress and completed order")
    func allowsOnlyUpcomingInProgressAndCompletedOrder() throws {
        var line = try makeSaleLine()

        try line.start()
        #expect(line.status == .inProgress)
        try line.complete()
        #expect(line.status == .completed)

        #expect(throws: SaleLineError.invalidTransition) {
            try line.complete()
        }
    }
}

@Suite("Sale lifecycle")
struct SaleLifecycleTests {
    @Test("Rejects starting a sale without service lines")
    func rejectsStartingASaleWithoutServiceLines() throws {
        var sale = try Sale.draft(
            id: SaleID(rawValue: saleUUID("10000000-0000-0000-0000-000000000001")),
            clientID: nil,
            createdAt: saleDate(0),
            lines: []
        )

        #expect(throws: SaleError.emptySale) {
            try sale.start()
        }
    }

    @Test("Rejects creating a draft from an already progressed line")
    func rejectsCreatingADraftFromAnAlreadyProgressedLine() throws {
        var line = try makeSaleLine()
        try line.start()

        #expect(throws: SaleError.invalidDraftState) {
            try Sale.draft(
                id: SaleID(rawValue: saleUUID("10000000-0000-0000-0000-000000000003")),
                clientID: nil,
                createdAt: saleDate(0),
                lines: [line]
            )
        }
    }

    @Test("Rejects duplicate line identity when creating a draft")
    func rejectsDuplicateLineIdentityWhenCreatingADraft() throws {
        let line = try makeSaleLine()

        #expect(throws: SaleError.invalidDraftState) {
            try Sale.draft(
                id: SaleID(rawValue: saleUUID("10000000-0000-0000-0000-000000000004")),
                clientID: nil,
                createdAt: saleDate(0),
                lines: [line, line]
            )
        }
    }

    @Test("Moves to awaiting payment only after every line completes")
    func movesToAwaitingPaymentOnlyAfterEveryLineCompletes() throws {
        let firstLine = try makeSaleLine(
            id: SaleLineID(rawValue: saleUUID("20000000-0000-0000-0000-000000000001"))
        )
        let secondLine = try makeSaleLine(
            id: SaleLineID(rawValue: saleUUID("20000000-0000-0000-0000-000000000002"))
        )
        var sale = try makeDraftSale(lines: [firstLine, secondLine])

        try sale.start()
        try sale.startLine(id: firstLine.id)
        try sale.completeLine(id: firstLine.id)
        #expect(sale.status == .inProgress)

        try sale.startLine(id: secondLine.id)
        try sale.completeLine(id: secondLine.id)

        #expect(sale.status == .awaitingPayment)
        #expect(sale.lines.allSatisfy { $0.status == .completed })
    }

    @Test("Rejects payment while a service still requires action")
    func rejectsPaymentWhileAServiceStillRequiresAction() throws {
        let firstLine = try makeSaleLine(
            id: SaleLineID(rawValue: saleUUID("30000000-0000-0000-0000-000000000001"))
        )
        let secondLine = try makeSaleLine(
            id: SaleLineID(rawValue: saleUUID("30000000-0000-0000-0000-000000000002"))
        )
        var sale = try makeDraftSale(lines: [firstLine, secondLine])
        try sale.start()
        try sale.startLine(id: firstLine.id)
        try sale.completeLine(id: firstLine.id)

        #expect(throws: SaleError.invalidSaleTransition) {
            try sale.registerPayment(
                id: PaymentID(rawValue: saleUUID("30000000-0000-0000-0000-000000000003")),
                method: .cash,
                paidAt: saleDate(1)
            )
        }
    }

    @Test("Payment freezes the commercial payload and is idempotent")
    func paymentFreezesTheCommercialPayloadAndIsIdempotent() throws {
        var sale = try makeAwaitingPaymentSale()
        let linesAtPayment = sale.lines
        let paymentID = PaymentID(rawValue: saleUUID("40000000-0000-0000-0000-000000000001"))
        let paidAt = saleDate(1)

        try sale.registerPayment(id: paymentID, method: .card, paidAt: paidAt)

        #expect(sale.status == .awaitingDocument(
            paymentID: paymentID,
            method: .card,
            paidAt: paidAt
        ))
        #expect(sale.lines == linesAtPayment)

        try sale.registerPayment(id: paymentID, method: .card, paidAt: paidAt)
        #expect(sale.lines == linesAtPayment)
    }

    @Test("Reusing a payment identifier with another payload is a conflict")
    func reusingAPaymentIdentifierWithAnotherPayloadIsAConflict() throws {
        var sale = try makeAwaitingPaymentSale()
        let paymentID = PaymentID(rawValue: saleUUID("50000000-0000-0000-0000-000000000001"))
        try sale.registerPayment(id: paymentID, method: .cash, paidAt: saleDate(1))

        #expect(throws: SaleError.conflictingPayment) {
            try sale.registerPayment(id: paymentID, method: .card, paidAt: saleDate(1))
        }
    }

    @Test("Rejects document closure before payment")
    func rejectsDocumentClosureBeforePayment() throws {
        var sale = try makeAwaitingPaymentSale()

        #expect(throws: SaleError.invalidSaleTransition) {
            try sale.close(
                documentID: BillingDocumentID(rawValue: saleUUID("60000000-0000-0000-0000-000000000001")),
                closedAt: saleDate(2)
            )
        }
    }

    @Test("Rejects voiding before the sale has closed")
    func rejectsVoidingBeforeTheSaleHasClosed() throws {
        var sale = try makeAwaitingPaymentSale()

        #expect(throws: SaleError.invalidSaleTransition) {
            try sale.void(
                reversalID: SaleReversalID(rawValue: saleUUID("60000000-0000-0000-0000-000000000002")),
                voidedAt: saleDate(3)
            )
        }
    }

    @Test("Closing adds only document metadata and is idempotent")
    func closingAddsOnlyDocumentMetadataAndIsIdempotent() throws {
        var sale = try makeAwaitingPaymentSale()
        let linesAtPayment = sale.lines
        let paymentID = PaymentID(rawValue: saleUUID("70000000-0000-0000-0000-000000000001"))
        let documentID = BillingDocumentID(rawValue: saleUUID("70000000-0000-0000-0000-000000000002"))
        let paidAt = saleDate(1)
        let closedAt = saleDate(2)
        try sale.registerPayment(id: paymentID, method: .cash, paidAt: paidAt)

        try sale.close(documentID: documentID, closedAt: closedAt)

        #expect(sale.status == .closed(
            paymentID: paymentID,
            method: .cash,
            paidAt: paidAt,
            documentID: documentID,
            closedAt: closedAt
        ))
        #expect(sale.lines == linesAtPayment)

        try sale.close(documentID: documentID, closedAt: closedAt)
        #expect(sale.lines == linesAtPayment)
    }

    @Test("Reusing closure with other metadata is a conflict")
    func reusingClosureWithOtherMetadataIsAConflict() throws {
        var sale = try makeClosedSale()

        #expect(throws: SaleError.conflictingDocument) {
            try sale.close(
                documentID: BillingDocumentID(rawValue: saleUUID("80000000-0000-0000-0000-000000000009")),
                closedAt: saleDate(2)
            )
        }
    }

    @Test("Voiding is a stable compensating transition")
    func voidingIsAStableCompensatingTransition() throws {
        var sale = try makeClosedSale()
        let closedLines = sale.lines
        let reversalID = SaleReversalID(rawValue: saleUUID("90000000-0000-0000-0000-000000000001"))
        let voidedAt = saleDate(3)

        try sale.void(reversalID: reversalID, voidedAt: voidedAt)

        guard case let .voided(
            paymentID,
            method,
            paidAt,
            documentID,
            closedAt,
            storedReversalID,
            storedVoidedAt
        ) = sale.status else {
            Issue.record("Expected a voided sale")
            return
        }
        #expect(paymentID == PaymentID(rawValue: saleUUID("A0000000-0000-0000-0000-000000000001")))
        #expect(method == .card)
        #expect(paidAt == saleDate(1))
        #expect(documentID == BillingDocumentID(rawValue: saleUUID("A0000000-0000-0000-0000-000000000002")))
        #expect(closedAt == saleDate(2))
        #expect(storedReversalID == reversalID)
        #expect(storedVoidedAt == voidedAt)
        #expect(sale.lines == closedLines)

        try sale.void(reversalID: reversalID, voidedAt: voidedAt)
        #expect(throws: SaleError.conflictingReversal) {
            try sale.void(
                reversalID: reversalID,
                voidedAt: saleDate(4)
            )
        }
    }

    @Test("Preserves a terminal sale through Codable")
    func preservesATerminalSaleThroughCodable() throws {
        var sale = try makeClosedSale()
        try sale.void(
            reversalID: SaleReversalID(rawValue: saleUUID("B0000000-0000-0000-0000-000000000001")),
            voidedAt: saleDate(3)
        )

        #expect(try saleRoundTrip(sale) == sale)
        requireSaleSendable(sale)
    }

    @Test("Decoding cannot pair a paid state with unfinished lines")
    func decodingCannotPairAPaidStateWithUnfinishedLines() throws {
        let payload = SalePayload(
            id: SaleID(rawValue: saleUUID("C0000000-0000-0000-0000-000000000001")),
            clientID: nil,
            createdAt: saleDate(0),
            lines: [try makeSaleLine()],
            status: .awaitingDocument(
                paymentID: PaymentID(rawValue: saleUUID("C0000000-0000-0000-0000-000000000002")),
                method: .cash,
                paidAt: saleDate(1)
            )
        )

        #expect(throws: SaleError.invalidPersistedState) {
            try JSONDecoder().decode(
                Sale.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test("Decoding cannot restore duplicate line identity")
    func decodingCannotRestoreDuplicateLineIdentity() throws {
        let line = try makeSaleLine()
        let payload = SalePayload(
            id: SaleID(rawValue: saleUUID("C0000000-0000-0000-0000-000000000003")),
            clientID: nil,
            createdAt: saleDate(0),
            lines: [line, line],
            status: .draft
        )

        #expect(throws: SaleError.invalidPersistedState) {
            try JSONDecoder().decode(
                Sale.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }
}

private struct SaleLinePayload: Codable {
    let id: SaleLineID
    let serviceID: ServiceID
    let serviceName: String
    let quantity: Int
    let unitPrice: Money
    let taxRate: TaxRate
    let discount: Discount?
    let linkedProductID: ProductID?
    let status: SaleLineStatus
}

private struct SalePayload: Codable {
    let id: SaleID
    let clientID: ClientID?
    let createdAt: Date
    let lines: [SaleLine]
    let status: SaleStatus
}

private func makeSaleLine(
    id: SaleLineID = SaleLineID(rawValue: saleUUID("00000000-0000-0000-0000-000000000001")),
    quantity: Int = 2,
    linkedProductID: ProductID? = nil
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: id,
        serviceID: ServiceID(rawValue: saleUUID("00000000-0000-0000-0000-000000000002")),
        serviceName: "Corte y peinado",
        quantity: quantity,
        unitPrice: Money(amount: saleDecimal("32.50"), currency: .eur),
        taxRate: TaxRate(percentage: saleDecimal("21")),
        discount: Discount(percentage: saleDecimal("10")),
        linkedProductID: linkedProductID
    )
}

private func makeDraftSale(lines: [SaleLine]) throws -> Sale {
    try Sale.draft(
        id: SaleID(rawValue: saleUUID("10000000-0000-0000-0000-000000000001")),
        clientID: ClientID(rawValue: saleUUID("10000000-0000-0000-0000-000000000002")),
        createdAt: saleDate(0),
        lines: lines
    )
}

private func makeAwaitingPaymentSale() throws -> Sale {
    let line = try makeSaleLine()
    var sale = try makeDraftSale(lines: [line])
    try sale.start()
    try sale.startLine(id: line.id)
    try sale.completeLine(id: line.id)
    return sale
}

private func makeClosedSale() throws -> Sale {
    var sale = try makeAwaitingPaymentSale()
    try sale.registerPayment(
        id: PaymentID(rawValue: saleUUID("A0000000-0000-0000-0000-000000000001")),
        method: .card,
        paidAt: saleDate(1)
    )
    try sale.close(
        documentID: BillingDocumentID(rawValue: saleUUID("A0000000-0000-0000-0000-000000000002")),
        closedAt: saleDate(2)
    )
    return sale
}

private func saleDate(_ dayOffset: TimeInterval) -> Date {
    Date(timeIntervalSince1970: dayOffset * 86_400)
}

private func saleUUID(_ rawValue: String) -> UUID {
    UUID(uuidString: rawValue)!
}

private func saleDecimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
}

private func saleRoundTrip<Value: Codable>(_ value: Value) throws -> Value {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(Value.self, from: data)
}

private func requireSaleSendable<Value: Sendable>(_ value: Value) {}
