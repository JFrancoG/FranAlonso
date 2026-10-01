import Foundation
import SwiftData

/// Deterministic commercial snapshots and an idempotent seed for interactive previews.
struct ServicePreviewFixtures {
    let professionalService: Service
    let productService: Service
    let inactiveService: Service

    var services: [Service] { [professionalService, productService, inactiveService] }

    @MainActor
    func seed(in context: ModelContext) throws {
        let source = ServiceLocalDataSource()
        for service in services {
            if try source.service(id: service.id, in: context) == nil {
                try source.upsert(service, in: context)
            }
        }
    }
}

extension ServicePreviewFixtures {
    static let assistantDestination = ServiceFormDestination(
        id: UUID(uuid: (16, 3, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, 1)),
        serviceID: ServiceID(rawValue: UUID(uuid: (16, 3, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1))),
        mode: .create
    )

    /// Exercises the complete form with fixed interpretation and no model inference or accepted writes.
    @MainActor
    static func makeAssistantForm(destination: ServiceFormDestination, locale: Locale) -> ServiceFormViewModel {
        let products = InMemoryProductRepository()
        let viewModel = ServiceFormViewModel(
            destination: destination,
            getService: GetServiceUseCase(repository: InMemoryServiceRepository()),
            observeLinkableProducts: ObserveLinkableProductsUseCase(repository: products),
            create: { _, _, _ in
                throw ServiceError.persistenceUnavailable
            },
            update: { _, _, _ in
                throw ServiceError.persistenceUnavailable
            },
            deactivate: { _, _ in
                throw ServiceError.persistenceUnavailable
            },
            locale: locale,
            assistant: PreviewServiceDraftInterpreter()
        )
        viewModel.assistantInput = "Servicio profesional de corte y peinado, precio 35 euros"
        return viewModel
    }

    static let list250: [Service] = (1...250).map { index in
        do {
            return try Service(
                id: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 1, UInt8(index)))),
                name: "Servicio de ejemplo \(index)",
                type: .professional,
                price: Money(amount: Decimal(index), currency: .eur),
                taxRate: TaxRate(percentage: 21),
                discount: nil,
                status: index.isMultiple(of: 5) ? .inactive : .active
            )
        } catch {
            preconditionFailure("The fixed service list values must satisfy Domain invariants")
        }
    }

    static let standard: ServicePreviewFixtures = {
        do {
            return try ServicePreviewFixtures(
                professionalService: Service(
                    id: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1))),
                    name: "Corte y peinado con tratamiento de hidratación",
                    type: .professional,
                    price: Money(amount: 35, currency: .eur),
                    taxRate: TaxRate(percentage: 21),
                    discount: nil,
                    status: .active
                ),
                productService: Service(
                    id: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 2))),
                    name: "Champú profesional hidratante",
                    type: .product,
                    linkedProductID: ProductPreviewFixtures.standard.primaryProduct.id,
                    price: Money(amount: Decimal(string: "19.95")!, currency: .eur),
                    taxRate: TaxRate(percentage: 21),
                    discount: Discount(percentage: 5),
                    status: .active
                ),
                inactiveService: Service(
                    id: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 3))),
                    name: "Coloración de temporada",
                    type: .professional,
                    price: Money(amount: 50, currency: .eur),
                    taxRate: TaxRate(percentage: 21),
                    discount: nil,
                    status: .inactive
                )
            )
        } catch {
            preconditionFailure("The fixed service preview values must satisfy Domain invariants")
        }
    }()
}

private struct PreviewServiceDraftInterpreter: ServiceDraftInterpreter {
    func availability(locale: Locale) async -> ServiceDraftAvailability { .available }

    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal {
        try Task.checkCancellation()
        return try ServiceDraftProposal(name: "Corte y peinado", price: Money(amount: 35, currency: .eur))
    }
}
