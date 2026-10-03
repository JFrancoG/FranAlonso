import Foundation

/// Geometry of the captured 13.6 Spanish A4 templates, in bottom-left PDF points.
/// Row counts exclude the header; dynamic fields are inset from the existing grid.
struct BillingDocumentPDFGeometry {
    let kind: BillingDocumentKind

    var rowCount: Int { kind == .ticket ? 11 : 9 }
    var rowHeight: Double { kind == .ticket ? 25 : 24 }
    var tableTop: Double { kind == .ticket ? 563 : 482 }
    var columns: [Double] {
        kind == .ticket ? [38, 82, 427, 507, 595] : [38, 73, 338, 406, 460, 515, 595]
    }

    func cell(column: Int, row: Int) throws -> BillingPDFRectangle {
        try rectangle(
            x: columns[column] + 3,
            y: tableTop - Double(row + 1) * rowHeight + 3,
            width: columns[column + 1] - columns[column] - 6,
            height: rowHeight - 6
        )
    }

    func rectangle(
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) throws -> BillingPDFRectangle {
        try BillingPDFRectangle(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    func number() throws -> BillingPDFRectangle {
        try rectangle(
            x: 41,
            y: 642,
            width: 136,
            height: 16
        )
    }

    func date() throws -> BillingPDFRectangle {
        try rectangle(
            x: 208,
            y: 642,
            width: 136,
            height: 16
        )
    }

    func signature() throws -> BillingPDFRectangle {
        try rectangle(
            x: 42,
            y: 66,
            width: 212,
            height: kind == .ticket ? 88 : 70
        )
    }
}
