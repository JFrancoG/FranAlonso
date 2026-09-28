import Foundation
import SwiftData

/// Resolves document capabilities for one container and the currently authorized application session.
@MainActor
final class ClientDocumentComposition {
    weak var authenticationRoot: AuthenticationRootViewModel?
    private let persistence: ClientDocumentPersistenceActor
    private let observationSignal: ClientObservationSignal
    private let catalog = BundleClientDocumentCatalog(bundle: .main)
    private let renderer = CoreGraphicsClientDocumentRenderer()

    init(modelContainer: ModelContainer, observationSignal: ClientObservationSignal) {
        persistence = ClientDocumentPersistenceActor(modelContainer: modelContainer)
        self.observationSignal = observationSignal
    }

    /// Binds a new form to current authority while all forms share the same serialization owner.
    func makeRepository() throws -> DefaultClientDocumentRepository {
        guard let authenticationRoot else { throw ClientDocumentAccessError.sessionExpired }
        return try DefaultClientDocumentRepository(
            persistence: persistence,
            access: authenticationRoot.makeClientDocumentAccess(),
            observationSignal: observationSignal
        )
    }

    /// Uses the supported Spanish catalog and local rendering; remote delivery stays unavailable.
    /// Creating this capability never starts a render, write or network operation.
    func makeServices() throws -> ClientConsentServices {
        try ClientConsentServices(
            repository: makeRepository(),
            catalog: catalog,
            renderer: renderer,
            storage: UnavailableClientDocumentStorage(),
            version: "2026-09-10-draft",
            language: "es",
            now: { .now },
            newID: { UUID() }
        )
    }
}

/// Keeps normal composition recoverable without claiming remote acceptance before the live gate.
private struct UnavailableClientDocumentStorage: ClientDocumentStorage {
    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt {
        try Task.checkCancellation()
        throw ClientDocumentStorageError.unavailable
    }
}
