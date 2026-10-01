import Foundation

/// A nonempty, partial proposal for one professional service, with no persistence capability.
///
/// An absent field means no change to the person's draft. Zero percentages are explicit values.
/// Construction and decoding reject blank proposed names and negative prices.
struct ServiceDraftProposal: Codable, Equatable {
    private let storedName: String?
    private let storedPrice: Money?
    private let storedTaxRate: TaxRate?
    private let storedDiscount: Discount?

    var name: String? { storedName }
    var price: Money? { storedPrice }
    var taxRate: TaxRate? { storedTaxRate }
    var discount: Discount? { storedDiscount }

    private enum CodingKeys: String, CodingKey {
        case storedName = "name"
        case storedPrice = "price"
        case storedTaxRate = "taxRate"
        case storedDiscount = "discount"
    }
}

extension ServiceDraftProposal {
    /// Rejects an empty or invalid proposal without filling any missing commercial field.
    init(
        name: String? = nil,
        price: Money? = nil,
        taxRate: TaxRate? = nil,
        discount: Discount? = nil
    ) throws {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName == nil || trimmedName?.isEmpty == false else {
            throw ServiceDraftAssistantError.clarification
        }
        guard price == nil || price.map({ $0.amount >= 0 }) == true else {
            throw ServiceDraftAssistantError.clarification
        }
        guard trimmedName != nil || price != nil || taxRate != nil || discount != nil else {
            throw ServiceDraftAssistantError.clarification
        }

        self.init(
            storedName: trimmedName,
            storedPrice: price,
            storedTaxRate: taxRate,
            storedDiscount: discount
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: container.decodeIfPresent(String.self, forKey: .storedName),
            price: container.decodeIfPresent(Money.self, forKey: .storedPrice),
            taxRate: container.decodeIfPresent(TaxRate.self, forKey: .storedTaxRate),
            discount: container.decodeIfPresent(Discount.self, forKey: .storedDiscount)
        )
    }
}
