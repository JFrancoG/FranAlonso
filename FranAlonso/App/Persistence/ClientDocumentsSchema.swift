import SwiftData

/// The additive document-storage schema. The supported 1.0.0 model shapes remain untouched.
struct ClientDocumentsSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        PhaseFiveBaselineSchema.models + [ClientDocumentDraftModel.self, ClientSignedDocumentModel.self]
    }
}
