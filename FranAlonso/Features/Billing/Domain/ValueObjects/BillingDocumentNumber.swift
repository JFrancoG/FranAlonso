import Foundation

/// A violation of a billing document's definitive sequence number.
enum BillingDocumentNumberError: Error, Equatable {
    /// Definitive sequence values start at one.
    case nonPositiveValue
}

/// An independently allocated fiscal sequence for one billing document family.
enum BillingDocumentSeries: String, Codable, Hashable {
    /// The sequence reserved for tickets.
    case ticket

    /// The sequence reserved for invoices.
    case invoice
}

/// The commercial family of a billing document.
enum BillingDocumentKind: String, Codable, Equatable {
    case ticket
    case invoice

    /// The independent fiscal series that numbers this document family.
    var series: BillingDocumentSeries {
        switch self {
        case .ticket:
            .ticket
        case .invoice:
            .invoice
        }
    }
}

/// A positive definitive value within one independently allocated fiscal series.
///
/// This value records an allocation made by the remote authority; it does not
/// expose local increment or reservation behavior.
struct BillingDocumentNumber: Codable, Hashable {
    let series: BillingDocumentSeries
    private let storedValue: Int

    var value: Int {
        storedValue
    }

    private enum CodingKeys: String, CodingKey {
        case series
        case value
    }
}

extension BillingDocumentNumber {
    /// Creates a definitive number already allocated within a fiscal series.
    ///
    /// - Parameters:
    ///   - series: The independently allocated ticket or invoice series.
    ///   - value: The positive value returned by the numbering authority.
    /// - Throws: `BillingDocumentNumberError.nonPositiveValue` when `value` is
    ///   zero or negative.
    init(series: BillingDocumentSeries, value: Int) throws {
        guard value > 0 else { throw BillingDocumentNumberError.nonPositiveValue }

        self.init(series: series, storedValue: value)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            series: container.decode(BillingDocumentSeries.self, forKey: .series),
            value: container.decode(Int.self, forKey: .value)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(series, forKey: .series)
        try container.encode(value, forKey: .value)
    }
}
