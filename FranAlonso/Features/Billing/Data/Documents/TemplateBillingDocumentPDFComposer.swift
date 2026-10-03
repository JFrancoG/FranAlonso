import Foundation

/// Composes complete confirmed snapshots for the captured Spanish/EUR A4 backgrounds.
/// All measurement and pagination are actor-isolated; no profile, catalog or network is consulted.
actor TemplateBillingDocumentPDFComposer: BillingDocumentPDFComposer {
    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func compose(
        _ projection: BillingDocumentProjection,
        template: Data,
        signature: Data?
    ) async throws -> BillingPDFRenderRequest {
        try Task.checkCancellation()
        try BillingPDFTemplateValidator.validate(template)
        let geometry = BillingDocumentPDFGeometry(kind: projection.document.kind)
        let text = BillingDocumentPDFText(bundle: bundle)
        let fiscal = projection.document.request.fiscalRecipient
        let sourceUnits = projection.document.request.sale.lines.reduce(0) { $0 + $1.serviceName.utf16.count }
            + (fiscal.map { recipient in
                BillingFiscalField.allCases.reduce(0) { $0 + recipient.input[$1].utf16.count }
            } ?? 0)
        guard sourceUnits <= 200_000 else { throw BillingPDFRenderError.limitExceeded }
        let rows = try tableRows(projection, geometry: geometry, text: text)
        guard !rows.isEmpty else { throw BillingPDFRenderError.missingContent }
        let pageCount = (rows.count + geometry.rowCount - 1) / geometry.rowCount
        var pages: [BillingPDFPage] = []
        for index in 0..<pageCount {
            try Task.checkCancellation()
            var fields = try fiscalFields(fiscal, geometry: geometry)
            let first = index * geometry.rowCount
            let end = min(first + geometry.rowCount, rows.count)
            for (row, values) in rows[first..<end].enumerated() {
                for (column, value) in values.enumerated() {
                    guard let value else { continue }
                    fields.append(try field(value, in: geometry.cell(column: column, row: row), size: 8))
                }
            }
            if index == pageCount - 1 {
                fields += try finalTotals(projection.calculation, geometry: geometry, text: text)
            } else {
                fields.append(try field(
                    text.label(.continuation),
                    in: geometry.rectangle(
                        x: 41,
                        y: 205,
                        width: 330,
                        height: 38
                    )
                ))
            }
            fields.append(try field(
                "\(text.label(.page)) \(index + 1)/\(pageCount)",
                in: geometry.rectangle(
                    x: 41,
                    y: 38,
                    width: 510,
                    height: 16
                )
            ))
            pages.append(try BillingPDFPage(fields: fields))
        }
        let title: String
        switch projection.document.kind {
        case .ticket:
            title = String(
                localized: "ticket.metadata.title",
                table: "DocumentTemplates",
                bundle: bundle,
                locale: Locale(identifier: "es")
            )
        case .invoice:
            title = String(
                localized: "invoice.metadata.title",
                table: "DocumentTemplates",
                bundle: bundle,
                locale: Locale(identifier: "es")
            )
        }
        let image = try signature.map { BillingPDFSignature(data: $0, frame: try geometry.signature()) }
        let request = try BillingPDFRenderRequest(
            document: projection.document,
            template: template,
            title: title,
            numberFrame: geometry.number(),
            dateFrame: geometry.date(),
            pages: pages,
            signature: image
        )
        try Task.checkCancellation()
        return request
    }
}

private extension TemplateBillingDocumentPDFComposer {
    func tableRows(
        _ projection: BillingDocumentProjection,
        geometry: BillingDocumentPDFGeometry,
        text: BillingDocumentPDFText
    ) throws -> [[String?]] {
        var rows: [[String?]] = []
        let sale = projection.document.request.sale
        for (index, pair) in zip(sale.lines, projection.calculation.lineCalculations).enumerated() {
            try Task.checkCancellation()
            let (line, calculation) = pair
            let description = text.description(
                line: line,
                calculation: calculation,
                global: sale.globalDiscount,
                index: index
            )
            let chunks = try BillingPDFTextLayout.chunks(description, in: geometry.cell(column: 1, row: 0))
            for (part, chunk) in chunks.enumerated() {
                guard rows.count < geometry.rowCount * 100 else { throw BillingPDFRenderError.limitExceeded }
                var values: [String?] = Array(repeating: nil, count: geometry.columns.count - 1)
                values[1] = chunk
                if part == 0 {
                    values[0] = String(line.quantity)
                    if geometry.kind == .invoice {
                        values[2] = text.money(line.unitPrice)
                        values[3] = text.money(calculation.discountAmount)
                        values[4] = text.money(calculation.taxAmount)
                        values[5] = text.money(calculation.total)
                    } else {
                        values[2] = text.money(calculation.taxAmount)
                        values[3] = text.money(calculation.total)
                    }
                }
                rows.append(values)
            }
        }
        return rows
    }

    func fiscalFields(
        _ recipient: BillingFiscalRecipient?,
        geometry: BillingDocumentPDFGeometry
    ) throws -> [BillingPDFTextField] {
        guard geometry.kind == .invoice, let recipient else { return [] }
        let input = recipient.input
        return [
            try field(
                input.displayName,
                in: geometry.rectangle(
                    x: 41,
                    y: 587,
                    width: 306,
                    height: 18
                )
            ),
            try field(
                input.taxIdentifier,
                in: geometry.rectangle(
                    x: 375,
                    y: 587,
                    width: 179,
                    height: 18
                )
            ),
            try field(
                input.streetLine,
                in: geometry.rectangle(
                    x: 41,
                    y: 553,
                    width: 513,
                    height: 18
                )
            ),
            try field(
                input.postalCode + " " + input.city,
                in: geometry.rectangle(
                    x: 41,
                    y: 518,
                    width: 246,
                    height: 18
                )
            ),
            try field(
                input.province,
                in: geometry.rectangle(
                    x: 315,
                    y: 518,
                    width: 239,
                    height: 18
                )
            )
        ]
    }

    func finalTotals(
        _ calculation: SaleCalculation,
        geometry: BillingDocumentPDFGeometry,
        text: BillingDocumentPDFText
    ) throws -> [BillingPDFTextField] {
        let values: [Money]
        let positions: [Double]
        if geometry.kind == .ticket {
            values = [calculation.taxableBase, calculation.taxAmount, calculation.total]
            positions = [258, 236, 214]
        } else {
            values = [calculation.taxableBase, calculation.discountAmount, calculation.taxAmount, calculation.total]
            positions = [236, 216, 196, 176]
        }
        var fields = try zip(values, positions).enumerated().map { index, pair in
            try field(
                text.money(pair.0),
                in: geometry.rectangle(
                    x: 478,
                    y: pair.1,
                    width: 76,
                    height: 16
                ),
                bold: index == values.count - 1
            )
        }
        fields.append(try field(
            text.summary(calculation),
            in: geometry.rectangle(
                x: 41,
                y: 184,
                width: 330,
                height: 70
            )
        ))
        return fields
    }

    func field(
        _ text: String,
        in rectangle: BillingPDFRectangle,
        size: Double = 9,
        bold: Bool = false
    ) throws -> BillingPDFTextField {
        let field = try BillingPDFTextField(
            text: text,
            frame: rectangle,
            fontSize: size,
            bold: bold
        )
        _ = try BillingPDFTextLayout(field: field).makeFrame()
        return field
    }
}
