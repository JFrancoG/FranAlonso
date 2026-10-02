/// A single service-work intention; commercial terms and payment metadata are never replaced.
enum SaleProgressAction: Codable, Equatable {
    case start
    case startLine(SaleLineID)
    case completeLine(SaleLineID)

    /// Applies the aggregate's existing lifecycle invariants to a detached snapshot.
    /// - Throws: Sale or line transition errors; no persistence is performed.
    func applying(to sale: Sale) throws -> Sale {
        var candidate = sale
        switch self {
        case .start: try candidate.start()
        case let .startLine(id): try candidate.startLine(id: id)
        case let .completeLine(id): try candidate.completeLine(id: id)
        }
        return candidate
    }
}
