import Foundation
import Testing
@testable import FranAlonso

@Suite("Durable billing checkpoint invariants")
struct BillingDocumentDeliveryTests {
    @Test
    func receiptMakesFinalOnlyAfterConfirmedDocumentPDFAndAttempt() throws {
        let document = try billingRenderingDocument()
        var delivery = try BillingDocumentDelivery(request: document.request, principalID: "principal-A")
        #expect(!delivery.isFinal)
        #expect(throws: BillingDocumentPersistenceError.invalidState) {
            try delivery.completeUpload(.accepted(documentID: document.id, principalID: "principal-A"))
        }
        try delivery.accept(document)
        #expect(!delivery.isFinal)
        try delivery.acceptPDF(billingPDFTemplate())
        #expect(!delivery.isFinal)
        try delivery.beginUpload()
        try delivery.completeUpload(.accepted(documentID: document.id, principalID: "principal-A"))
        #expect(delivery.isFinal)
        #expect(delivery.uploadAttempts == 1)
        #expect(delivery.document == document)
        guard case .awaitingDocument = delivery.request.sale.status else {
            Issue.record("Materialization must retain the paid sale awaiting its document")
            return
        }
        let decoded = try JSONDecoder().decode(BillingDocumentDelivery.self, from: JSONEncoder().encode(delivery))
        #expect(decoded == delivery)
    }

    @Test
    func acceptedBytesAreImmutableAndFinalReplayCannotDemote() throws {
        let document = try billingRenderingDocument()
        var delivery = try BillingDocumentDelivery(request: document.request, principalID: "principal-A")
        try delivery.accept(document)
        let pdf = try billingPDFTemplate()
        try delivery.acceptPDF(pdf)
        try delivery.acceptPDF(pdf)
        #expect(throws: BillingDocumentPersistenceError.conflict) {
            try delivery.acceptPDF(Data("different bytes".utf8))
        }
        try delivery.beginUpload()
        let receipt = BillingPDFUploadReceipt.accepted(documentID: document.id, principalID: "principal-A")
        try delivery.completeUpload(receipt)
        let final = delivery
        try delivery.recordFailure(phase: .upload, reason: .unavailable, attempt: 1)
        try delivery.beginUpload()
        try delivery.completeUpload(receipt)
        #expect(delivery == final)
    }

    @Test
    func previousPhaseAndPreviousAttemptFailuresCannotReplaceLaterCheckpoint() throws {
        let document = try billingRenderingDocument()
        var delivery = try BillingDocumentDelivery(request: document.request, principalID: "principal-A")
        try delivery.accept(document)
        try delivery.recordFailure(phase: .numbering, reason: .conflict, attempt: nil)
        #expect(delivery.failure == nil)
        try delivery.acceptPDF(billingPDFTemplate())
        try delivery.beginUpload()
        try delivery.recordFailure(phase: .upload, reason: .unavailable, attempt: 1)
        #expect(delivery.failure?.reason == .unavailable)
        try delivery.beginUpload()
        try delivery.recordFailure(phase: .upload, reason: .conflict, attempt: 1)
        #expect(delivery.failure == nil)
        #expect(delivery.uploadAttempts == 2)
    }

    @Test(arguments: ["principal", "attempts", "pdf", "receipt"])
    func decodingRejectsBrokenCrossFieldInvariants(_ damage: String) throws {
        let document = try billingRenderingDocument()
        let delivery = try BillingDocumentDelivery(request: document.request, principalID: "principal-A")
        let encoded = try JSONEncoder().encode(delivery)
        var envelope = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var contents = try #require(envelope["contents"] as? [String: Any])
        switch damage {
        case "principal": contents["principalID"] = ""
        case "attempts": contents["uploadAttempts"] = -1
        case "pdf": contents["pdf"] = Data("%PDF synthetic".utf8).base64EncodedString()
        default:
            contents["receipt"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(
                BillingPDFUploadReceipt.accepted(documentID: document.id, principalID: "principal-A")
            ))
        }
        envelope["contents"] = contents
        let corrupted = try JSONSerialization.data(withJSONObject: envelope)
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(BillingDocumentDelivery.self, from: corrupted)
        }
    }
}
