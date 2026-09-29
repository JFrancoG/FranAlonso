import Foundation

extension ProductError {
    /// Resolves local failures into actionable copy without exposing provider details or product payloads.
    var productFormMessage: LocalizedStringResource {
        switch self {
        case .invalidName: .productsFormErrorName
        case .alreadyExists: .productsFormErrorExists
        case .notFound, .deleted: .productsFormErrorMissing
        case .conflict: .productsFormErrorConflict
        case .persistenceUnavailable: .productsFormErrorUnavailable
        }
    }
}

extension ProductFormViewModel.State {
    var formError: ProductError? {
        guard case .failed(_, let error) = self else { return nil }
        return error
    }

    var progressMessage: LocalizedStringResource? {
        switch self {
        case .saving: .productsFormSaving
        case .deactivating: .productsFormDeactivating
        default: nil
        }
    }
}
