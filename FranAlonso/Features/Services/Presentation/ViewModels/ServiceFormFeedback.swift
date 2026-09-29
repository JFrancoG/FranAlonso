import Foundation

/// Fields that can receive focus after an explicit, unsuccessful save attempt.
enum ServiceFormValidationField: Hashable {
    case name, price, tax, discount
}

extension ServiceFormError {
    /// Resolves local failures into actionable copy without provider details or stored payloads.
    var serviceFormMessage: LocalizedStringResource {
        switch self {
        case .invalidPriceInput, .service(.invalidPrice): .servicesFormErrorPrice
        case .invalidTaxInput: .servicesFormErrorTax
        case .invalidDiscountInput: .servicesFormErrorDiscount
        case .service(.invalidName): .servicesFormErrorName
        case .service(.alreadyExists): .servicesFormErrorExists
        case .service(.notFound), .service(.deleted): .servicesFormErrorMissing
        case .service(.conflict): .servicesFormErrorConflict
        case .service(.persistenceUnavailable): .servicesFormErrorUnavailable
        case .service(.linkedProductUnavailable): .servicesFormErrorLinkedProductUnavailable
        case .service(.linkedProductRequired), .service(.linkedProductNotAllowed): .servicesFormErrorLinkedProduct
        }
    }

    /// Keeps input errors next to their field; persistence and historical-link failures stay general.
    var validationField: ServiceFormValidationField? {
        switch self {
        case .service(.invalidName): .name
        case .invalidPriceInput, .service(.invalidPrice): .price
        case .invalidTaxInput: .tax
        case .invalidDiscountInput: .discount
        default: nil
        }
    }
}

extension ServiceFormViewModel.State {
    var formError: ServiceFormError? {
        guard case .failed(_, let error) = self else { return nil }
        return error
    }

    var progressMessage: LocalizedStringResource? {
        switch self {
        case .saving: .servicesFormSaving
        case .deactivating: .servicesFormDeactivating
        default: nil
        }
    }
}
