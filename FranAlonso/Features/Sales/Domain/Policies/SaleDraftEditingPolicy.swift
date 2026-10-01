/// Produces editable draft candidates while preserving captured commercial terms and line order.
///
/// Candidates remain pure Domain values. Local acceptance and monetary calculation belong to their callers.
struct SaleDraftEditingPolicy {
    /// Appends a captured line without merging repeated services or replacing existing identities.
    /// - Throws: `SaleDraftError.requiresDraft` or `SaleError.invalidDraftState` for invalid draft content.
    func adding(_ line: SaleLine, to draft: Sale) throws -> Sale {
        try draft.replacingDraft(clientID: draft.clientID, lines: draft.lines + [line])
    }

    /// Removes exactly one line identity; an absent identity is rejected rather than silently ignored.
    /// - Throws: `SaleError.lineNotFound` or `SaleDraftError.requiresDraft`.
    func removing(id: SaleLineID, from draft: Sale) throws -> Sale {
        let index = try lineIndex(id: id, in: draft)
        var lines = draft.lines
        lines.remove(at: index)
        return try draft.replacingDraft(clientID: draft.clientID, lines: lines)
    }

    /// Changes a strictly positive quantity without refreshing the line's service snapshot.
    /// - Throws: `SaleLineError.invalidQuantity`, `SaleError.lineNotFound` or `SaleDraftError.requiresDraft`.
    func settingQuantity(_ quantity: Int, for id: SaleLineID, in draft: Sale) throws -> Sale {
        let index = try lineIndex(id: id, in: draft)
        let line = draft.lines[index]
        return try replacing(
            line,
            at: index,
            in: draft,
            quantity: quantity,
            discount: line.discount
        )
    }

    /// Associates or removes a client while retaining all captured line terms.
    /// - Throws: `SaleDraftError.requiresDraft` if the sale has progressed.
    func settingClient(_ id: ClientID?, in draft: Sale) throws -> Sale {
        try draft.replacingDraft(clientID: id, lines: draft.lines)
    }

    /// Sets or removes a validated line discount without refreshing its service snapshot.
    /// - Throws: `SaleError.lineNotFound` or `SaleDraftError.requiresDraft`.
    func settingDiscount(_ discount: Discount?, for id: SaleLineID, in draft: Sale) throws -> Sale {
        let index = try lineIndex(id: id, in: draft)
        let line = draft.lines[index]
        return try replacing(
            line,
            at: index,
            in: draft,
            quantity: line.quantity,
            discount: discount
        )
    }

    private func lineIndex(id: SaleLineID, in draft: Sale) throws -> Int {
        guard draft.status == .draft else { throw SaleDraftError.requiresDraft }
        guard let index = draft.lines.firstIndex(where: { $0.id == id }) else { throw SaleError.lineNotFound }
        return index
    }

    private func replacing(
        _ line: SaleLine,
        at index: Int,
        in draft: Sale,
        quantity: Int,
        discount: Discount?
    ) throws -> Sale {
        var lines = draft.lines
        lines[index] = try SaleLine.upcoming(
            id: line.id,
            serviceID: line.serviceID,
            serviceName: line.serviceName,
            quantity: quantity,
            unitPrice: line.unitPrice,
            taxRate: line.taxRate,
            discount: discount,
            linkedProductID: line.linkedProductID
        )
        return try draft.replacingDraft(clientID: draft.clientID, lines: lines)
    }
}
