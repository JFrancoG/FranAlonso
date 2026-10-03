import Foundation
import Testing
@testable import FranAlonso

@Suite("Confirmed billing document projection")
struct BillingDocumentProjectionTests {
    @Test(
        arguments: [
            RenderingMoneyOracle(
                price: "100",
                line: "10",
                global: "20",
                tax: "21",
                subtotal: "100",
                lineAmount: "10",
                globalAmount: "18",
                base: "59.50",
                taxAmount: "12.50",
                total: "72"
            ),
            RenderingMoneyOracle(
                price: "0.07",
                line: "50",
                global: "50",
                tax: "0",
                subtotal: "0.07",
                lineAmount: "0.04",
                globalAmount: "0.02",
                base: "0.01",
                taxAmount: "0",
                total: "0.01"
            ),
            RenderingMoneyOracle(
                price: "-100",
                line: "10",
                global: "20",
                tax: "21",
                subtotal: "-100",
                lineAmount: "-10",
                globalAmount: "-18",
                base: "-59.50",
                taxAmount: "-12.50",
                total: "-72"
            ),
            RenderingMoneyOracle(
                price: "19.99",
                line: "12.5",
                global: "12.345678901234567890123456789012345678",
                tax: "21",
                subtotal: "19.99",
                lineAmount: "2.50",
                globalAmount: "2.16",
                base: "12.67",
                taxAmount: "2.66",
                total: "15.33"
            ),
            RenderingMoneyOracle(
                price: "100",
                line: "100",
                global: "20",
                tax: "21",
                subtotal: "100",
                lineAmount: "100",
                globalAmount: "0",
                base: "0",
                taxAmount: "0",
                total: "0"
            ),
            RenderingMoneyOracle(
                price: "12.10",
                line: nil,
                global: nil,
                tax: "21",
                subtotal: "12.10",
                lineAmount: "0",
                globalAmount: "0",
                base: "10",
                taxAmount: "2.10",
                total: "12.10"
            ),
            RenderingMoneyOracle(
                price: "12.10",
                line: "0",
                global: "0",
                tax: "21",
                subtotal: "12.10",
                lineAmount: "0",
                globalAmount: "0",
                base: "10",
                taxAmount: "2.10",
                total: "12.10"
            )
        ]
    )
    private func `the complete paid snapshot determines all monetary components`(
        _ oracle: RenderingMoneyOracle
    ) throws {
        let document = try billingRenderingDocument(
            lines: [
                billingRenderingLine(price: oracle.price, tax: oracle.tax, lineDiscount: oracle.line)
            ],
            globalDiscount: oracle.global
        )

        let result = try BillingDocumentProjection(document: document).calculation

        #expect(result.subtotal.amount == (try billingRenderingDecimal(oracle.subtotal)))
        #expect(result.lineDiscountAmount.amount == (try billingRenderingDecimal(oracle.lineAmount)))
        #expect(result.globalDiscountAmount.amount == (try billingRenderingDecimal(oracle.globalAmount)))
        #expect(result.taxableBase.amount == (try billingRenderingDecimal(oracle.base)))
        #expect(result.taxAmount.amount == (try billingRenderingDecimal(oracle.taxAmount)))
        #expect(result.total.amount == (try billingRenderingDecimal(oracle.total)))
        let line = try #require(result.lineCalculations.first)
        #expect(line.taxableBase.amount == (try billingRenderingDecimal(oracle.base)))
        #expect(line.taxAmount.amount == (try billingRenderingDecimal(oracle.taxAmount)))
        #expect(line.total.amount == (try billingRenderingDecimal(oracle.total)))
    }

    @Test
    func `mixed captured tax rates round per line and preserve display order`() throws {
        let document = try billingRenderingDocument(
            lines: [
                billingRenderingLine(
                    name: "Primero",
                    price: "10",
                    tax: "21",
                    lineDiscount: nil,
                    index: 2
                ),
                billingRenderingLine(
                    name: "Segundo",
                    price: "10",
                    tax: "10",
                    lineDiscount: nil,
                    index: 1
                )
            ],
            globalDiscount: nil
        )

        let result = try BillingDocumentProjection(document: document).calculation

        #expect(result.taxableBase.amount == (try billingRenderingDecimal("17.35")))
        #expect(result.taxAmount.amount == (try billingRenderingDecimal("2.65")))
        #expect(result.total.amount == 20)
        #expect(result.lineCalculations.map(\.taxableBase.amount) == [
            try billingRenderingDecimal("8.26"), try billingRenderingDecimal("9.09")
        ])
        #expect(result.lineCalculations.map(\.id) == document.request.sale.lines.map(\.id))
    }

    @Test
    func `captured quantity participates in the financial projection`() throws {
        let document = try billingRenderingDocument(
            lines: [billingRenderingLine(
                price: "12.10",
                tax: "21",
                lineDiscount: nil,
                quantity: 3
            )],
            globalDiscount: nil
        )

        let result = try BillingDocumentProjection(document: document).calculation

        #expect(result.subtotal.amount == (try billingRenderingDecimal("36.30")))
        #expect(result.taxableBase.amount == 30)
        #expect(result.taxAmount.amount == (try billingRenderingDecimal("6.30")))
        #expect(result.total.amount == (try billingRenderingDecimal("36.30")))
    }

    @Test
    func `USD snapshots cannot be represented by a EUR template`() throws {
        let document = try billingRenderingDocument(lines: [billingRenderingLine(currency: .usd)])

        #expect(throws: BillingDocumentProjectionError.unsupportedCurrency(.usd)) {
            try BillingDocumentProjection(document: document)
        }
    }

    @Test
    func `mixed currency snapshots retain the calculator error`() throws {
        let document = try billingRenderingDocument(lines: [
            billingRenderingLine(index: 1),
            billingRenderingLine(currency: .usd, index: 2)
        ])

        #expect(throws: SaleCalculatorError.incompatibleCurrency(expected: .eur, actual: .usd)) {
            try BillingDocumentProjection(document: document)
        }
    }

    @Test
    func `historical invoices without their recipient fail before enrichment`() throws {
        let document = try billingRenderingDocument(kind: .invoice, includeFiscalRecipient: false)

        #expect(throws: BillingDocumentProjectionError.missingFiscalRecipient) {
            try BillingDocumentProjection(document: document)
        }
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func `missing historical service names cannot disappear from a document`(_ name: String) throws {
        let document = try billingRenderingDocument(name: name)

        #expect(throws: BillingDocumentProjectionError.missingServiceName) {
            try BillingDocumentProjection(document: document)
        }
    }

    @Test
    func `precision failures are not hidden by a complete discount`() throws {
        let document = try billingRenderingDocument(
            lines: [
                billingRenderingLine(
                    price: "999999999999999999999999999999999999.99",
                    lineDiscount: nil,
                    quantity: Int.max
                )
            ],
            globalDiscount: "100"
        )

        #expect(throws: MoneyError.invalidAmount) {
            try BillingDocumentProjection(document: document)
        }
    }
}

private struct RenderingMoneyOracle {
    let price: String
    let line: String?
    let global: String?
    let tax: String
    let subtotal: String
    let lineAmount: String
    let globalAmount: String
    let base: String
    let taxAmount: String
    let total: String
}
