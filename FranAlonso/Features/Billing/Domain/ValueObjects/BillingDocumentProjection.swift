import Foundation

/// Recoverable incompatibilities between captured document data and the supported EUR templates.
enum BillingDocumentProjectionError: Error, Equatable {
    case unsupportedCurrency(Currency)
    case missingFiscalRecipient
    case missingServiceName
}

/// A transient financial projection of one confirmed, immutable paid-sale snapshot.
///
/// Derived totals are not persisted. The captured sale remains the authority for commercial
/// and fiscal terms; projection never reads a current catalog or client profile.
struct BillingDocumentProjection: Equatable {
    let document: BillingDocument
    private let storedCalculation: SaleCalculation

    var calculation: SaleCalculation { storedCalculation }
}

extension BillingDocumentProjection {
    /// Recalculates the complete captured sale under its retained rounding and discount policy.
    ///
    /// The bundled templates support EUR only. An invoice needs its captured recipient and
    /// every line needs a historical display name; valid text is retained without normalization.
    /// - Throws: Unsupported-template or missing-snapshot errors, or the calculator's exact monetary errors.
    init(document: BillingDocument) throws {
        let sale = document.request.sale
        let currency = sale.lines.first?.unitPrice.currency ?? .eur
        guard currency == .eur else { throw BillingDocumentProjectionError.unsupportedCurrency(currency) }
        guard document.kind != .invoice || document.request.fiscalRecipient != nil else {
            throw BillingDocumentProjectionError.missingFiscalRecipient
        }
        guard sale.lines.allSatisfy({ !$0.serviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw BillingDocumentProjectionError.missingServiceName
        }
        let calculation = try SaleCalculator().calculate(sale: sale, currency: .eur)
        self.init(document: document, storedCalculation: calculation)
    }
}
