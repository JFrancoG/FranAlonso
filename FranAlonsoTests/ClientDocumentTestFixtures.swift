import Foundation
@testable import FranAlonso

struct ClientDocumentTestFixtures {
    static let documentID = UUID(uuidString: "00000000-0000-0000-0000-000000000085")!
    static let clientID = ClientID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!)
    static let date = Date(timeIntervalSince1970: 1_800_000_000)

    static func snapshot(
        decision: ClientDocumentPhotoDecision = .notSelected,
        purpose: ClientDocumentPurpose = .initialInformation,
        longText: Bool = false
    ) async throws -> ClientDocumentSnapshot {
        let snapshot = try await PrepareClientDocumentUseCase(
            catalog: BundleClientDocumentCatalog(bundle: .main),
            newID: { documentID }
        )(
            clientID: clientID,
            clientName: "Cliente sintético Álvarez",
            context: .init(purpose: purpose, photoDecision: decision),
            version: "2026-09-10-draft",
            language: "es"
        )
        guard longText else { return snapshot }
        let fields = snapshot.fields
        let content = fields.content.fields
        let paragraphs = (1...80).map { index in
            ClientDocumentContent.Section(
                heading: "Sección sintética \(index)",
                body: "Párrafo \(index): acción, pingüino, información y conservación. " +
                    String(repeating: "Texto de prueba de continuidad y paginación. ", count: 8)
            )
        }
        return try ClientDocumentSnapshot(.init(
            id: fields.id,
            clientID: fields.clientID,
            clientName: fields.clientName,
            context: fields.context,
            content: ClientDocumentContent(.init(
                version: content.version,
                language: content.language,
                title: content.title,
                reviewNotice: content.reviewNotice,
                sections: paragraphs,
                photoAuthorization: content.photoAuthorization,
                signatureNotice: content.signatureNotice,
                labels: content.labels
            ))
        ))
    }

    static func binding(_ snapshot: ClientDocumentSnapshot) throws -> ClientDocumentSignature {
        try ClientDocumentSignature(
            snapshot: snapshot,
            signature: ClientSignature(strokes: [
                [.init(x: 0.1, y: 0.7), .init(x: 0.4, y: 0.1), .init(x: 0.7, y: 0.8)],
                [.init(x: 0.2, y: 0.9), .init(x: 0.9, y: 0.4)]
            ])
        )
    }

    static func render(_ snapshot: ClientDocumentSnapshot) async throws -> ClientSignedDocument {
        try await RenderConsentUseCase(renderer: CoreGraphicsClientDocumentRenderer(), now: { date })(
            snapshot: snapshot,
            binding: binding(snapshot)
        )
    }
}
