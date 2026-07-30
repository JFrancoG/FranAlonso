import Foundation
import SwiftData

/// The flattened local SwiftData representation of a Service catalog snapshot.
///
/// Decimal business values retain the same canonical strings used by transport.
/// Domain values are reconstructed at the Data boundary so live persistent models
/// never leave the context that owns them.
@Model
final class ServiceModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRawValue: String
    var linkedProductID: UUID?
    var priceAmountCanonical: String
    var currencyRawValue: String
    var taxPercentageCanonical: String
    var discountPercentageCanonical: String?
    var statusRawValue: String

    init(
        id: UUID,
        name: String,
        typeRawValue: String,
        linkedProductID: UUID?,
        priceAmountCanonical: String,
        currencyRawValue: String,
        taxPercentageCanonical: String,
        discountPercentageCanonical: String?,
        statusRawValue: String
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = typeRawValue
        self.linkedProductID = linkedProductID
        self.priceAmountCanonical = priceAmountCanonical
        self.currencyRawValue = currencyRawValue
        self.taxPercentageCanonical = taxPercentageCanonical
        self.discountPercentageCanonical = discountPercentageCanonical
        self.statusRawValue = statusRawValue
    }
}
