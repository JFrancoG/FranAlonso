import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service product link local acceptance", .timeLimit(.minutes(1)))
struct ServiceProductLinkPersistenceTests {
    @Test(arguments: ServiceProductLinkRoute.allCases, UnavailableServiceProduct.allCases)
    @MainActor
    func `unavailable products reject creation without changing either catalog or causal queue`(
        _ route: ServiceProductLinkRoute,
        _ availability: UnavailableServiceProduct
    ) async throws {
        let fixture = try ServiceProductLinkFixture(route: route)
        let productID = ProductID(rawValue: UUID())
        try await availability.prepare(productID, using: fixture.products)
        let productState = try serviceLinkProductState(in: ModelContext(fixture.container))
        let id = ServiceID(rawValue: UUID())

        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await fixture.create(id, profile: serviceLinkProfile(productID: productID))
        }

        #expect(try await fixture.repository.service(id: id) == nil)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)).isEmpty)
        #expect(try await fixture.services.pendingOperations().isEmpty)
        #expect(try serviceLinkProductState(in: ModelContext(fixture.container)) == productState)
        #expect(!fixture.container.mainContext.hasChanges)
    }

    @Test(arguments: ServiceProductLinkRoute.allCases, [UnavailableServiceProduct.inactive, .pendingDelete])
    @MainActor
    func `a link invalidated through another route blocks editing but preserves historical deactivation`(
        _ route: ServiceProductLinkRoute,
        _ availability: UnavailableServiceProduct
    ) async throws {
        let fixture = try ServiceProductLinkFixture(route: route)
        let productID = ProductID(rawValue: UUID())
        try await fixture.products.upsert(.testSnapshot(id: productID, name: "Original product"))
        let id = ServiceID(rawValue: UUID())
        let created = try await fixture.create(id, profile: serviceLinkProfile(productID: productID))
        let acceptedQueue = try await fixture.services.pendingOperations()
        try await availability.invalidate(productID, using: fixture.products)
        let productState = try serviceLinkProductState(in: ModelContext(fixture.container))

        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await fixture.update(id, profile: serviceLinkProfile(productID: productID, name: "Rejected edit"))
        }

        #expect(try await fixture.repository.service(id: id) == created)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)) == [created])
        #expect(try await fixture.services.pendingOperations() == acceptedQueue)
        #expect(!fixture.container.mainContext.hasChanges)

        try await fixture.deactivate(id)

        let inactive = try makeService(
            id: id.rawValue,
            name: "Linked offering",
            type: .product,
            linkedProductID: productID.rawValue,
            status: .inactive
        )
        #expect(try await fixture.repository.service(id: id) == inactive)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)) == [inactive])
        let upserts = try await fixture.services.pendingUpserts()
        try #require(upserts.count == 2)
        #expect(upserts.map(\.service) == [try ServiceDTO(created), try ServiceDTO(inactive)])
        #expect(upserts[1].predecessorOperationID == upserts[0].operationID)
        #expect(try serviceLinkProductState(in: ModelContext(fixture.container)) == productState)
    }

    @Test(arguments: ServiceProductLinkRoute.allCases)
    @MainActor
    func `a removed product link can be replaced or changed to professional without writing products`(
        _ route: ServiceProductLinkRoute
    ) async throws {
        let fixture = try ServiceProductLinkFixture(route: route)
        let originalID = ProductID(rawValue: UUID())
        let replacementID = ProductID(rawValue: UUID())
        try await fixture.products.upsert(.testSnapshot(id: originalID, name: "Original product"))
        try await fixture.products.persistPendingUpsert(
            .testSnapshot(id: replacementID, name: "Replacement product"),
            operationID: UUID()
        )
        let id = ServiceID(rawValue: UUID())
        let original = try await fixture.create(id, profile: serviceLinkProfile(productID: originalID))
        try await fixture.products.persistPendingDelete(originalID, operationID: UUID())
        let productState = try serviceLinkProductState(in: ModelContext(fixture.container))

        let replaced = try await fixture.update(id, profile: serviceLinkProfile(productID: replacementID))
        #expect(try serviceLinkProductState(in: ModelContext(fixture.container)) == productState)
        try await fixture.products.persistPendingDelete(replacementID, operationID: UUID())
        let removedProductState = try serviceLinkProductState(in: ModelContext(fixture.container))
        let professional = try await fixture.update(id, profile: serviceLinkProfile())

        let expectedReplacement = try makeService(
            id: id.rawValue,
            name: "Linked offering",
            type: .product,
            linkedProductID: replacementID.rawValue
        )
        let expectedProfessional = try makeService(id: id.rawValue, name: "Linked offering")
        #expect(replaced == expectedReplacement)
        #expect(professional == expectedProfessional)
        #expect(try await fixture.repository.service(id: id) == expectedProfessional)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)) == [expectedProfessional])
        let upserts = try await fixture.services.pendingUpserts()
        try #require(upserts.count == 3)
        #expect(upserts.map(\.service) == [
            try ServiceDTO(original),
            try ServiceDTO(expectedReplacement),
            try ServiceDTO(expectedProfessional)
        ])
        #expect(upserts.map(\.predecessorOperationID) == [nil, upserts[0].operationID, upserts[1].operationID])
        #expect(try serviceLinkProductState(in: ModelContext(fixture.container)) == removedProductState)
        #expect(!fixture.container.mainContext.hasChanges)
    }

    @Test(arguments: ServiceProductLinkRoute.allCases, ServiceLinkIdentityRejection.allCases)
    @MainActor
    func `service identity and conflict rejection take priority over an unavailable product`(
        _ route: ServiceProductLinkRoute,
        _ rejection: ServiceLinkIdentityRejection
    ) async throws {
        let fixture = try ServiceProductLinkFixture(route: route)
        let id = ServiceID(rawValue: UUID())
        if rejection != .missing {
            _ = try await fixture.create(id, profile: serviceLinkProfile())
        }
        if rejection == .deleted {
            try await fixture.services.persistPendingDelete(id, operationID: UUID())
        } else if rejection == .conflict {
            let operation = try #require(try await fixture.services.pendingUpserts().first)
            try await fixture.services.recordConflict(
                operation: operation,
                reason: .baseChanged,
                remoteRecord: ServiceRemoteRecord(
                    service: makeServiceDTO(id: id.rawValue, name: "Remote commercial value"),
                    version: .versioned(revision: 2, lastOperationID: UUID())
                )
            )
        }
        let accepted = try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container))
        let acceptedQueue = try await fixture.services.pendingOperations()
        let profile = try serviceLinkProfile(productID: ProductID(rawValue: UUID()))

        await #expect(throws: rejection.error) {
            if rejection == .duplicate {
                try await fixture.create(id, profile: profile)
            } else {
                try await fixture.update(id, profile: profile)
            }
        }

        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)) == accepted)
        #expect(try await fixture.services.pendingOperations() == acceptedQueue)
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
        #expect(try await fixture.products.pendingOperations().isEmpty)
        #expect(!fixture.container.mainContext.hasChanges)
    }

    @Test(arguments: ServiceProductLinkRoute.allCases)
    @MainActor
    func `an unreadable linked product reports persistence failure without accepting creation or editing`(
        _ route: ServiceProductLinkRoute
    ) async throws {
        let fixture = try ServiceProductLinkFixture(route: route)
        let existingID = ServiceID(rawValue: UUID())
        let original = try await fixture.create(existingID, profile: serviceLinkProfile())
        let acceptedQueue = try await fixture.services.pendingOperations()
        let productID = ProductID(rawValue: UUID())
        let context = ModelContext(fixture.container)
        context.insert(ProductModel(
            id: productID.rawValue,
            name: "Unreadable product",
            statusRawValue: "invalid-status"
        ))
        try context.save()
        let productState = try serviceLinkProductState(in: ModelContext(fixture.container))
        let newID = ServiceID(rawValue: UUID())
        let profile = try serviceLinkProfile(productID: productID)

        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await fixture.create(newID, profile: profile)
        }
        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await fixture.update(existingID, profile: profile)
        }

        #expect(try await fixture.repository.service(id: newID) == nil)
        #expect(try await fixture.repository.service(id: existingID) == original)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(fixture.container)) == [original])
        #expect(try await fixture.services.pendingOperations() == acceptedQueue)
        #expect(try serviceLinkProductState(in: ModelContext(fixture.container)) == productState)
        #expect(!fixture.container.mainContext.hasChanges)
    }
}

