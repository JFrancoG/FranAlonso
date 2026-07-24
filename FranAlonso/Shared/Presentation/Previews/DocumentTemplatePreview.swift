#if DEBUG
import PDFKit
import SwiftUI

@MainActor
private struct DocumentTemplatePDFPreview: UIViewRepresentable {
    let resource: DocumentTemplateResource

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemGroupedBackground
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = resource.url(in: .main).flatMap(PDFDocument.init(url:))
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = resource.url(in: .main).flatMap(PDFDocument.init(url:))
    }
}

#Preview("Consentimiento", traits: .modifier(AppPreviewModifier())) {
    DocumentTemplatePDFPreview(resource: .clientConsent)
}

#Preview("Ticket A4", traits: .modifier(AppPreviewModifier())) {
    DocumentTemplatePDFPreview(resource: .billingTicketA4)
}

#Preview("Factura A4", traits: .modifier(AppPreviewModifier())) {
    DocumentTemplatePDFPreview(resource: .billingInvoiceA4)
}
#endif
