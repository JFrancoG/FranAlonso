import PDFKit
import Testing
@testable import FranAlonso

@Suite("Document template resources")
struct DocumentTemplateResourceTests {
    @Test("Required semantic PDF names remain stable")
    func requiredSemanticPDFNamesRemainStable() {
        #expect(
            Set(DocumentTemplateResource.allCases.map(\.rawValue)) == [
                "client-consent-template",
                "billing-ticket-a4-template",
                "billing-invoice-a4-template"
            ]
        )
    }

    @Test(
        "Every required template loads as one A4 page",
        arguments: DocumentTemplateResource.allCases
    )
    func everyRequiredTemplateLoadsAsOneA4Page(
        resource: DocumentTemplateResource
    ) throws {
        let url = try #require(resource.url(in: .main))
        let document = try #require(PDFDocument(url: url))
        let page = try #require(document.page(at: 0))
        let pageBounds = page.bounds(for: .mediaBox)

        #expect(document.pageCount == 1)
        #expect(abs(pageBounds.width - 595.28) < 0.5)
        #expect(abs(pageBounds.height - 841.89) < 0.5)
    }
}
