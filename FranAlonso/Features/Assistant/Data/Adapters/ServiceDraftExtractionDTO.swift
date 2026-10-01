import Foundation
import FoundationModels

/// Ephemeral literal evidence returned by the model; it is untrusted until converted to Domain.
@Generable(representNilExplicitlyInGeneratedContent: true)
struct ServiceDraftExtractionDTO {
    @Guide(description: "Exact service-name passage from the description, unchanged; null when absent.")
    var name: String?

    @Guide(description: """
        Exact passage from price or precio through its amount and currency (EUR, euros, euro, €, USD),
        unchanged; null when absent.
        """)
    var priceEvidence: String?

    @Guide(description: """
        Exact tax, VAT, IVA or impuesto passage through its numeric percentage and %, unchanged;
        null when absent.
        """)
    var taxEvidence: String?

    @Guide(description: """
        Exact discount or descuento passage through its numeric percentage and %, unchanged;
        null when absent.
        """)
    var discountEvidence: String?
}

extension ServiceDraftExtractionDTO {
    /// Requires literal evidence tied to each commercial field before creating a partial proposal.
    func toDomain(source: String, locale: Locale) throws -> ServiceDraftProposal {
        let evidence = ServiceDraftEvidenceParser(source: source, locale: locale)
        do {
            return try ServiceDraftProposal(
                name: name.map(evidence.name),
                price: priceEvidence.map(evidence.price),
                taxRate: taxEvidence.map(evidence.taxRate),
                discount: discountEvidence.map(evidence.discount)
            )
        } catch {
            throw ServiceDraftAssistantError.clarification
        }
    }
}
