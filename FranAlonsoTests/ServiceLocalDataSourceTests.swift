import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service local data source")
struct ServiceLocalDataSourceTests {
    private let dataSource = ServiceLocalDataSource()

    @Test("Explicit save makes an inserted Service visible from another context")
    func explicitSaveMakesAnInsertedServiceVisibleFromAnotherContext() throws {
        let container = try makeServiceLocalContainer()
        let service = try localService(
            id: "51000000-0000-0000-0000-000000000001",
            name: "Corte y peinado"
        )
        let insertionContext = ModelContext(container)
        insertionContext.autosaveEnabled = false

        try dataSource.upsert(service, in: insertionContext)

        #expect(!insertionContext.hasChanges)
        #expect(
            try dataSource.fetchAll(in: ModelContext(container)) == [service]
        )
    }

    @Test("Upsert replaces every Service field under the same stable identity")
    func upsertReplacesEveryFieldUnderTheSameStableIdentity() throws {
        let container = try makeServiceLocalContainer()
        let identifier = "51000000-0000-0000-0000-000000000002"
        let initialService = try localService(
            id: identifier,
            name: "Initial service"
        )
        let linkedProductID = try localUUID(
            "51100000-0000-0000-0000-000000000002"
        )
        let updatedService = try localService(
            id: identifier,
            name: "Updated product service",
            type: .product,
            linkedProductID: linkedProductID,
            priceAmount: 45.75,
            currency: .usd,
            taxPercentage: 8.5,
            discountPercentage: nil,
            status: .inactive
        )

        try dataSource.upsert(initialService, in: ModelContext(container))
        try dataSource.upsert(updatedService, in: ModelContext(container))

        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServiceModel>()
            ) == 1
        )
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [updatedService]
        )
    }

    @Test("The model schema enforces unique Service identifiers")
    func modelSchemaEnforcesUniqueServiceIdentifiers() throws {
        let container = try makeServiceLocalContainer()
        let identifier = "51000000-0000-0000-0000-000000000003"
        let firstService = try localService(
            id: identifier,
            name: "First value"
        )
        let replacementService = try localService(
            id: identifier,
            name: "Replacement value",
            priceAmount: 60,
            discountPercentage: nil,
            status: .inactive
        )
        let firstContext = ModelContext(container)
        firstContext.insert(try ServiceModel(firstService))
        try firstContext.save()

        let replacementContext = ModelContext(container)
        replacementContext.insert(try ServiceModel(replacementService))
        try replacementContext.save()

        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServiceModel>()
            ) == 1
        )
        #expect(
            try dataSource.fetchAll(in: verificationContext)
                == [replacementService]
        )
    }

    @Test("Delete removes an existing Service and remains idempotent")
    func deleteRemovesAnExistingServiceAndRemainsIdempotent() throws {
        let container = try makeServiceLocalContainer()
        let service = try localService(
            id: "51000000-0000-0000-0000-000000000004",
            name: "Service to delete"
        )
        try dataSource.upsert(service, in: ModelContext(container))

        try dataSource.delete(service.id, in: ModelContext(container))
        #expect(
            try dataSource.fetchAll(in: ModelContext(container)).isEmpty
        )

        let repeatedDeletionContext = ModelContext(container)
        repeatedDeletionContext.autosaveEnabled = false
        try dataSource.delete(service.id, in: repeatedDeletionContext)
        #expect(!repeatedDeletionContext.hasChanges)
    }

    @Test("Model conversion rejects an unknown persisted Service status")
    func modelConversionRejectsAnUnknownPersistedServiceStatus() throws {
        let model = try ServiceModel(
            localService(
                id: "51000000-0000-0000-0000-000000000005",
                name: "Invalid status"
            )
        )
        model.statusRawValue = "suspended"

        #expect(
            throws: ServiceMappingError.invalidPersistedStatus("suspended")
        ) {
            _ = try model.toDomain()
        }
    }

    @Test("Model conversion rejects an unknown persisted Service type")
    func modelConversionRejectsAnUnknownPersistedServiceType() throws {
        let model = try ServiceModel(
            localService(
                id: "51000000-0000-0000-0000-000000000006",
                name: "Invalid type"
            )
        )
        model.typeRawValue = "subscription"

        #expect(
            throws: ServiceMappingError.invalidPersistedType("subscription")
        ) {
            _ = try model.toDomain()
        }
    }

    @Test("Model reconstruction revalidates both Service type-link rules")
    func modelReconstructionRevalidatesBothTypeLinkRules() throws {
        let productWithoutLink = try ServiceModel(
            localService(
                id: "51000000-0000-0000-0000-000000000007",
                name: "Missing Product"
            )
        )
        productWithoutLink.typeRawValue = ServiceType.product.rawValue

        let professionalWithLink = try ServiceModel(
            localService(
                id: "51000000-0000-0000-0000-000000000008",
                name: "Unexpected Product",
                type: .product,
                linkedProductID: try localUUID(
                    "51100000-0000-0000-0000-000000000008"
                )
            )
        )
        professionalWithLink.typeRawValue = ServiceType.professional.rawValue

        #expect(throws: ServiceError.linkedProductRequired) {
            _ = try productWithoutLink.toDomain()
        }
        #expect(throws: ServiceError.linkedProductNotAllowed) {
            _ = try professionalWithLink.toDomain()
        }
    }

    @Test(
        "Every Service status round trips through the persistent model",
        arguments: [ServiceStatus.active, .inactive]
    )
    func everyServiceStatusRoundTrips(_ status: ServiceStatus) throws {
        let service = try localService(
            id: "51000000-0000-0000-0000-000000000009",
            name: "Catalog service",
            status: status
        )

        #expect(try ServiceModel(service).toDomain() == service)
    }
}

private func makeServiceLocalContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ServiceModel.self]))
}

private func localService(
    id: String,
    name: String,
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    priceAmount: Decimal = 29.95,
    currency: Currency = .eur,
    taxPercentage: Decimal = 21,
    discountPercentage: Decimal? = 10,
    status: ServiceStatus = .active
) throws -> Service {
    try makeService(
        id: localUUID(id),
        name: name,
        type: type,
        linkedProductID: linkedProductID,
        priceAmount: priceAmount,
        currency: currency,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        status: status
    )
}

private func localUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}
