import Foundation

/// Errors raised when a Sale transport payload cannot reconstruct a valid aggregate.
enum SaleMappingError: Error, Equatable {
    /// A stable identity at the reported aggregate location is not a UUID string.
    case invalidIdentifier(String, location: SaleIdentifierLocation)

    /// Domain money normalization would change the transported amount.
    case moneyNormalizationChanged(original: Decimal, normalized: Decimal)

    /// The payload shape is not supported by this application version.
    case unsupportedPayloadVersion(Int)

    /// Line progress and aggregate lifecycle do not describe one valid Sale history.
    case invalidLifecycle
}

/// The exact aggregate field whose transported identifier could not be reconstructed.
enum SaleIdentifierLocation: Equatable {
    case sale
    case client
    case line(index: Int)
    case service(lineIndex: Int)
    case linkedProduct(lineIndex: Int)
    case payment
    case document
    case reversal
}

extension SaleDTO {
    /// Creates the exact v1 transport snapshot for a validated Domain Sale.
    ///
    /// - Parameter sale: The aggregate whose identity, order, values, and dates are preserved.
    /// - Throws: Canonical decimal or timestamp errors when a value is not transportable.
    init(_ sale: Sale) throws {
        self.init(
            payloadVersion: Self.currentPayloadVersion,
            id: sale.id.rawValue.uuidString,
            clientID: sale.clientID?.rawValue.uuidString,
            createdAt: try SaleTimestampDTO(sale.createdAt),
            lines: try sale.lines.map(SaleLineDTO.init),
            status: try SaleStatusDTO(sale.status)
        )
    }

    /// Reconstructs a Sale by replaying its validated Domain factories and transitions.
    ///
    /// - Returns: The exact Domain aggregate represented by this v1 payload.
    /// - Throws: `SaleMappingError` for unsupported versions, invalid identifiers,
    ///   monetary normalization, or an incoherent lifecycle. Domain errors propagate.
    func toDomain() throws -> Sale {
        guard payloadVersion == Self.currentPayloadVersion else {
            throw SaleMappingError.unsupportedPayloadVersion(payloadVersion)
        }

        let saleID = SaleID(rawValue: try saleUUID(id, location: .sale))
        let clientID = try clientID.map { rawValue in
            ClientID(rawValue: try saleUUID(rawValue, location: .client))
        }
        let upcomingLines = try lines.enumerated().map { index, line in
            try line.toUpcomingDomain(at: index)
        }
        var sale = try Sale.draft(
            id: saleID,
            clientID: clientID,
            createdAt: createdAt.date,
            lines: upcomingLines
        )

        switch status {
        case .draft:
            guard lines.allSatisfy({ $0.status == .upcoming }) else {
                throw SaleMappingError.invalidLifecycle
            }
        case .inProgress:
            guard !lines.isEmpty,
                  !lines.allSatisfy({ $0.status == .completed }) else {
                throw SaleMappingError.invalidLifecycle
            }
            try replayLineProgress(in: &sale)
            guard sale.status == .inProgress else { throw SaleMappingError.invalidLifecycle }
        case .awaitingPayment:
            try replayCompletedLines(in: &sale)
        case let .awaitingDocument(payment):
            try replayCompletedLines(in: &sale)
            try sale.registerPayment(
                id: PaymentID(
                    rawValue: try saleUUID(payment.id, location: .payment)
                ),
                method: payment.method.domain,
                paidAt: payment.paidAt.date
            )
        case let .closed(payment, document):
            try replayCompletedLines(in: &sale)
            try sale.registerPayment(
                id: PaymentID(
                    rawValue: try saleUUID(payment.id, location: .payment)
                ),
                method: payment.method.domain,
                paidAt: payment.paidAt.date
            )
            try sale.close(
                documentID: BillingDocumentID(
                    rawValue: try saleUUID(document.id, location: .document)
                ),
                closedAt: document.closedAt.date
            )
        case let .voided(payment, document, reversal):
            try replayCompletedLines(in: &sale)
            try sale.registerPayment(
                id: PaymentID(
                    rawValue: try saleUUID(payment.id, location: .payment)
                ),
                method: payment.method.domain,
                paidAt: payment.paidAt.date
            )
            try sale.close(
                documentID: BillingDocumentID(
                    rawValue: try saleUUID(document.id, location: .document)
                ),
                closedAt: document.closedAt.date
            )
            try sale.void(
                reversalID: SaleReversalID(
                    rawValue: try saleUUID(reversal.id, location: .reversal)
                ),
                voidedAt: reversal.voidedAt.date
            )
        }

        return sale
    }

    private func replayCompletedLines(in sale: inout Sale) throws {
        guard !lines.isEmpty,
              lines.allSatisfy({ $0.status == .completed }) else {
            throw SaleMappingError.invalidLifecycle
        }
        try replayLineProgress(in: &sale)
        guard sale.status == .awaitingPayment else { throw SaleMappingError.invalidLifecycle }
    }

