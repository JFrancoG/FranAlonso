import Foundation

/// Failures that prevent a flattened Sale snapshot from being reconstructed safely.
enum SaleModelPayloadError: Error, Equatable {
    case unsupportedLinesVersion(Int)
    case invalidLifecycleMetadata
    case invalidStatus(String)
}

extension SaleModel {
    /// Creates a flattened local representation from one validated Sale aggregate.
    ///
    /// - Parameter sale: The Domain snapshot to preserve atomically.
    /// - Throws: A DTO conversion or encoding error for untransportable values.
    convenience init(_ sale: Sale) throws {
        let dto = try SaleDTO(sale)
        let metadata = dto.status.flattenedMetadata
        self.init(
            id: sale.id.rawValue,
            clientID: sale.clientID?.rawValue,
            createdAt: dto.createdAt.date,
            createdAtCanonical: dto.createdAt.canonicalString,
            statusKindRawValue: metadata.kind,
            paymentID: metadata.paymentID,
            paymentMethodRawValue: metadata.paymentMethod,
            paidAtCanonical: metadata.paidAt,
            documentID: metadata.documentID,
            closedAtCanonical: metadata.closedAt,
            reversalID: metadata.reversalID,
            voidedAtCanonical: metadata.voidedAt,
            linesPayloadVersion: 1,
            linesData: try JSONEncoder().encode(dto.lines)
        )
    }

    /// Reconstructs Domain through the exact v1 DTO and its validating transitions.
    ///
    /// - Returns: The Sale represented by the flattened root and ordered line snapshot.
    /// - Throws: `SaleModelPayloadError` for unsupported or incoherent persisted metadata.
    func toDomain() throws -> Sale {
        guard linesPayloadVersion == 1 else {
            throw SaleModelPayloadError.unsupportedLinesVersion(linesPayloadVersion)
        }
        let lines = try JSONDecoder().decode([SaleLineDTO].self, from: linesData)
        let canonicalCreatedAt = try SaleTimestampDTO(
            canonicalString: createdAtCanonical
        )
        guard createdAt.timeIntervalSinceReferenceDate.bitPattern
                == canonicalCreatedAt.date.timeIntervalSinceReferenceDate.bitPattern else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
        let dto = SaleDTO(
            payloadVersion: SaleDTO.currentPayloadVersion,
            id: id.uuidString,
            clientID: clientID?.uuidString,
            createdAt: canonicalCreatedAt,
            lines: lines,
            status: try statusDTO()
        )
        return try dto.toDomain()
    }

    /// Replaces every persisted field with a newly validated Sale snapshot.
    ///
    /// - Parameter sale: The replacement Domain snapshot with the same stable identity.
    /// - Throws: A DTO conversion or encoding error for untransportable values.
    func update(from sale: Sale) throws {
        let replacement = try SaleModel(sale)
        clientID = replacement.clientID
        createdAt = replacement.createdAt
        createdAtCanonical = replacement.createdAtCanonical
        statusKindRawValue = replacement.statusKindRawValue
        paymentID = replacement.paymentID
        paymentMethodRawValue = replacement.paymentMethodRawValue
        paidAtCanonical = replacement.paidAtCanonical
        documentID = replacement.documentID
        closedAtCanonical = replacement.closedAtCanonical
        reversalID = replacement.reversalID
        voidedAtCanonical = replacement.voidedAtCanonical
        linesPayloadVersion = replacement.linesPayloadVersion
        linesData = replacement.linesData
    }

