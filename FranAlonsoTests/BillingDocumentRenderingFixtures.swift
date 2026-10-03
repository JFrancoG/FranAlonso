import Foundation
import Testing
@testable import FranAlonso

func billingRenderingDecimal(_ literal: String) throws -> Decimal {
    try #require(Decimal(string: literal, locale: Locale(identifier: "en_US_POSIX")))
}

func billingRenderingLine(
    name: String = "Servicio histórico de muestra",
    price: String = "100",
    tax: String = "21",
    lineDiscount: String? = nil,
    currency: Currency = .eur,
    quantity: Int = 1,
    index: Int = 1
) throws -> SaleLine {
    try SaleLine.upcoming(
        id: SaleLineID(rawValue: billingRenderingUUID(index)),
        serviceID: ServiceID(rawValue: billingRenderingUUID(10_000 + index)),
        serviceName: name,
        quantity: quantity,
        unitPrice: Money(amount: billingRenderingDecimal(price), currency: currency),
        taxRate: TaxRate(percentage: billingRenderingDecimal(tax)),
        discount: try lineDiscount.map { try Discount(percentage: billingRenderingDecimal($0)) },
        linkedProductID: nil
    )
}

func billingRenderingDocument(
    kind: BillingDocumentKind = .ticket,
    lines: [SaleLine]? = nil,
    globalDiscount: String? = nil,
    fiscalRecipient: BillingFiscalRecipient? = nil,
    includeFiscalRecipient: Bool = true,
    name: String = "Servicio histórico de muestra"
) throws -> BillingDocument {
    var sale = try Sale.draft(
        id: SaleID(rawValue: billingRenderingUUID(20_001)),
        clientID: ClientID(rawValue: billingRenderingUUID(20_002)),
        createdAt: Date(timeIntervalSince1970: 1_000),
        lines: lines ?? [billingRenderingLine(name: name)],
        globalDiscount: try globalDiscount.map {
            try SaleGlobalDiscount(
                discount: Discount(percentage: billingRenderingDecimal($0)),
                policy: .lineThenGlobalV1
            )
        }
    )
    try sale.start()
    for line in sale.lines {
        try sale.startLine(id: line.id)
        try sale.completeLine(id: line.id)
    }
    try sale.registerPayment(
        id: PaymentID(rawValue: billingRenderingUUID(20_003)),
        method: .cash,
        paidAt: Date(timeIntervalSince1970: 1_500)
    )
    let recipient: BillingFiscalRecipient?
    if kind == .invoice, includeFiscalRecipient {
        recipient = try fiscalRecipient ?? billingRenderingFiscalRecipient()
    } else {
        recipient = nil
    }
    let request = try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: billingRenderingUUID(20_004)),
        documentID: BillingDocumentID(rawValue: billingRenderingUUID(20_005)),
        sale: sale,
        kind: kind,
        requestedAt: Date(timeIntervalSince1970: 1_700),
        fiscalRecipient: recipient
    )
    return try BillingDocument.numbered(
        request: request,
        number: BillingDocumentNumber(series: kind.series, value: kind == .ticket ? 41 : 91),
        issuedAt: Date(timeIntervalSince1970: 1_759_493_045)
    )
}

func billingRenderingFiscalRecipient() throws -> BillingFiscalRecipient {
    try BillingFiscalRecipient(BillingFiscalRecipientInput(
        displayName: "Persona sintética histórica",
        taxIdentifier: "DEMO-NIF-138",
        streetLine: "Calle sintética 13",
        postalCode: "28000",
        city: "Ciudad de muestra",
        province: "Provincia de muestra"
    ))
}

private func billingRenderingUUID(_ index: Int) throws -> UUID {
    let digits = String(index)
    let suffix = String(repeating: "0", count: 12 - digits.count) + digits
    return try #require(UUID(uuidString: "13800000-0000-0000-0000-" + suffix))
}
