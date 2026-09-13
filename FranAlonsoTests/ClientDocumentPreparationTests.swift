import Foundation
import Testing
@testable import FranAlonso

@Suite("Versioned client document preparation")
struct ClientDocumentPreparationTests {
    @Test(arguments: [ClientDocumentPhotoDecision.notSelected, .declined])
    func `no photo and rejected photo omit image authorization`(decision: ClientDocumentPhotoDecision) async throws {
        let snapshot = try await prepare(decision: decision)
        let text = snapshot.fields.content.fields.sections.map(\.body).joined(separator: " ").lowercased()
        #expect(!text.contains("fotograf"))
        #expect(!text.contains("imagen"))
        #expect(snapshot.fields.content.fields.photoAuthorization == nil)
        #expect(snapshot.fields.content.fields.signatureNotice.contains("recibido la información"))
    }

    @Test
    func `selected photo remains unsigned until an explicit decision`() async throws {
        let pending = try await prepare(decision: .undecided)
        #expect(pending.fields.content.fields.photoAuthorization?.contains("no incluye su publicación") == true)
        #expect(throws: ClientDocumentError.photoDecisionRequired) {
            try ClientDocumentSignature(snapshot: pending, signature: ink())
        }
        let authorized = try await prepare(decision: .authorized)
        _ = try ClientDocumentSignature(snapshot: authorized, signature: ink())
    }

    @Test(arguments: ["en", "es-MX"])
    func `unsupported language never silently falls back to Spanish`(language: String) async {
        await #expect(throws: ClientDocumentError.unsupportedLanguage) {
            try await prepare(decision: .notSelected, language: language)
        }
    }

    @Test
    func `unavailable historical version is not replaced by current text`() async {
        await #expect(throws: ClientDocumentError.unsupportedVersion) {
            try await prepare(decision: .notSelected, version: "missing-version")
        }
    }

    @Test(arguments: [false, true])
    func `incomplete bundle cannot produce a partial legal document`(includeManifest: Bool) async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(
            at: directory.appending(path: "es.lproj"),
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        if includeManifest {
            let source = try #require(Bundle.main.url(forResource: "document-template-content", withExtension: "json"))
            try FileManager.default.copyItem(at: source, to: directory.appending(path: "document-template-content.json"))
        }
        let bundle = try #require(Bundle(url: directory))
        await #expect(throws: includeManifest ? ClientDocumentError.invalidContent : .unavailableCatalog) {
            try await BundleClientDocumentCatalog(bundle: bundle).content(
                variant: .dataInformation,
                version: "2026-09-10-draft",
                language: "es"
            )
        }
    }

    private func prepare(
        decision: ClientDocumentPhotoDecision,
        language: String = "es",
        version: String = "2026-09-10-draft"
    ) async throws -> ClientDocumentSnapshot {
        try await PrepareClientDocumentUseCase(
            catalog: BundleClientDocumentCatalog(bundle: .main),
            newID: { UUID(uuidString: "00000000-0000-0000-0000-000000000085")! }
        )(
            clientID: ClientID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!),
            clientName: "Cliente sintético Álvarez",
            context: .init(purpose: .initialInformation, photoDecision: decision),
            version: version,
            language: language
        )
    }

    private func ink() throws -> ClientSignature {
        try ClientSignature(strokes: [[.init(x: 0, y: 0), .init(x: 1, y: 1)]])
    }
}
