import Foundation

/// One ordered page with at least one positioned content field.
struct BillingPDFPage: Equatable {
    private let storedFields: [BillingPDFTextField]

    var fields: [BillingPDFTextField] { storedFields }
}

extension BillingPDFPage {
    /// Rejects empty pages and pages exceeding the 200-field render budget.
    init(fields: [BillingPDFTextField]) throws {
        guard !fields.isEmpty else { throw BillingPDFRenderError.missingContent }
        guard fields.count <= 200 else { throw BillingPDFRenderError.limitExceeded }

        self.init(storedFields: fields)
    }
}

/// An optional captured private image, placed proportionally on the final page only.
///
/// Resource authentication and protection belong to the asset repository; Data validates image bytes.
struct BillingPDFSignature: Equatable {
    let data: Data
    let frame: BillingPDFRectangle
}
