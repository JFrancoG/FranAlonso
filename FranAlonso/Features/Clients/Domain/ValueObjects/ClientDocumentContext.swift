import Foundation

/// A pending photograph is not authorized until an explicit decision is made.
enum ClientDocumentPhotoDecision: String, Codable {
    case notSelected
    case undecided
    case authorized
    case declined
}

/// Subsequent authorization never replaces the initial signed information or changes client activation.
enum ClientDocumentPurpose: String, Codable {
    case initialInformation
    case subsequentPhotoAuthorization
}

/// The section set selected for presentation. Declining or removing a photo uses data-only information.
enum ClientDocumentVariant: String, Codable {
    case dataInformation
    case informationWithPhoto
}

/// Context for document preparation; contains no image, upload state, or mutable client profile.
struct ClientDocumentContext: Codable, Equatable {
    let purpose: ClientDocumentPurpose
    let photoDecision: ClientDocumentPhotoDecision

    var variant: ClientDocumentVariant {
        switch photoDecision {
        case .notSelected, .declined: .dataInformation
        case .undecided, .authorized: .informationWithPhoto
        }
    }
}
