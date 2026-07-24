import Foundation
import SwiftData

/// The local SwiftData representation of a client profile.
///
/// Domain values are mapped at the Data boundary so live persistent models never
/// leave the context that owns them.
@Model
final class ClientModel {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var taxIdentifier: String?
    var billingStreetLine: String?
    var billingPostalCode: String?
    var billingCity: String?
    var billingProvince: String?
    var statusRawValue: String
    var consentReference: String?

    init(
        id: UUID,
        displayName: String,
        taxIdentifier: String?,
        billingStreetLine: String?,
        billingPostalCode: String?,
        billingCity: String?,
        billingProvince: String?,
        statusRawValue: String,
        consentReference: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.taxIdentifier = taxIdentifier
        self.billingStreetLine = billingStreetLine
        self.billingPostalCode = billingPostalCode
        self.billingCity = billingCity
        self.billingProvince = billingProvince
        self.statusRawValue = statusRawValue
        self.consentReference = consentReference
    }
}