enum ServiceProductLinkRoute: CaseIterable {
    case actor
    case contextual
}

enum UnavailableServiceProduct: CaseIterable {
    case absent
    case inactive
    case pendingDelete
    case remoteTombstone

    func prepare(_ id: ProductID, using actor: ProductPersistenceActor) async throws {
        guard self != .absent else { return }
        try await actor.upsert(.testSnapshot(id: id, name: "Unavailable product"))
        try await invalidate(id, using: actor)
    }

    func invalidate(_ id: ProductID, using actor: ProductPersistenceActor) async throws {
        switch self {
        case .absent:
            break
        case .inactive:
            _ = try await actor.deactivateProduct(id, operationID: UUID())
        case .pendingDelete:
            try await actor.persistPendingDelete(id, operationID: UUID())
        case .remoteTombstone:
            try await actor.recordRemoteObservation(ProductRemoteRecord(
                content: .tombstone(productID: id.rawValue),
                version: .versioned(revision: 2, lastOperationID: UUID()),
                changeSequence: 2
            ))
        }
    }
}

enum ServiceLinkIdentityRejection: CaseIterable {
    case duplicate
    case missing
    case deleted
    case conflict

    var error: ServiceError {
        switch self {
        case .duplicate: .alreadyExists
        case .missing: .notFound
        case .deleted: .deleted
        case .conflict: .conflict
        }
    }
}

