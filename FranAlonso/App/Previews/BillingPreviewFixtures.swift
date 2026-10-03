import Foundation

/// Synthetic fiscal input over a fixed paid sale; no recipient data or document number is real.
struct BillingPreviewFixtures {
    let input: BillingFiscalRecipientInput
}

extension BillingPreviewFixtures {
    static let standard = BillingPreviewFixtures(input: BillingFiscalRecipientInput(
        displayName: "Alba DEMO — Estudio de imagen y cuidado personal",
        taxIdentifier: "DEMO-IDENTIFICADOR",
        streetLine: "Calle de la muestra de demostración, edificio de prueba, local 12",
        postalCode: "DEMO 28000",
        city: "Ciudad de demostración",
        province: "Provincia de demostración"
    ))

    @MainActor
    static func model(
        kind: BillingDocumentKind,
        invalid: Bool = false,
        prepared: Bool = false
    ) -> BillingViewModel<UnavailableBillingDocumentReservationRepository> {
        let model = BillingViewModel(
            sale: SalesPreviewFixtures.workday.sales[5],
            reserve: ReserveBillingDocumentUseCase(repository: UnavailableBillingDocumentReservationRepository()),
            prepare: PrepareBillingDocumentRequestUseCase(
                makeRequestID: { BillingDocumentRequestID(rawValue: fixedID(1)) },
                makeDocumentID: { BillingDocumentID(rawValue: fixedID(2)) },
                now: { Date(timeIntervalSince1970: 1_790_001_200) }
            )
        )
        model.selectKind(kind)
        if kind == .invoice {
            for field in BillingFiscalField.allCases {
                model.updateField(field, value: invalid && field == .taxIdentifier ? "" : standard.input[field])
            }
        }
        if invalid || prepared {
            _ = model.prepareSelection()
        }
        return model
    }

    private static func fixedID(_ value: UInt8) -> UUID {
        UUID(uuid: (13, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, value))
    }
}
