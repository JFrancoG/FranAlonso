import Foundation

enum SaleError: Error, Equatable {
    case emptySale
    case invalidDraftState
    case lineNotFound
    case invalidSaleTransition
    case conflictingPayment
    case conflictingDocument
    case conflictingReversal
    case invalidPersistedState
}

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

    mutating func start() throws {
        guard status == .draft else {
            throw SaleError.invalidSaleTransition
        }
        guard !lines.isEmpty else {
            throw SaleError.emptySale
        }

        storedStatus = .inProgress
    }

    mutating func startLine(id: SaleLineID) throws {
        guard status == .inProgress else {
            throw SaleError.invalidSaleTransition
        }
        guard let index = storedLines.firstIndex(where: { $0.id == id }) else {
            throw SaleError.lineNotFound
        }

        try storedLines[index].start()
    }

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
