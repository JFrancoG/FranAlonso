import Foundation
import PDFKit
import Testing
@testable import FranAlonso

@Suite("Signed client document pipeline")
struct ClientSignedDocumentTests {
    @Test(arguments: [ClientDocumentPhotoDecision.notSelected, .authorized])
    func `PDF contains the complete presented text and the signing identity`(
        decision: ClientDocumentPhotoDecision
    ) async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot(decision: decision)
        let signed = try await ClientDocumentTestFixtures.render(snapshot)
        Attachment.record(signed.fields.pdf, named: "initial-\(decision.rawValue).pdf")
        let pdf = try #require(PDFDocument(data: signed.fields.pdf))
        let extracted = normalize(try #require(pdf.string))
        let content = snapshot.fields.content.fields
        for section in content.sections {
            #expect(extracted.contains(normalize(section.body)))
        }
        #expect(extracted.contains(normalize(content.signatureNotice)))
        #expect(extracted.contains("Cliente sintético Álvarez"))
        #expect(extracted.contains("00000000-0000-0000-0000-000000000085"))
        #expect(extracted.contains("00000000-0000-0000-0000-000000000014"))
        #expect(extracted.contains("2027-01-15"))
        if let photo = content.photoAuthorization {
            #expect(extracted.contains(normalize(photo)))
            #expect(extracted.contains("Autorización concedida"))
        } else {
            #expect(!extracted.lowercased().contains("fotograf"))
        }
        let page = try #require(pdf.page(at: 0))
        #expect(abs(page.bounds(for: .mediaBox).width - 595.28) < 0.1)
        #expect(abs(page.bounds(for: .mediaBox).height - 841.89) < 0.1)
    }

    @Test
    func `long Unicode content flows through multiple pages without loss`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot(longText: true)
        let signed = try await ClientDocumentTestFixtures.render(snapshot)
        Attachment.record(signed.fields.pdf, named: "long-unicode.pdf")
        let pdf = try #require(PDFDocument(data: signed.fields.pdf))
        #expect(pdf.pageCount > 2)
        let text = normalize(try #require(pdf.string))
        for index in 1...80 {
            #expect(text.contains("Párrafo \(index): acción, pingüino, información y conservación."))
        }
        #expect(text.contains("Firma del cliente"))
    }

    @Test
    func `later authorization is identified separately in the artifact`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot(
            decision: .authorized,
            purpose: .subsequentPhotoAuthorization
        )
        let signed = try await ClientDocumentTestFixtures.render(snapshot)
        Attachment.record(signed.fields.pdf, named: "subsequent-photo.pdf")
        let text = try #require(PDFDocument(data: signed.fields.pdf)?.string)
        #expect(text.contains("Autorización fotográfica posterior"))
        #expect(!text.contains("Información inicial firmada"))
    }

    @Test
    func `serialized history keeps exact PDF bytes and text without the current catalog`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let original = try await ClientDocumentTestFixtures.render(snapshot)
        let encoded = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(ClientSignedDocument.self, from: encoded)
        #expect(restored.fields.pdf == original.fields.pdf)
        #expect(PDFDocument(data: restored.fields.pdf)?.string?.contains("2026-09-10-draft") == true)
        #expect(restored.fields.binding == original.fields.binding)
    }

    @Test
    func `a changed presented client name cannot reuse the old ink`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let old = snapshot.fields
        let changed = try ClientDocumentSnapshot(.init(
            id: old.id,
            clientID: old.clientID,
            clientName: "Otra persona sintética",
            context: old.context,
            content: old.content
        ))
        await #expect(throws: ClientDocumentError.staleSignature) {
            try await RenderConsentUseCase(renderer: CoreGraphicsClientDocumentRenderer(), now: { Date() })(
                snapshot: changed,
                binding: ClientDocumentTestFixtures.binding(snapshot)
            )
        }
    }

    private func normalize(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
