import CryptoKit
import Foundation

/// Acknowledges one immutable remote PDF without duplicating its bytes or exposing a download URL.
///
/// The repository guarantees the complete document/PDF binding. Consumers separately correlate the
/// principal, document ID and canonical private path before publishing completion.
struct BillingPDFUploadReceipt: Identifiable, Codable, Equatable {
    let documentID: BillingDocumentID
    let principalID: String
    let objectPath: String
    var id: BillingDocumentID { documentID }

    func matches(documentID: BillingDocumentID, principalID: String) -> Bool {
        self.documentID == documentID && self.principalID == principalID &&
            objectPath == Self.canonicalPath(documentID: documentID, principalID: principalID)
    }

    /// Derives a stable opaque principal namespace; the hash grants no authorization.
    static func accepted(documentID: BillingDocumentID, principalID: String) -> BillingPDFUploadReceipt {
        BillingPDFUploadReceipt(
            documentID: documentID,
            principalID: principalID,
            objectPath: canonicalPath(documentID: documentID, principalID: principalID)
        )
    }
}

private extension BillingPDFUploadReceipt {
    static func canonicalPath(documentID: BillingDocumentID, principalID: String) -> String {
        let namespace = SHA256.hash(data: Data(principalID.utf8)).map { String(format: "%02x", $0) }.joined()
        return "billing-pdfs/\(namespace)/\(documentID.rawValue.uuidString.lowercased()).pdf"
    }
}
