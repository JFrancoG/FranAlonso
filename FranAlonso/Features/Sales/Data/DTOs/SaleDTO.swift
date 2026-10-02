/// A versioned Sale aggregate independent of Domain and backend SDK types.
struct SaleDTO: Codable, Equatable {
    /// New writes use v2; historical v1 snapshots retain their own version on replay.
    static let currentPayloadVersion = 2

    let payloadVersion: Int
    let id: String
    let clientID: String?
    let createdAt: SaleTimestampDTO
    let lines: [SaleLineDTO]
    let status: SaleStatusDTO
    let globalDiscount: SaleGlobalDiscountDTO?
}

/// The validated sale-wide percentage and the historical calculation order it selects.
struct SaleGlobalDiscountDTO: Codable, Equatable {
    let percentage: CanonicalDecimalDTO
    let policy: SaleGlobalDiscountPolicyDTO
}

/// The stable calculation policy carried by a commercial transport snapshot.
enum SaleGlobalDiscountPolicyDTO: String, Codable, Equatable {
    case lineThenGlobalV1
}

/// The local2 commercial envelope stored in the existing ordered-line payload column.
struct SaleCommercialPayloadDTO: Codable {
    let lines: [SaleLineDTO]
    let globalDiscount: SaleGlobalDiscountDTO?
}

/// A versioned snapshot of one ordered Sale service line.
struct SaleLineDTO: Codable, Equatable {
    let id: String
    let serviceID: String
    let serviceName: String
    let quantity: Int
    let unitPrice: SaleMoneyDTO
    let taxRate: SaleTaxRateDTO
    let discount: SaleDiscountDTO?
    let linkedProductID: String?
    let status: SaleLineStatusDTO
}

/// The monetary portion of a Sale line snapshot.
struct SaleMoneyDTO: Codable, Equatable {
    let amount: CanonicalDecimalDTO
    let currency: SaleCurrencyDTO
}

/// The tax portion of a Sale line snapshot.
struct SaleTaxRateDTO: Codable, Equatable {
    let percentage: CanonicalDecimalDTO
}

/// The optional discount portion of a Sale line snapshot.
struct SaleDiscountDTO: Codable, Equatable {
    let percentage: CanonicalDecimalDTO
}

extension SaleLineDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case serviceID
        case serviceName
        case quantity
        case unitPrice
        case taxRate
        case discount
        case linkedProductID
        case status
    }

    init(from decoder: any Decoder) throws {
        try requireSalePayloadKeys(
            required: [
                CodingKeys.id.rawValue,
                CodingKeys.serviceID.rawValue,
                CodingKeys.serviceName.rawValue,
                CodingKeys.quantity.rawValue,
                CodingKeys.unitPrice.rawValue,
                CodingKeys.taxRate.rawValue,
                CodingKeys.status.rawValue
            ],
            allowed: CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale line payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            serviceID: try container.decode(String.self, forKey: .serviceID),
            serviceName: try container.decode(String.self, forKey: .serviceName),
            quantity: try container.decode(Int.self, forKey: .quantity),
            unitPrice: try container.decode(SaleMoneyDTO.self, forKey: .unitPrice),
            taxRate: try container.decode(SaleTaxRateDTO.self, forKey: .taxRate),
            discount: try container.decodeIfPresent(SaleDiscountDTO.self, forKey: .discount),
            linkedProductID: try container.decodeIfPresent(String.self, forKey: .linkedProductID),
            status: try container.decode(SaleLineStatusDTO.self, forKey: .status)
        )
    }
}

extension SaleMoneyDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case amount
        case currency
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale money payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            amount: try container.decode(CanonicalDecimalDTO.self, forKey: .amount),
            currency: try container.decode(SaleCurrencyDTO.self, forKey: .currency)
        )
    }
}

extension SaleTaxRateDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case percentage
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale tax payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(percentage: try container.decode(CanonicalDecimalDTO.self, forKey: .percentage))
    }
}

extension SaleDiscountDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case percentage
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale discount payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(percentage: try container.decode(CanonicalDecimalDTO.self, forKey: .percentage))
    }
}

/// Stable currency values supported by Sale transport.
enum SaleCurrencyDTO: String, Codable, Equatable {
    case eur = "EUR"
    case usd = "USD"
}

/// Stable execution values for a transported Sale line.
enum SaleLineStatusDTO: String, Codable, Equatable {
    case upcoming
    case inProgress
    case completed
}

