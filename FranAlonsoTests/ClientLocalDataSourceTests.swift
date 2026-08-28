import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client local data source")
struct ClientLocalDataSourceTests {
    private let dataSource = ClientLocalDataSource()

    @Test("Explicit save makes an inserted client visible from another context")
    func explicitSaveMakesAnInsertedClientVisibleFromAnotherContext() throws {
        let container = try makeClientContainer()
        let client = try completeClient(
            id: "10000000-0000-0000-0000-000000000001",
            displayName: "Ana Alonso"
        )
        let insertionContext = ModelContext(container)
        insertionContext.autosaveEnabled = false

        try dataSource.upsert(client, in: insertionContext)

        #expect(!insertionContext.hasChanges)
        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext) == [client])
    }

    @Test("Upsert updates the client with the same stable identifier")
    func upsertUpdatesTheClientWithTheSameStableIdentifier() throws {
        let container = try makeClientContainer()
        let identifier = "10000000-0000-0000-0000-000000000002"
        let initialClient = Client.draft(
            id: try clientID(identifier),
            displayName: "Initial name"
        )
        let updatedClient = try completeClient(
            id: identifier,
            displayName: "Updated name"
        )

        try dataSource.upsert(initialClient, in: ModelContext(container))
        try dataSource.upsert(updatedClient, in: ModelContext(container))

        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientModel>()) == 1)
        #expect(try dataSource.fetchAll(in: verificationContext) == [updatedClient])
    }

    @Test("The model schema enforces unique client identifiers")
    func modelSchemaEnforcesUniqueClientIdentifiers() throws {
        let container = try makeClientContainer()
        let identifier = "10000000-0000-0000-0000-000000000003"
        let firstClient = Client.draft(
            id: try clientID(identifier),
            displayName: "First value"
        )
        let replacementClient = Client.draft(
            id: try clientID(identifier),
            displayName: "Replacement value"
        )
        let firstContext = ModelContext(container)
        firstContext.insert(ClientModel(firstClient))
        try firstContext.save()

        let replacementContext = ModelContext(container)
        replacementContext.insert(ClientModel(replacementClient))
        try replacementContext.save()

        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientModel>()) == 1)
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [replacementClient]
        )
    }

    @Test("Delete removes an existing client and is idempotent when repeated")
    func deleteRemovesAnExistingClientAndIsIdempotentWhenRepeated() throws {
        let container = try makeClientContainer()
        let client = Client.draft(
            id: try clientID("10000000-0000-0000-0000-000000000004"),
            displayName: "Client to delete"
        )
        try dataSource.upsert(client, in: ModelContext(container))

        try dataSource.delete(client.id, in: ModelContext(container))
        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)

        let repeatedDeletionContext = ModelContext(container)
        repeatedDeletionContext.autosaveEnabled = false
        try dataSource.delete(client.id, in: repeatedDeletionContext)
        #expect(!repeatedDeletionContext.hasChanges)
    }

    @Test("Model conversion rejects an unknown persisted client status")
    func modelConversionRejectsAnUnknownPersistedClientStatus() throws {
        let model = ClientModel(
            id: try rawUUID("10000000-0000-0000-0000-000000000005"),
            displayName: "Invalid status",
            taxIdentifier: nil,
            billingStreetLine: nil,
            billingPostalCode: nil,
            billingCity: nil,
            billingProvince: nil,
            statusRawValue: "suspended",
            consentReference: nil
        )

        #expect(throws: ClientMappingError.invalidPersistedStatus("suspended")) {
            try model.toDomain()
        }
    }

    @Test("Model conversion rejects a partially persisted billing address")
    func modelConversionRejectsAPartiallyPersistedBillingAddress() throws {
        let model = ClientModel(
            id: try rawUUID("10000000-0000-0000-0000-000000000006"),
            displayName: "Incomplete address",
            taxIdentifier: nil,
            billingStreetLine: "Calle Bailén, 33",
            billingPostalCode: nil,
            billingCity: "Sevilla",
            billingProvince: "Sevilla",
            statusRawValue: "draft",
            consentReference: nil
        )

        #expect(throws: ClientMappingError.incompletePersistedBillingAddress) {
            try model.toDomain()
        }
    }

}

private func makeClientContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ClientModel.self]))
}

private func completeClient(id: String, displayName: String) throws -> Client {
    Client(
        id: try clientID(id),
        displayName: displayName,
        taxIdentifier: "12345678Z",
        billingAddress: BillingAddress(
            streetLine: "Calle Bailén, 33",
            postalCode: "41001",
            city: "Sevilla",
            province: "Sevilla"
        ),
        status: .active(
            consentReference: try ClientConsentReference(
                rawValue: "consents/client/signed.pdf"
            )
        )
    )
}

private func clientID(_ value: String) throws -> ClientID {
    ClientID(rawValue: try rawUUID(value))
}

private func rawUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}
