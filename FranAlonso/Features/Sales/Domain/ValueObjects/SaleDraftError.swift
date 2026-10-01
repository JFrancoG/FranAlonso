/// Neutral failures of local draft acceptance, independent of persistence providers.
enum SaleDraftError: Error, Equatable {
    /// Creation cannot reuse a materialized, pending, remote, or discarded identity.
    case alreadyExists
    /// Editing requires a locally materialized sale.
    case notFound
    /// Only drafts can be recovered for editing, replaced, or discarded.
    case requiresDraft
    /// The expected snapshot differs from the locally accepted draft.
    case staleDraft
    /// An unresolved synchronization conflict blocks ordinary draft mutations.
    case conflict
    /// A discarded identity cannot be edited or implicitly restored.
    case deleted
    /// Local storage could not read or commit the requested operation.
    case persistenceUnavailable
}