/// Stable payment-method values for Sale transport.
enum SalePaymentMethodDTO: String, Codable, Equatable {
    case cash
    case card
}

/// Payment metadata accumulated by a Sale lifecycle.
struct SalePaymentDTO: Codable, Equatable {
    let id: String
    let method: SalePaymentMethodDTO
    let paidAt: SaleTimestampDTO
}

/// Document metadata accumulated by a closed Sale.
struct SaleDocumentDTO: Codable, Equatable {
    let id: String
    let closedAt: SaleTimestampDTO
}

/// Reversal metadata accumulated by a voided Sale.
struct SaleReversalDTO: Codable, Equatable {
    let id: String
    let voidedAt: SaleTimestampDTO
}

extension SalePaymentDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case method
        case paidAt
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale payment payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            method: try container.decode(SalePaymentMethodDTO.self, forKey: .method),
            paidAt: try container.decode(SaleTimestampDTO.self, forKey: .paidAt)
        )
    }
}

extension SaleDocumentDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case closedAt
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale document payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            closedAt: try container.decode(SaleTimestampDTO.self, forKey: .closedAt)
        )
    }
}

extension SaleReversalDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case voidedAt
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale reversal payload does not match v1."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            voidedAt: try container.decode(SaleTimestampDTO.self, forKey: .voidedAt)
        )
    }
}

/// An exact, tagged representation of every Sale lifecycle state.
enum SaleStatusDTO: Equatable {
    case draft
    case inProgress
    case awaitingPayment
    case awaitingDocument(payment: SalePaymentDTO)
    case closed(payment: SalePaymentDTO, document: SaleDocumentDTO)
    case voided(payment: SalePaymentDTO, document: SaleDocumentDTO, reversal: SaleReversalDTO)
}

extension SaleDTO {
    /// Creates a snapshot without a global term, preserving existing v1 construction callers.
    init(
        payloadVersion: Int,
        id: String,
        clientID: String?,
        createdAt: SaleTimestampDTO,
        lines: [SaleLineDTO],
        status: SaleStatusDTO
    ) {
        self.init(
            payloadVersion: payloadVersion,
            id: id,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines,
            status: status,
            globalDiscount: nil
        )
    }

    private enum CodingKeys: String, CodingKey, CaseIterable, Hashable {
        case payloadVersion
        case id
        case clientID
        case createdAt
        case lines
        case status
        case globalDiscount
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payloadVersion = try container.decode(Int.self, forKey: .payloadVersion)
        guard payloadVersion == 1 || payloadVersion == 2 else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unsupported Sale payload version.")
            )
        }
        let allowedKeys = CodingKeys.allCases.filter { payloadVersion == 2 || $0 != .globalDiscount }
        try requireSalePayloadKeys(
            required: ["payloadVersion", "id", "createdAt", "lines", "status"],
            allowed: allowedKeys.map(\.rawValue),
            decoder: decoder,
            description: "Sale payload does not match its declared version."
        )
        self.init(
            payloadVersion: payloadVersion,
            id: try container.decode(String.self, forKey: .id),
            clientID: try container.decodeIfPresent(String.self, forKey: .clientID),
            createdAt: try container.decode(SaleTimestampDTO.self, forKey: .createdAt),
            lines: try container.decode([SaleLineDTO].self, forKey: .lines),
            status: try container.decode(SaleStatusDTO.self, forKey: .status),
            globalDiscount: try container.decodeIfPresent(SaleGlobalDiscountDTO.self, forKey: .globalDiscount)
        )
    }

    func encode(to encoder: any Encoder) throws {
        guard payloadVersion == 1 || payloadVersion == 2,
              payloadVersion == 2 || globalDiscount == nil else {
            throw EncodingError.invalidValue(
                self,
                .init(codingPath: encoder.codingPath, debugDescription: "Sale payload does not match its version.")
            )
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payloadVersion, forKey: .payloadVersion)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(clientID, forKey: .clientID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lines, forKey: .lines)
        try container.encode(status, forKey: .status)
        if payloadVersion == 2 {
            try container.encodeIfPresent(globalDiscount, forKey: .globalDiscount)
        }
    }
}

extension SaleGlobalDiscountDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case percentage
        case policy
    }

    init(from decoder: any Decoder) throws {
        try requireExactSalePayloadKeys(
            CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Sale global discount payload does not match v2."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let percentage = try container.decode(CanonicalDecimalDTO.self, forKey: .percentage)
        do {
            _ = try Discount(percentage: percentage.decimal)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .percentage,
                in: container,
                debugDescription: "A global discount percentage must be in the closed range 0...100."
            )
        }
        self.init(
            percentage: percentage,
            policy: try container.decode(SaleGlobalDiscountPolicyDTO.self, forKey: .policy)
        )
    }
}

