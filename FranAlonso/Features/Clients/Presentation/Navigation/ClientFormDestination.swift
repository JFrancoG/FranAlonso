import Foundation

/// Identifies one form session separately from the stable client being created or edited.
/// Reopening the same client creates a new session, so an older dismissal cannot close it.
struct ClientFormDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: UUID
    let clientID: ClientID
    let mode: Mode
}
