import Foundation

/// A stable acknowledgement of one principal's immutable document, without duplicating its PDF.
///
/// Storage guarantees that the acknowledgement describes the complete submitted value. Consumers
/// must also check its principal and document identity before persisting completion. A receipt alone
/// does not activate a client or replace the reference to their initial signed information.
struct ClientDocumentUploadReceipt: Identifiable, Codable, Equatable {
    let documentID: UUID
    let principalID: String
    let reference: ClientConsentReference
    var id: UUID { documentID }

    func matches(documentID: UUID, principalID: String) -> Bool {
        self.documentID == documentID && self.principalID == principalID
    }
}