    private func statusDTO() throws -> SaleStatusDTO {
        switch statusKindRawValue {
        case "draft":
            try requireEmptyMetadata()
            return .draft
        case "inProgress":
            try requireEmptyMetadata()
            return .inProgress
        case "awaitingPayment":
            try requireEmptyMetadata()
            return .awaitingPayment
        case "awaitingDocument":
            try requireDocumentAndReversalAbsent()
            return .awaitingDocument(payment: try paymentDTO())
        case "closed":
            try requireReversalAbsent()
            return .closed(payment: try paymentDTO(), document: try documentDTO())
        case "voided":
            return .voided(
                payment: try paymentDTO(),
                document: try documentDTO(),
                reversal: try reversalDTO()
            )
        default:
            throw SaleModelPayloadError.invalidStatus(statusKindRawValue)
        }
    }

    private func paymentDTO() throws -> SalePaymentDTO {
        guard let paymentID,
              let paymentMethodRawValue,
              let method = SalePaymentMethodDTO(rawValue: paymentMethodRawValue),
              let paidAtCanonical else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
        return SalePaymentDTO(
            id: paymentID.uuidString,
            method: method,
            paidAt: try SaleTimestampDTO(canonicalString: paidAtCanonical)
        )
    }

    private func documentDTO() throws -> SaleDocumentDTO {
        guard let documentID, let closedAtCanonical else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
        return SaleDocumentDTO(
            id: documentID.uuidString,
            closedAt: try SaleTimestampDTO(canonicalString: closedAtCanonical)
        )
    }

    private func reversalDTO() throws -> SaleReversalDTO {
        guard let reversalID, let voidedAtCanonical else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
        return SaleReversalDTO(
            id: reversalID.uuidString,
            voidedAt: try SaleTimestampDTO(canonicalString: voidedAtCanonical)
        )
    }

    private func requireEmptyMetadata() throws {
        guard paymentID == nil,
              paymentMethodRawValue == nil,
              paidAtCanonical == nil,
              documentID == nil,
              closedAtCanonical == nil,
              reversalID == nil,
              voidedAtCanonical == nil else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
    }

    private func requireDocumentAndReversalAbsent() throws {
        guard documentID == nil,
              closedAtCanonical == nil,
              reversalID == nil,
              voidedAtCanonical == nil else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
    }

    private func requireReversalAbsent() throws {
        guard reversalID == nil, voidedAtCanonical == nil else {
            throw SaleModelPayloadError.invalidLifecycleMetadata
        }
    }
}

private extension SaleStatusDTO {
    var flattenedMetadata: SaleFlattenedMetadata {
        switch self {
        case .draft:
            SaleFlattenedMetadata(kind: "draft")
        case .inProgress:
            SaleFlattenedMetadata(kind: "inProgress")
        case .awaitingPayment:
            SaleFlattenedMetadata(kind: "awaitingPayment")
        case let .awaitingDocument(payment):
            SaleFlattenedMetadata(kind: "awaitingDocument", payment: payment)
        case let .closed(payment, document):
            SaleFlattenedMetadata(kind: "closed", payment: payment, document: document)
        case let .voided(payment, document, reversal):
            SaleFlattenedMetadata(
                kind: "voided",
                payment: payment,
                document: document,
                reversal: reversal
            )
        }
    }
}

private struct SaleFlattenedMetadata {
    let kind: String
    let paymentID: UUID?
    let paymentMethod: String?
    let paidAt: String?
    let documentID: UUID?
    let closedAt: String?
    let reversalID: UUID?
    let voidedAt: String?
}

private extension SaleFlattenedMetadata {
    init(
        kind: String,
        payment: SalePaymentDTO? = nil,
        document: SaleDocumentDTO? = nil,
        reversal: SaleReversalDTO? = nil
    ) {
        self.init(
            kind: kind,
            paymentID: payment.flatMap { UUID(uuidString: $0.id) },
            paymentMethod: payment?.method.rawValue,
            paidAt: payment?.paidAt.canonicalString,
            documentID: document.flatMap { UUID(uuidString: $0.id) },
            closedAt: document?.closedAt.canonicalString,
            reversalID: reversal.flatMap { UUID(uuidString: $0.id) },
            voidedAt: reversal?.voidedAt.canonicalString
        )
    }
}
