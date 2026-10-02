import Foundation

/// Converts complete localized decimal input without rounding or accepting numeric prefixes.
///
/// Input requires ASCII integer digits and, when present, fractional digits after the session's
/// decimal separator. An optional minus and exterior whitespace are accepted. Grouping, exponents,
/// other symbols and values that cannot survive an exact 38-significant-digit representation are rejected.
struct LocalizedDecimalInput {
    let locale: Locale

    func parse(_ text: String) -> Decimal? {
        var input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isNegative = input.first == "-"
        if isNegative {
            input.removeFirst()
        }

        let parts = input.components(separatedBy: locale.decimalSeparator ?? ".")
        guard (1...2).contains(parts.count), parts.allSatisfy(containsOnlyDigits) else { return nil }

        let integerDigits = parts[0].drop(while: { $0 == "0" })
        let integer = integerDigits.isEmpty ? "0" : String(integerDigits)
        var fraction = parts.count == 2 ? parts[1] : ""
        while fraction.last == "0" {
            fraction.removeLast()
        }
        let sign = isNegative && (integer != "0" || !fraction.isEmpty) ? "-" : ""
        let canonical = sign + integer + (fraction.isEmpty ? "" : "." + fraction)

        guard let value = Decimal(string: canonical, locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN, canonicalString(value) == canonical else {
            return nil
        }
        return value
    }

    /// Formats a validated Domain decimal without grouping or currency-specific rounding.
    func format(_ value: Decimal) -> String {
        canonicalString(value).replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
    }

    private func containsOnlyDigits(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
    }

    private func canonicalString(_ value: Decimal) -> String {
        value.formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.significantDigits(1...38))
        )
    }
}
