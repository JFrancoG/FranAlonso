import Foundation

enum DocumentTemplateResource: String, CaseIterable, Sendable {
    case clientConsent = "client-consent-template"
    case billingTicketA4 = "billing-ticket-a4-template"
    case billingInvoiceA4 = "billing-invoice-a4-template"

    func url(in bundle: Bundle) -> URL? {
        bundle.url(forResource: rawValue, withExtension: "pdf")
    }
}
