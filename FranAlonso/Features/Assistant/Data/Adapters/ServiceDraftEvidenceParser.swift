import Foundation

/// Verifies source provenance and a deliberately narrow commercial grammar before proposing values.
///
/// Evidence must be a complete literal span with its own field label and unit. Decimal parsing rejects
/// grouping, prefixes, exponents and representational loss; prices additionally reject minor-unit rounding.
struct ServiceDraftEvidenceParser {
    let source: String
    let locale: Locale

    func name(_ evidence: String) throws -> String {
        let name = evidence.trimmingCharacters(in: .whitespacesAndNewlines)
        try requireLiteralSpan(name)
        return name
    }

    func price(_ evidence: String) throws -> Money {
        try requireLiteralSpan(evidence)
        let input = try removingLabel(from: evidence, labels: ["precio", "price"])
        let currencies: [(String, Currency)] = [
            ("euros", .eur), ("euro", .eur), ("EUR", .eur), ("€", .eur), ("USD", .usd)
        ]
        for (suffix, currency) in currencies where input.lowercased().hasSuffix(suffix.lowercased()) {
            let number = String(input.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            let amount = try decimal(number)
            guard amount >= 0 else { throw ServiceDraftAssistantError.clarification }
            let price = try Money(amount: amount, currency: currency)
            guard price.amount == amount else { throw ServiceDraftAssistantError.clarification }
            return price
        }
        throw ServiceDraftAssistantError.clarification
    }

    func taxRate(_ evidence: String) throws -> TaxRate {
        try TaxRate(percentage: percentage(evidence, labels: ["IVA", "impuesto", "tax", "VAT"]))
    }

    func discount(_ evidence: String) throws -> Discount {
        try Discount(percentage: percentage(evidence, labels: ["descuento", "discount"]))
    }
}

private extension ServiceDraftEvidenceParser {
    func percentage(_ evidence: String, labels: [String]) throws -> Decimal {
        try requireLiteralSpan(evidence)
        let input = try removingLabel(from: evidence, labels: labels)
        guard input.hasSuffix("%") else { throw ServiceDraftAssistantError.clarification }
        return try decimal(String(input.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func removingLabel(from evidence: String, labels: [String]) throws -> String {
        let input = evidence.trimmingCharacters(in: .whitespacesAndNewlines)
        for label in labels where input.lowercased().hasPrefix(label.lowercased()) {
            var remainder = String(input.dropFirst(label.count))
            guard let separator = remainder.first, separator.isWhitespace || separator == ":" else {
                throw ServiceDraftAssistantError.clarification
            }
            remainder = remainder.trimmingCharacters(in: .whitespacesAndNewlines)
            if remainder.first == ":" {
                remainder.removeFirst()
            }
            return remainder.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw ServiceDraftAssistantError.clarification
    }

    func requireLiteralSpan(_ evidence: String) throws {
        guard !evidence.isEmpty else { throw ServiceDraftAssistantError.clarification }
        var searchRange = source.startIndex..<source.endIndex
        while let range = source.range(of: evidence, options: .literal, range: searchRange) {
            let startsAtBoundary = range.lowerBound == source.startIndex
                || !isWordCharacter(source[source.index(before: range.lowerBound)])
            let endsAtBoundary = range.upperBound == source.endIndex
                || !isWordCharacter(source[range.upperBound])
            if startsAtBoundary && endsAtBoundary {
                return
            }
            searchRange = range.upperBound..<source.endIndex
        }
        throw ServiceDraftAssistantError.clarification
    }

    func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }

    func decimal(_ input: String) throws -> Decimal {
        var magnitude = input
        let isNegative = magnitude.first == "-"
        if isNegative {
            magnitude.removeFirst()
        }
        let parts = magnitude.components(separatedBy: locale.decimalSeparator ?? ".")
        guard (1...2).contains(parts.count), parts.allSatisfy(containsOnlyDigits) else {
            throw ServiceDraftAssistantError.clarification
        }

        let integerDigits = parts[0].drop(while: { $0 == "0" })
        let integer = integerDigits.isEmpty ? "0" : String(integerDigits)
        var fraction = parts.count == 2 ? parts[1] : ""
        while fraction.last == "0" {
            fraction.removeLast()
        }
        let sign = isNegative && (integer != "0" || !fraction.isEmpty) ? "-" : ""
        let canonical = sign + integer + (fraction.isEmpty ? "" : "." + fraction)
        let exactLocale = Locale(identifier: "en_US_POSIX")
        guard let value = Decimal(string: canonical, locale: exactLocale), !value.isNaN else {
            throw ServiceDraftAssistantError.clarification
        }
        let represented = value.formatted(
            .number.locale(exactLocale).grouping(.never).precision(.significantDigits(1...38))
        )
        guard represented == canonical else { throw ServiceDraftAssistantError.clarification }
        return value
    }

    func containsOnlyDigits(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
    }
}
