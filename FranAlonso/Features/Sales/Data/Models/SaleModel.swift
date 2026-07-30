import Foundation
import SwiftData

/// The flattened local SwiftData representation of an atomic Sale snapshot.
///
/// Root lifecycle metadata remains queryable while ordered lines are retained as
/// one independently versioned Codable payload. Live models never leave their context.
@Model
final class SaleModel {
    @Attribute(.unique) var id: UUID
    var clientID: UUID?
    var createdAt: Date
    var createdAtCanonical: String
    var statusKindRawValue: String
    var paymentID: UUID?
    var paymentMethodRawValue: String?
    var paidAtCanonical: String?
    var documentID: UUID?
    var closedAtCanonical: String?
    var reversalID: UUID?
    var voidedAtCanonical: String?
    var linesPayloadVersion: Int
    var linesData: Data

    init(
        id: UUID,
        clientID: UUID?,
        createdAt: Date,
        createdAtCanonical: String,
        statusKindRawValue: String,
        paymentID: UUID?,
        paymentMethodRawValue: String?,
        paidAtCanonical: String?,
        documentID: UUID?,
        closedAtCanonical: String?,
        reversalID: UUID?,
        voidedAtCanonical: String?,
        linesPayloadVersion: Int,
        linesData: Data
    ) {
        self.id = id
        self.clientID = clientID
        self.createdAt = createdAt
        self.createdAtCanonical = createdAtCanonical
        self.statusKindRawValue = statusKindRawValue
        self.paymentID = paymentID
        self.paymentMethodRawValue = paymentMethodRawValue
        self.paidAtCanonical = paidAtCanonical
        self.documentID = documentID
        self.closedAtCanonical = closedAtCanonical
        self.reversalID = reversalID
        self.voidedAtCanonical = voidedAtCanonical
        self.linesPayloadVersion = linesPayloadVersion
        self.linesData = linesData
    }
}
