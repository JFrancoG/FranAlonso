import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

struct BillingSeriesAdjustmentSDKBoundaryTests {
    @Test func `pending audit uses a server transform and cannot publish a fabricated date`() throws {
        let pending = BillingSeriesAdjustmentAuditDTO(
            payloadVersion: 1,
            request: BillingSeriesAdjustmentRequestDTO(try seriesAdjustmentRequest()),
            principalID: "admin-opaque-A",
            adjustedAt: nil
        )
        let envelope = FirestoreBillingSeriesAdjustmentAuditDTO(pending)
        let payload = try Firestore.Encoder().encode(envelope)
        let transform = try #require(payload["adjustedAt"] as? FieldValue)
        #expect(transform.isEqual(FieldValue.serverTimestamp()))
        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try envelope.toAudit(operationID: pending.request.id)
        }
    }

    @Test(arguments: [FirestoreEnvironment.develop, .production], [BillingDocumentKind.ticket, .invoice])
    func `administration and reservation address exactly the same selected counter`(
        environment: FirestoreEnvironment,
        kind: BillingDocumentKind
    ) throws {
        let reservation = BillingFirestorePaths(
            environment: environment,
            request: try BillingDocumentRequestDTO(billingTransactionRequest(kind: kind))
        )
        let administration = BillingSeriesAdjustmentFirestorePaths(
            environment: environment,
            request: BillingSeriesAdjustmentRequestDTO(try seriesAdjustmentRequest(series: kind.series))
        )
        #expect(administration.counter == reservation.counter)
        #expect(administration.audit != reservation.document && administration.audit != reservation.binding)
    }

    @Test(arguments: [false, true])
    func `unknown server audit fields cannot be discarded during decoding`(nestedRequest: Bool) throws {
        let resolved = FirestoreBillingSeriesAdjustmentAuditDTO(try seriesAdjustmentAudit(seriesAdjustmentRequest()))
        var payload = try Firestore.Encoder().encode(resolved)
        if nestedRequest {
            var request = try #require(payload["request"] as? [String: Any])
            request["unsupported"] = true
            payload["request"] = request
        } else {
            payload["unsupported"] = true
        }
        #expect(throws: DecodingError.self) {
            try Firestore.Decoder().decode(FirestoreBillingSeriesAdjustmentAuditDTO.self, from: payload)
        }
    }

    @Test func `server acceptance under another operation path is rejected`() throws {
        let resolved = FirestoreBillingSeriesAdjustmentAuditDTO(try seriesAdjustmentAudit(seriesAdjustmentRequest()))
        let transported = try Firestore.Decoder().decode(
            FirestoreBillingSeriesAdjustmentAuditDTO.self,
            from: Firestore.Encoder().encode(resolved)
        )
        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try transported.toAudit(operationID: viewModelUUID(9999).uuidString)
        }
    }
}
