import Foundation
@testable import FranAlonso

enum BillingPrefillRevocation: CaseIterable {
    case edited, ticket, closed, prepared, parentClosed
}

@MainActor
final class BillingFormAvailability {
    var value = true
}

actor BillingFormClientRepository: ClientRepository {
    private let value: Client
    private let gate: RecoveryOperationGate?
    private(set) var reads = 0
    private(set) var writes = 0

    func client(id: ClientID) async throws -> Client? {
        reads += 1
        await gate?.enter()
        return value
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream {
            $0.finish()
        }
    }

    func saveClient(_ client: Client) async throws {
        writes += 1
        throw ClientError.persistenceUnavailable
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        writes += 1
        throw ClientError.persistenceUnavailable
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        writes += 1
        throw ClientError.persistenceUnavailable
    }

    func deactivateClient(_ id: ClientID) async throws {
        writes += 1
        throw ClientError.persistenceUnavailable
    }

    init(client: Client, gate: RecoveryOperationGate? = nil) {
        value = client
        self.gate = gate
    }
}

func billingFormClient(index: Int = 6_001) -> Client {
    Client(
        id: ClientID(rawValue: viewModelUUID(index)),
        displayName: "Synthetic Recipient",
        taxIdentifier: "Synthetic Tax ID",
        billingAddress: BillingAddress(
            streetLine: "Synthetic Street 3",
            postalCode: "AB 12",
            city: "Synthetic City",
            province: "Synthetic Province"
        ),
        status: .draft
    )
}

@MainActor
func populateBillingForm(_ model: BillingViewModel<BillingPresentationRepository>) {
    model.updateField(.displayName, value: "  Manual Recipient  ")
    model.updateField(.taxIdentifier, value: "Manual Tax ID")
    model.updateField(.streetLine, value: "Manual Street 2")
    model.updateField(.postalCode, value: "XY 99")
    model.updateField(.city, value: "Manual City")
    model.updateField(.province, value: "Manual Province")
}

@MainActor
func makeBillingNavigationDraft(
    repository: any SaleRepository,
    saleID: SaleID,
    mode: SaleDraftDestination.Mode = .operate
) -> SaleDraftViewModel {
    SaleDraftViewModel(
        destination: SaleDraftDestination(id: viewModelUUID(6_099), saleID: saleID, mode: mode),
        createdAt: Date(timeIntervalSince1970: 100),
        currency: .eur,
        create: CreateSaleDraftUseCase(repository: repository),
        getDraft: GetSaleDraftUseCase(repository: repository),
        update: UpdateSaleDraftUseCase(repository: repository),
        discard: DiscardSaleDraftUseCase(repository: repository),
        getSale: GetSaleUseCase(repository: repository),
        advance: AdvanceSaleUseCase(repository: repository),
        registerPayment: RegisterSalePaymentUseCase(repository: repository)
    )
}
