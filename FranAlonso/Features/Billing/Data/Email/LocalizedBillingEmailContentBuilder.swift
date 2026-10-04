import Foundation

/// Resolves editable plain-text email copy in the caller's selected language.
/// Only the confirmed document family and number enter the subject and body.
struct LocalizedBillingEmailContentBuilder: BillingEmailContentBuilder {
    let bundle: Bundle
    let locale: Locale

    func content(for document: BillingDocument) -> BillingEmailContent {
        let number = document.number.value
        let subject: LocalizedStringResource
        let body: LocalizedStringResource
        switch document.kind {
        case .ticket:
            subject = LocalizedStringResource(
                "billing.email.ticket.subject",
                defaultValue: "Tu ticket nº \(number)",
                locale: locale,
                bundle: .atURL(bundle.bundleURL)
            )
            body = LocalizedStringResource(
                "billing.email.ticket.body",
                defaultValue: "Adjunto encontrarás tu ticket nº \(number).",
                locale: locale,
                bundle: .atURL(bundle.bundleURL)
            )
        case .invoice:
            subject = LocalizedStringResource(
                "billing.email.invoice.subject",
                defaultValue: "Tu factura nº \(number)",
                locale: locale,
                bundle: .atURL(bundle.bundleURL)
            )
            body = LocalizedStringResource(
                "billing.email.invoice.body",
                defaultValue: "Adjunto encontrarás tu factura nº \(number).",
                locale: locale,
                bundle: .atURL(bundle.bundleURL)
            )
        }
        return BillingEmailContent(subject: String(localized: subject), body: String(localized: body))
    }
}
