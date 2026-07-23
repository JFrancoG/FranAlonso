import Foundation

/// A violation of a sale's construction, lifecycle, persistence, or replay rules.
enum SaleError: Error, Equatable {
    /// The sale has no service lines and therefore cannot start.
    case emptySale

    /// The proposed draft contains a progressed line or duplicate line identifiers.
    case invalidDraftState

    /// The requested line does not belong to the sale.
    case lineNotFound

    /// The requested operation is not valid for the sale's current lifecycle state.
    case invalidSaleTransition

    /// A payment attempt does not exactly match payment metadata already recorded.
    case conflictingPayment

    /// A closure attempt does not exactly match document metadata already recorded.
    case conflictingDocument

    /// A void attempt does not exactly match reversal metadata already recorded.
    case conflictingReversal

    /// Decoded data violates the sale's line-identity or lifecycle invariants.
    case invalidPersistedState
}

/// A sale aggregate that preserves historical service snapshots and controls their
/// execution, payment, closure, and compensating-void lifecycle.
struct Sale: Identifiable, Codable, Equatable {
    let id: SaleID
    let clientID: ClientID?
    let createdAt: Date
    private var storedLines: [SaleLine]
    private var storedStatus: SaleStatus

    var lines: [SaleLine] {
        storedLines
    }

    var status: SaleStatus {
        storedStatus
    }

    /// Starts service work for a draft sale.
    ///
    /// A draft may contain no lines, but it cannot start until at least one line exists.
    /// - Throws: `SaleError.invalidSaleTransition` if the sale is not a draft, or
    ///   `SaleError.emptySale` if it contains no lines.
    mutating func start() throws {
        guard status == .draft else {
            throw SaleError.invalidSaleTransition
        }
        guard !lines.isEmpty else {
            throw SaleError.emptySale
        }

        storedStatus = .inProgress
    }

    /// Moves an upcoming line into progress while the sale is in progress.
    ///
    /// - Parameter id: The stable identifier of the line to start.
    /// - Throws: `SaleError.invalidSaleTransition` if the sale is not in progress,
    ///   `SaleError.lineNotFound` if the identifier does not belong to the sale,
    ///   or `SaleLineError.invalidTransition` if the line is not upcoming.
    mutating func startLine(id: SaleLineID) throws {
        guard status == .inProgress else {
            throw SaleError.invalidSaleTransition
        }
        guard let index = storedLines.firstIndex(where: { $0.id == id }) else {
            throw SaleError.lineNotFound
        }

        try storedLines[index].start()
    }

    /// Completes an in-progress line.
    ///
    /// The sale moves to `SaleStatus.awaitingPayment` when this operation leaves
    /// every line completed.
    ///
    /// - Parameter id: The stable identifier of the line to complete.
    /// - Throws: `SaleError.invalidSaleTransition` if the sale is not in progress,
    ///   `SaleError.lineNotFound` if the identifier does not belong to the sale,
    ///   or `SaleLineError.invalidTransition` if the line is not in progress.
    mutating func completeLine(id: SaleLineID) throws {
        guard status == .inProgress else {
            throw SaleError.invalidSaleTransition
        }
        guard let index = storedLines.firstIndex(where: { $0.id == id }) else {
            throw SaleError.lineNotFound
        }

        try storedLines[index].complete()

        if storedLines.allSatisfy({ $0.status == .completed }) {
            storedStatus = .awaitingPayment
        }
    }

    /// Records payment metadata and moves a sale awaiting payment to awaiting document.
    ///
    /// Replaying the exact payment metadata is a no-op, including after the sale
    /// has closed or been voided. Any differing payment metadata is a conflict.
    ///
    /// - Parameters:
    ///   - paymentID: The stable identifier that makes payment registration idempotent.
    ///   - method: The payment method to preserve with the sale.
    ///   - paidAt: The payment timestamp to preserve with the sale.
    /// - Throws: `SaleError.invalidSaleTransition` if service work is not complete,
    ///   or `SaleError.conflictingPayment` if a recorded payment differs from
    ///   these values.
    mutating func registerPayment(
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) throws {
        switch status {
        case .awaitingPayment:
            storedStatus = .awaitingDocument(
                paymentID: paymentID,
                method: method,
                paidAt: paidAt
            )
        case let .awaitingDocument(storedID, storedMethod, storedPaidAt),
             let .closed(storedID, storedMethod, storedPaidAt, _, _),
             let .voided(storedID, storedMethod, storedPaidAt, _, _, _, _):
            guard storedID == paymentID,
                  storedMethod == method,
                  storedPaidAt == paidAt else {
                throw SaleError.conflictingPayment
            }
        case .draft, .inProgress:
            throw SaleError.invalidSaleTransition
        }
    }

