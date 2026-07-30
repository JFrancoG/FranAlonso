import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service persistence actor")
struct ServicePersistenceActorTests {
    @Test("Concurrent upserts serialize and return detached Domain snapshots")
    func concurrentUpsertsSerializeAndReturnDetachedDomainSnapshots() async throws {
        let container = try makeServicePersistenceContainer()
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let services = [
            try persistenceService(
                id: "52000000-0000-0000-0000-000000000001",
                name: "Tratamiento"
            ),
            try persistenceService(
                id: "52000000-0000-0000-0000-000000000002",
                name: "Corte"
            ),
            try persistenceService(
                id: "52000000-0000-0000-0000-000000000003",
                name: "Peinado"
            )
        ]

        try await withThrowingTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    try await persistenceActor.upsert(service)
                }
            }

            try await group.waitForAll()
        }

        let snapshots: [Service] = try await persistenceActor.fetchAll()
        #expect(snapshots == services.sorted { $0.name < $1.name })
    }

    @Test("An actor save is visible from an independently owned context")
    func actorSaveIsVisibleFromAnIndependentlyOwnedContext() async throws {
        let container = try makeServicePersistenceContainer()
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let linkedProductID = try persistenceUUID(
            "52100000-0000-0000-0000-000000000004"
        )
        let service = try persistenceService(
            id: "52000000-0000-0000-0000-000000000004",
            name: "Producto aplicado",
            type: .product,
            linkedProductID: linkedProductID,
            priceAmount: 17.25,
            discountPercentage: nil,
            status: .inactive
        )

        try await persistenceActor.upsert(service)

        let persistedServices = try ServiceLocalDataSource().fetchAll(
            in: ModelContext(container)
        )
        #expect(persistedServices == [service])
    }

    @Test("Delete removes a stable Service identity through the actor boundary")
    func deleteRemovesAStableServiceIdentityThroughTheActorBoundary() async throws {
        let container = try makeServicePersistenceContainer()
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let service = try persistenceService(
            id: "52000000-0000-0000-0000-000000000005",
            name: "Service to delete"
        )
        try await persistenceActor.upsert(service)

        try await persistenceActor.delete(service.id)

        #expect(
            try ServiceLocalDataSource().fetchAll(
                in: ModelContext(container)
            ).isEmpty
        )
    }
}

private func makeServicePersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ServiceModel.self]))
}

private func persistenceService(
    id: String,
    name: String,
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    priceAmount: Decimal = 29.95,
    discountPercentage: Decimal? = 10,
    status: ServiceStatus = .active
) throws -> Service {
    try makeService(
        id: persistenceUUID(id),
        name: name,
        type: type,
        linkedProductID: linkedProductID,
        priceAmount: priceAmount,
        discountPercentage: discountPercentage,
        status: status
    )
}

private func persistenceUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}
