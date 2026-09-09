import Foundation

extension ClientError {
    /// Resolves finite local failures into actionable form copy without exposing provider details.
    var clientFormMessage: LocalizedStringResource {
        switch self {
        case .invalidDisplayName: .clientsFormErrorName
        case .alreadyExists: .clientsFormErrorExists
        case .notFound: .clientsFormErrorMissing
        case .deactivated: .clientsFormErrorDeactivated
        case .conflict: .clientsFormErrorConflict
        case .persistenceUnavailable: .clientsFormErrorUnavailable
        }
    }
}

extension ClientFormViewModel.State {
    var formError: ClientError? {
        guard case .failed(_, let error) = self else { return nil }
        return error
    }

    var progressMessage: LocalizedStringResource? {
        switch self {
        case .saving: .clientsFormSaving
        case .deactivating: .clientsFormDeactivating
        default: nil
        }
    }
}
