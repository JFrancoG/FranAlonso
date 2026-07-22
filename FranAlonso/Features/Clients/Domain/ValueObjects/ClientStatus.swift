enum ClientStatus: Codable, Equatable {
    case draft
    case consentPendingUpload
    case active(consentReference: ClientConsentReference)
}
