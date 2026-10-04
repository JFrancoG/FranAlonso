import Foundation
import SwiftData

/// Persists one sealed request and its exact recoverable checkpoints without duplicating PDF bytes.
@Model
final class BillingDocumentDeliveryModel {
    @Attribute(.unique) var id: UUID
    var documentID: UUID
    var saleID: UUID
    var kind: String
    var principalID: String
    var payloadVersion: Int
    var payload: Data

    init(_ delivery: BillingDocumentDelivery) throws {
        id = delivery.id.rawValue
        documentID = delivery.request.documentID.rawValue
        saleID = delivery.request.saleID.rawValue
        kind = delivery.request.kind.rawValue
        principalID = delivery.principalID
        payloadVersion = 1
        payload = try JSONEncoder().encode(BillingDocumentDeliveryEnvelope(delivery: delivery))
        _ = try toDomain()
    }

    /// Rejects unknown envelopes or mismatched indexed bindings without modifying their persisted bytes.
    func toDomain() throws -> BillingDocumentDelivery {
        guard payloadVersion == 1 else { throw BillingDocumentPersistenceError.invalidState }
        do {
            let delivery = try JSONDecoder().decode(BillingDocumentDeliveryEnvelope.self, from: payload).delivery
            guard delivery.id.rawValue == id, delivery.request.documentID.rawValue == documentID,
                  delivery.request.saleID.rawValue == saleID, delivery.request.kind.rawValue == kind,
                  delivery.principalID == principalID
            else { throw BillingDocumentPersistenceError.invalidState }
            if let pdf = delivery.pdf {
                try BillingPDFUploadValidator.validate(pdf)
            }
            return delivery
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BillingDocumentPersistenceError.invalidState
        }
    }

    /// Advances only this envelope's immutable indexed binding, retaining one copy of the complete PDF.
    func update(_ delivery: BillingDocumentDelivery) throws {
        guard payloadVersion == 1, delivery.id.rawValue == id,
              delivery.request.documentID.rawValue == documentID, delivery.request.saleID.rawValue == saleID,
              delivery.request.kind.rawValue == kind, delivery.principalID == principalID
        else { throw BillingDocumentPersistenceError.conflict }
        if let pdf = delivery.pdf {
            try BillingPDFUploadValidator.validate(pdf)
        }
        let encoded = try JSONEncoder().encode(BillingDocumentDeliveryEnvelope(delivery: delivery))
        _ = try JSONDecoder().decode(BillingDocumentDeliveryEnvelope.self, from: encoded)
        payload = encoded
    }
}

private struct BillingDocumentDeliveryEnvelope: Codable {
    let delivery: BillingDocumentDelivery
}