    /// Attaches billing document metadata to a paid sale and marks it closed.
    ///
    /// Replaying the exact document and closure timestamp is a no-op, including
    /// after a later void. Differing closure metadata is a conflict.
    ///
    /// - Parameters:
    ///   - documentID: The stable identifier of the billing document.
    ///   - closedAt: The timestamp to preserve for the sale's closure.
    /// - Throws: `SaleError.invalidSaleTransition` if payment has not been recorded,
    ///   or `SaleError.conflictingDocument` if recorded closure metadata differs.
    mutating func close(
        documentID: BillingDocumentID,
        closedAt: Date
    ) throws {
        switch status {
        case let .awaitingDocument(paymentID, method, paidAt):
            storedStatus = .closed(
                paymentID: paymentID,
                method: method,
                paidAt: paidAt,
                documentID: documentID,
                closedAt: closedAt
            )
        case let .closed(_, _, _, storedDocumentID, storedClosedAt),
             let .voided(_, _, _, storedDocumentID, storedClosedAt, _, _):
            guard storedDocumentID == documentID,
                  storedClosedAt == closedAt else {
                throw SaleError.conflictingDocument
            }
        case .draft, .inProgress, .awaitingPayment:
            throw SaleError.invalidSaleTransition
        }
    }

    /// Applies a compensating void without rewriting the sale's original history.
    ///
    /// Replaying the exact reversal metadata after the void is a no-op.
    /// - Parameters:
    ///   - reversalID: The stable identifier that makes the operation idempotent.
    ///   - voidedAt: The effective timestamp of the compensating void.
    /// - Throws: `SaleError.invalidSaleTransition` if the sale is neither closed
    ///   nor already voided, or `SaleError.conflictingReversal` if recorded
    ///   reversal metadata differs.
    mutating func void(
        reversalID: SaleReversalID,
        voidedAt: Date
    ) throws {
        switch status {
        case let .closed(paymentID, method, paidAt, documentID, closedAt):
            storedStatus = .voided(
                paymentID: paymentID,
                method: method,
                paidAt: paidAt,
                documentID: documentID,
                closedAt: closedAt,
                reversalID: reversalID,
                voidedAt: voidedAt
            )
        case let .voided(_, _, _, _, _, storedReversalID, storedVoidedAt):
            guard storedReversalID == reversalID,
                  storedVoidedAt == voidedAt else {
                throw SaleError.conflictingReversal
            }
        case .draft, .inProgress, .awaitingPayment, .awaitingDocument:
            throw SaleError.invalidSaleTransition
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case clientID
        case createdAt
        case lines
        case status
    }
}

extension Sale {
    /// Creates a sale in the draft state from historical service-line snapshots.
    ///
    /// Every supplied line must be upcoming and line identifiers must be unique.
    /// An empty line collection is valid for a draft, although that sale cannot start.
    ///
    /// - Parameters:
    ///   - id: The sale's stable identifier.
    ///   - clientID: The optional identifier of the client associated with the sale.
    ///   - createdAt: The timestamp at which the draft was created.
    ///   - lines: The service-line snapshots to include in the draft.
    /// - Returns: A sale whose status is `SaleStatus.draft`.
    /// - Throws: `SaleError.invalidDraftState` if a line is not upcoming or line
    ///   identifiers are not unique.
    static func draft(
        id: SaleID,
        clientID: ClientID?,
        createdAt: Date,
        lines: [SaleLine]
    ) throws -> Sale {
        guard lines.allSatisfy({ $0.status == .upcoming }),
              hasUniqueLineIdentifiers(lines) else {
            throw SaleError.invalidDraftState
        }

        return Sale(
            id: id,
            clientID: clientID,
            createdAt: createdAt,
            storedLines: lines,
            storedStatus: .draft
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lines = try container.decode([SaleLine].self, forKey: .lines)
        let status = try container.decode(SaleStatus.self, forKey: .status)

        try Self.ensurePersistedStateIsConsistent(
            lines: lines,
            status: status
        )

        self.init(
            id: try container.decode(SaleID.self, forKey: .id),
            clientID: try container.decodeIfPresent(ClientID.self, forKey: .clientID),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            storedLines: lines,
            storedStatus: status
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(clientID, forKey: .clientID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lines, forKey: .lines)
        try container.encode(status, forKey: .status)
    }

    private static func ensurePersistedStateIsConsistent(
        lines: [SaleLine],
        status: SaleStatus
    ) throws {
        guard hasUniqueLineIdentifiers(lines) else {
            throw SaleError.invalidPersistedState
        }

        let everyLineIsUpcoming = lines.allSatisfy { $0.status == .upcoming }
        let everyLineIsCompleted = !lines.isEmpty && lines.allSatisfy { $0.status == .completed }

        switch status {
        case .draft:
            guard everyLineIsUpcoming else {
                throw SaleError.invalidPersistedState
            }
        case .inProgress:
            guard !lines.isEmpty, !everyLineIsCompleted else {
                throw SaleError.invalidPersistedState
            }
        case .awaitingPayment, .awaitingDocument, .closed, .voided:
            guard everyLineIsCompleted else {
                throw SaleError.invalidPersistedState
            }
        }
    }

    private static func hasUniqueLineIdentifiers(_ lines: [SaleLine]) -> Bool {
        Set(lines.map(\.id)).count == lines.count
    }
}
