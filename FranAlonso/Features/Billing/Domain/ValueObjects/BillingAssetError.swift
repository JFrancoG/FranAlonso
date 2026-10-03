/// Recoverable asset failures, without exposing private paths or infrastructure payloads.
enum BillingAssetError: Error, Equatable {
    case templateUnavailable
    case invalidTemplate
    case signatureUnavailable
    case invalidSignature
    case unauthorized
}