@MainActor
private struct ServiceProductLinkFixture {
    let route: ServiceProductLinkRoute
    let container: ModelContainer
    let services: ServicePersistenceActor
    let products: ProductPersistenceActor
    let repository: DefaultServiceRepository
    let adapter: ServiceContextualPersistenceAdapter

    func create(_ id: ServiceID, profile: ServiceProfile) async throws -> Service {
        switch route {
        case .actor:
            try await repository.createService(id: id, profile: profile)
        case .contextual:
            try await adapter.create(id: id, profile: profile, in: container.mainContext)
        }
    }

    func update(_ id: ServiceID, profile: ServiceProfile) async throws -> Service {
        switch route {
        case .actor:
            try await repository.updateService(id: id, profile: profile)
        case .contextual:
            try await adapter.update(id: id, profile: profile, in: container.mainContext)
        }
    }

    func deactivate(_ id: ServiceID) async throws {
        switch route {
        case .actor:
            try await repository.deactivateService(id)
        case .contextual:
            try await adapter.deactivate(id, in: container.mainContext)
        }
    }
}

private extension ServiceProductLinkFixture {
    init(route: ServiceProductLinkRoute) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let services = ServicePersistenceActor(modelContainer: container)
        let signal = ServiceObservationSignal()
        self.init(
            route: route,
            container: container,
            services: services,
            products: ProductPersistenceActor(modelContainer: container),
            repository: DefaultServiceRepository(persistenceActor: services, observationSignal: signal),
            adapter: ServiceContextualPersistenceAdapter(observationSignal: signal)
        )
    }
}

private struct ServiceLinkProductRow: Equatable {
    let id: UUID
    let name: String
    let status: String
}

private struct ServiceLinkProductState: Equatable {
    let rows: [ServiceLinkProductRow]
    let operations: [ProductPendingOperation]
    let remoteRecords: [ProductRemoteRecord]
}

private func serviceLinkProductState(in context: ModelContext) throws -> ServiceLinkProductState {
    let rows = try context.fetch(FetchDescriptor<ProductModel>()).map {
        ServiceLinkProductRow(id: $0.id, name: $0.name, status: $0.statusRawValue)
    }.sorted { $0.id.uuidString < $1.id.uuidString }
    let records = try context.fetch(FetchDescriptor<ProductRemoteStateModel>()).map {
        try $0.decodeRecord()
    }.sorted { $0.id < $1.id }
    return ServiceLinkProductState(
        rows: rows,
        operations: try ProductLocalDataSource().pendingOperations(in: context),
        remoteRecords: records
    )
}

private func serviceLinkProfile(
    productID: ProductID? = nil,
    name: String = "Linked offering"
) throws -> ServiceProfile {
    try ServiceProfile(
        name: name,
        type: productID == nil ? .professional : .product,
        linkedProductID: productID,
        price: Money(amount: 29.95, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10)
    )
}
