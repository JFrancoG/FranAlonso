import Foundation

/// Keeps form session identity separate from the stable identity of its commercial service.
struct ServiceFormDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: UUID
    let serviceID: ServiceID
    let mode: Mode
}
