import Foundation

/// Formats captured Decimal values exactly for the current Spanish/EUR backgrounds.
/// Canonical Decimal text avoids floating conversion or rounding a captured percentage.
struct BillingDocumentPDFText {
    let bundle: Bundle

    func label(_ key: BillingDocumentPDFLabel) -> String {
        String(
            localized: String.LocalizationValue(stringLiteral: key.rawValue),
            table: "DocumentTemplates",
            bundle: bundle,
            locale: Locale(identifier: "es")
        )
    }

    func money(_ value: Money) -> String {
        var amount = value.amount
        let canonical = NSDecimalString(&amount, Locale(identifier: "en_US_POSIX"))
        let parts = canonical.split(separator: ".", omittingEmptySubsequences: false)
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        return String(parts[0]) + "," + fraction + String(repeating: "0", count: max(0, 2 - fraction.count))
    }

    func percentage(_ value: Decimal) -> String {
        var amount = value
        return NSDecimalString(&amount, Locale(identifier: "en_US_POSIX")).replacingOccurrences(of: ".", with: ",")
            + " %"
    }

    func discount(_ value: Discount?) -> String {
        value.map { percentage($0.percentage) } ?? label(.absentDiscount)
    }

    func description(
        line: SaleLine,
        calculation: SaleLineCalculation,
        global: SaleGlobalDiscount?,
        index: Int
    ) -> String {
        let unit = "\(label(.unitPrice)): \(money(line.unitPrice))"
        let rate = "\(label(.taxRate)): \(percentage(line.taxRate.percentage))"
        let promotion = "\(label(.linePromotion)): \(discount(line.discount))"
        let globalTerm = "\(label(.globalDiscount)): \(discount(global?.discount))"
        let subtotal = "\(label(.subtotal)): \(money(calculation.subtotal))"
        let base = "\(label(.taxableBase)): \(money(calculation.taxableBase))"
        let tax = "\(label(.taxAmount)): \(money(calculation.taxAmount))"
        let lineAmount = "\(label(.lineAmount)): \(money(calculation.lineDiscountAmount))"
        let globalAmount = "\(label(.globalAmount)): \(money(calculation.globalDiscountAmount))"
        return [
            "\(index + 1). \(line.serviceName)",
            "\(unit); \(rate)",
            "\(promotion); \(globalTerm)",
            "\(subtotal); \(base)",
            "\(tax); \(lineAmount); \(globalAmount)"
        ].joined(separator: "\n")
    }

    func summary(_ calculation: SaleCalculation) -> String {
        [
            "\(label(.subtotal)): \(money(calculation.subtotal))",
            "\(label(.lineAmount)): \(money(calculation.lineDiscountAmount))",
            "\(label(.globalAmount)): \(money(calculation.globalDiscountAmount))"
        ].joined(separator: "\n")
    }
}

/// Semantic labels shared by the document's table details and page annotations.
enum BillingDocumentPDFLabel: String {
    case unitPrice = "billing.pdf.unit_price"
    case taxRate = "billing.pdf.tax_rate"
    case linePromotion = "billing.pdf.line_promotion"
    case globalDiscount = "billing.pdf.global_discount"
    case absentDiscount = "billing.pdf.absent_discount"
    case subtotal = "billing.pdf.subtotal"
    case taxableBase = "billing.pdf.taxable_base"
    case taxAmount = "billing.pdf.tax_amount"
    case lineAmount = "billing.pdf.line_amount"
    case globalAmount = "billing.pdf.global_amount"
    case continuation = "billing.pdf.continuation"
    case page = "billing.pdf.page"
}