    private func replayLineProgress(in sale: inout Sale) throws {
        try sale.start()
        for (index, line) in lines.enumerated() {
            let lineID = SaleLineID(
                rawValue: try saleUUID(line.id, location: .line(index: index))
            )
            switch line.status {
            case .upcoming:
                break
            case .inProgress:
                try sale.startLine(id: lineID)
            case .completed:
                try sale.startLine(id: lineID)
                try sale.completeLine(id: lineID)
            }
        }
    }
}

private extension SaleLineDTO {
    init(_ line: SaleLine) throws {
        let currency: SaleCurrencyDTO = switch line.unitPrice.currency {
        case .eur: .eur
        case .usd: .usd
        }
        let status: SaleLineStatusDTO = switch line.status {
        case .upcoming: .upcoming
        case .inProgress: .inProgress
        case .completed: .completed
        }

        self.init(
            id: line.id.rawValue.uuidString,
            serviceID: line.serviceID.rawValue.uuidString,
            serviceName: line.serviceName,
            quantity: line.quantity,
            unitPrice: SaleMoneyDTO(
                amount: try CanonicalDecimalDTO(line.unitPrice.amount),
                currency: currency
            ),
            taxRate: SaleTaxRateDTO(
                percentage: try CanonicalDecimalDTO(line.taxRate.percentage)
            ),
            discount: try line.discount.map {
                SaleDiscountDTO(
                    percentage: try CanonicalDecimalDTO($0.percentage)
                )
            },
            linkedProductID: line.linkedProductID?.rawValue.uuidString,
            status: status
        )
    }

    func toUpcomingDomain(at index: Int) throws -> SaleLine {
        let currency: Currency = switch unitPrice.currency {
        case .eur: .eur
        case .usd: .usd
        }
        let money = try Money(amount: unitPrice.amount.decimal, currency: currency)
        guard money.amount == unitPrice.amount.decimal else {
            throw SaleMappingError.moneyNormalizationChanged(
                original: unitPrice.amount.decimal,
                normalized: money.amount
            )
        }

        return try SaleLine.upcoming(
            id: SaleLineID(
                rawValue: try saleUUID(id, location: .line(index: index))
            ),
            serviceID: ServiceID(
                rawValue: try saleUUID(
                    serviceID,
                    location: .service(lineIndex: index)
                )
            ),
            serviceName: serviceName,
            quantity: quantity,
            unitPrice: money,
            taxRate: TaxRate(percentage: taxRate.percentage.decimal),
            discount: try discount.map {
                try Discount(percentage: $0.percentage.decimal)
            },
            linkedProductID: try linkedProductID.map { rawValue in
                ProductID(
                    rawValue: try saleUUID(
                        rawValue,
                        location: .linkedProduct(lineIndex: index)
                    )
                )
            }
        )
    }
}

private extension SaleStatusDTO {
    init(_ status: SaleStatus) throws {
        switch status {
        case .draft:
            self = .draft
        case .inProgress:
            self = .inProgress
        case .awaitingPayment:
            self = .awaitingPayment
        case let .awaitingDocument(paymentID, method, paidAt):
            self = .awaitingDocument(
                payment: try SalePaymentDTO(paymentID, method, paidAt)
            )
        case let .closed(paymentID, method, paidAt, documentID, closedAt):
            self = .closed(
                payment: try SalePaymentDTO(paymentID, method, paidAt),
                document: SaleDocumentDTO(
                    id: documentID.rawValue.uuidString,
                    closedAt: try SaleTimestampDTO(closedAt)
                )
            )
        case let .voided(
            paymentID,
            method,
            paidAt,
            documentID,
            closedAt,
            reversalID,
            voidedAt
        ):
            self = .voided(
                payment: try SalePaymentDTO(paymentID, method, paidAt),
                document: SaleDocumentDTO(
                    id: documentID.rawValue.uuidString,
                    closedAt: try SaleTimestampDTO(closedAt)
                ),
                reversal: SaleReversalDTO(
                    id: reversalID.rawValue.uuidString,
                    voidedAt: try SaleTimestampDTO(voidedAt)
                )
            )
        }
    }
}

private extension SalePaymentDTO {
    init(_ id: PaymentID, _ method: PaymentMethod, _ paidAt: Date) throws {
        let transportMethod: SalePaymentMethodDTO = switch method {
        case .cash: .cash
        case .card: .card
        }
        self.init(
            id: id.rawValue.uuidString,
            method: transportMethod,
            paidAt: try SaleTimestampDTO(paidAt)
        )
    }
}

private extension SalePaymentMethodDTO {
    var domain: PaymentMethod {
        switch self {
        case .cash: .cash
        case .card: .card
        }
    }
}

private func saleUUID(_ rawValue: String, location: SaleIdentifierLocation) throws -> UUID {
    guard let identifier = UUID(uuidString: rawValue) else {
        throw SaleMappingError.invalidIdentifier(
            rawValue,
            location: location
        )
    }
    return identifier
}
