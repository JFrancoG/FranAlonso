import Foundation
@testable import FranAlonso

enum SaleServiceSelectionOffering: CaseIterable {
    case professional
    case product

    func service(currency: Currency, revised: Bool = false) throws -> Service {
        try makeService(
            id: viewModelUUID(7_801),
            name: revised ? "Oferta revisada" : (self == .professional ? "Corte original" : "Kit original"),
            type: self == .professional ? .professional : .product,
            linkedProductID: self == .product ? viewModelUUID(revised ? 7_803 : 7_802) : nil,
            priceAmount: revised ? 51.09 : (self == .professional ? 12.10 : 43.27),
            currency: currency,
            taxPercentage: revised ? 10 : (self == .professional ? 21 : 7.5),
            discountPercentage: revised ? 10 : (self == .professional ? nil : 0)
        )
    }
}

@MainActor
func saleSelectionDraft(
    repository: any SaleRepository,
    currency: Currency = .eur,
    mode: SaleDraftDestination.Mode = .editDraft
) -> SaleDraftViewModel {
    SaleDraftViewModel(
        destination: SaleDraftDestination(
            id: viewModelUUID(7_804),
            saleID: SaleID(rawValue: viewModelUUID(7_805)),
            mode: mode
        ),
        createdAt: Date(timeIntervalSince1970: 100),
        currency: currency,
        create: CreateSaleDraftUseCase(repository: repository),
        getDraft: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository),
        getSale: GetSaleUseCase(repository: repository)
    )
}

func saleSelectionEmptyDraft() throws -> Sale {
    try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(7_805)),
        clientID: nil,
        createdAt: Date(timeIntervalSince1970: 100),
        lines: []
    )
}

@MainActor
func saleSelectionCoordinator(
    services: any ServiceRepository,
    draft: SaleDraftViewModel,
    lineID: SaleLineID = SaleLineID(rawValue: viewModelUUID(7_806))
) -> SaleServicePickerViewModel {
    SaleServicePickerViewModel(
        picker: ServicePickerViewModel(observeServices: ObserveServicesUseCase(repository: services)),
        canAdd: { draft.canAddServices },
        addLine: { line in
            _ = try await draft.addLine(line)
        },
        makeLineID: { lineID }
    )
}

actor SaleSelectionControlledRepository: SaleRepository {
    enum AcceptancePhase { case before, after }

    private let backing: InMemorySaleRepository
    private var shouldFailUpdate = false
    private var updateHold: (SaleDraftScreenCheckpoint, AcceptancePhase)?
    private(set) var updateAttempts: [[SaleLine]] = []

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await backing.observeSales()
    }

    func sale(id: SaleID) async throws -> Sale? {
        try await backing.sale(id: id)
    }

    func saveSale(_ sale: Sale) async throws {
        try await backing.saveSale(sale)
    }

    func createDraft(_ draft: Sale) async throws {
        try await backing.createDraft(draft)
    }

    func discardDraft(_ id: SaleID) async throws {
        try await backing.discardDraft(id)
    }

    func updateDraft(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        updateAttempts.append(lines)
        let held = updateHold
        updateHold = nil
        if held?.1 == .before {
            await held?.0.block()
        }
        if shouldFailUpdate {
            shouldFailUpdate = false
            throw SaleDraftError.persistenceUnavailable
        }
        let accepted = try await backing.updateDraft(expected, clientID: clientID, lines: lines)
        if held?.1 == .after {
            await held?.0.block()
        }
        return accepted
    }

    func failNextUpdate() {
        shouldFailUpdate = true
    }

    func holdNextUpdate(at checkpoint: SaleDraftScreenCheckpoint, phase: AcceptancePhase) {
        updateHold = (checkpoint, phase)
    }

    init(sales: [Sale]) {
        backing = InMemorySaleRepository(sales: sales)
    }
}
