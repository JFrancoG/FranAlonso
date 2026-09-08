import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client deactivation retains local consent")
struct ClientDeactivationRetentionTests {
    @Test(
        "Every tombstone route hides the profile but retains its consent",
        arguments: ["local", "ack", "pull", "conflict"]
    )
    func tombstoneRetainsConsent(route: String) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let client = try retainedClient()
        let dataSource = ClientLocalDataSource()
        let operationID = UUID()
        let tombstone = ClientRemoteRecord(
            content: .tombstone(clientID: client.id.rawValue),
            version: .versioned(revision: 2, lastOperationID: operationID),
            changeSequence: 2
        )
        try dataSource.upsert(client, in: ModelContext(container))

        if route == "conflict" {
            try dataSource.persistPendingUpsert(client, operationID: UUID(), in: ModelContext(container))
        }
        if route == "local" || route == "ack" {
            try dataSource.persistPendingDelete(client.id, operationID: operationID, in: ModelContext(container))
        }
        if route == "ack" {
            try dataSource.acknowledge(operationID: operationID, record: tombstone, in: ModelContext(container))
        }
        if route == "pull" || route == "conflict" {
            try dataSource.reconcileRemoteBatch(
                ClientRemoteChangeBatch(records: [tombstone], nextCursor: ClientSyncCursor(changeSequence: 2)),
                policy: ClientSyncPolicy(),
                in: ModelContext(container)
            )
        }

        let verification = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verification).isEmpty)
        let retained = try #require(verification.fetch(FetchDescriptor<ClientModel>()).first)
        #expect(try retained.toDomain() == client)
    }

    @Test("Acknowledged deactivation retains consent after closing and reopening its store")
    func acknowledgedDeactivationSurvivesStoreReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let configuration = ModelConfiguration(
            "ConsentRetention",
            schema: .franAlonso,
            url: directory.appending(path: "Clients.store"),
            cloudKitDatabase: .none
        )
        let client = try retainedClient()
        try persistAcknowledgedDeactivation(client, configuration: configuration)

        let reopened = try ModelContainer(
            for: Schema.franAlonso,
            migrationPlan: PhaseFiveSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(reopened)
        #expect(try ClientLocalDataSource().fetchAll(in: context).isEmpty)
        let retained = try #require(context.fetch(FetchDescriptor<ClientModel>()).first)
        #expect(try retained.toDomain() == client)
    }
}

private func retainedClient() throws -> Client {
    Client(
        id: ClientID(rawValue: UUID()),
        displayName: "Synthetic retained profile",
        taxIdentifier: "SYNTHETIC-01",
        billingAddress: nil,
        status: .active(consentReference: try ClientConsentReference(rawValue: "fixture-consent/retained"))
    )
}

private func persistAcknowledgedDeactivation(_ client: Client, configuration: ModelConfiguration) throws {
    let container = try ModelContainer(
        for: Schema.franAlonso,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
    let dataSource = ClientLocalDataSource()
    let operationID = UUID()
    try dataSource.upsert(client, in: ModelContext(container))
    try dataSource.persistPendingDelete(client.id, operationID: operationID, in: ModelContext(container))
    try dataSource.acknowledge(
        operationID: operationID,
        record: ClientRemoteRecord(
            content: .tombstone(clientID: client.id.rawValue),
            version: .versioned(revision: 1, lastOperationID: operationID),
            changeSequence: 1
        ),
        in: ModelContext(container)
    )
}