extension SaleCommercialPayloadDTO {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case lines
        case globalDiscount
    }

    init(from decoder: any Decoder) throws {
        try requireSalePayloadKeys(
            required: [CodingKeys.lines.rawValue],
            allowed: CodingKeys.allCases.map(\.rawValue),
            decoder: decoder,
            description: "Local sale commercial payload does not match v2."
        )
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            lines: try container.decode([SaleLineDTO].self, forKey: .lines),
            globalDiscount: try container.decodeIfPresent(SaleGlobalDiscountDTO.self, forKey: .globalDiscount)
        )
    }
}

extension SaleStatusDTO: Codable {
    private enum Kind: String, Codable {
        case draft
        case inProgress
        case awaitingPayment
        case awaitingDocument
        case closed
        case voided
    }

    private enum CodingKeys: String, CodingKey, Hashable {
        case kind
        case payment
        case document
        case reversal
    }

    init(from decoder: any Decoder) throws {
        let strictContainer = try decoder.container(keyedBy: SaleDynamicCodingKey.self)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .draft:
            try Self.requireKeys([.kind], in: strictContainer, decoder: decoder)
            self = .draft
        case .inProgress:
            try Self.requireKeys([.kind], in: strictContainer, decoder: decoder)
            self = .inProgress
        case .awaitingPayment:
            try Self.requireKeys([.kind], in: strictContainer, decoder: decoder)
            self = .awaitingPayment
        case .awaitingDocument:
            try Self.requireKeys([.kind, .payment], in: strictContainer, decoder: decoder)
            self = .awaitingDocument(payment: try container.decode(SalePaymentDTO.self, forKey: .payment))
        case .closed:
            try Self.requireKeys([.kind, .payment, .document], in: strictContainer, decoder: decoder)
            self = .closed(
                payment: try container.decode(SalePaymentDTO.self, forKey: .payment),
                document: try container.decode(SaleDocumentDTO.self, forKey: .document)
            )
        case .voided:
            try Self.requireKeys([.kind, .payment, .document, .reversal], in: strictContainer, decoder: decoder)
            self = .voided(
                payment: try container.decode(SalePaymentDTO.self, forKey: .payment),
                document: try container.decode(SaleDocumentDTO.self, forKey: .document),
                reversal: try container.decode(SaleReversalDTO.self, forKey: .reversal)
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .draft:
            try container.encode(Kind.draft, forKey: .kind)
        case .inProgress:
            try container.encode(Kind.inProgress, forKey: .kind)
        case .awaitingPayment:
            try container.encode(Kind.awaitingPayment, forKey: .kind)
        case let .awaitingDocument(payment):
            try container.encode(Kind.awaitingDocument, forKey: .kind)
            try container.encode(payment, forKey: .payment)
        case let .closed(payment, document):
            try container.encode(Kind.closed, forKey: .kind)
            try container.encode(payment, forKey: .payment)
            try container.encode(document, forKey: .document)
        case let .voided(payment, document, reversal):
            try container.encode(Kind.voided, forKey: .kind)
            try container.encode(payment, forKey: .payment)
            try container.encode(document, forKey: .document)
            try container.encode(reversal, forKey: .reversal)
        }
    }

    private static func requireKeys(
        _ expected: Set<CodingKeys>,
        in container: KeyedDecodingContainer<SaleDynamicCodingKey>,
        decoder: any Decoder
    ) throws {
        guard Set(container.allKeys.map(\.stringValue)) == Set(expected.map(\.rawValue)) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Sale status payload does not match its kind.")
            )
        }
    }
}

private struct SaleDynamicCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

private func requireExactSalePayloadKeys(_ expected: [String], decoder: any Decoder, description: String) throws {
    let container = try decoder.container(keyedBy: SaleDynamicCodingKey.self)
    guard Set(container.allKeys.map(\.stringValue)) == Set(expected) else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: description))
    }
}

private func requireSalePayloadKeys(
    required: [String],
    allowed: [String],
    decoder: any Decoder,
    description: String
) throws {
    let container = try decoder.container(keyedBy: SaleDynamicCodingKey.self)
    let actual = Set(container.allKeys.map(\.stringValue))
    guard actual.isSuperset(of: required), actual.isSubset(of: allowed) else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: description))
    }
}
