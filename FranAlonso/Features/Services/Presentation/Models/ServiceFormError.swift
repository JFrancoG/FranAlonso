/// Semantic form failures kept separate from the localized messages shown by a screen.
enum ServiceFormError: Error, Equatable {
    case invalidPriceInput
    case invalidTaxInput
    case invalidDiscountInput
    case service(ServiceError)

    /// Whether editing the draft can resolve this failure without retrying persistence.
    var isLocalValidation: Bool {
        switch self {
        case .invalidPriceInput, .invalidTaxInput, .invalidDiscountInput:
            true
        case .service(let error):
            switch error {
            case .invalidName, .invalidPrice, .linkedProductRequired, .linkedProductNotAllowed:
                true
            case .alreadyExists, .notFound, .deleted, .conflict, .persistenceUnavailable, .linkedProductUnavailable:
                false
            }
        }
    }
}
