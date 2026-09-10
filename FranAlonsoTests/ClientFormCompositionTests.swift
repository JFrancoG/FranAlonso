import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client form contextual composition")
@MainActor
struct ClientFormCompositionTests {
    @Test
    func `creating through the form writes once and publishes on the existing observation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ClientPersistenceActor(modelContainer: container)
        let signal = ClientObservationSignal()
        let repository = DefaultClientRepository(persistenceActor: actor, observationSignal: signal)
        var observation = await repository.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let destination = ClientFormDestination(id: UUID(), clientID: ClientID(rawValue: UUID()), mode: .create)
        let model = AppDependencies.makeClientFormViewModel(
            destination: destination,
            persistenceActor: actor,
            observationSignal: signal
        )
        model.fields.displayName = "  Contextual creation  "
        await model.save(in: container.mainContext)

        let visible = try #require(try await observation.next())
        #expect(visible.map(\.displayName) == ["Contextual creation"])
        #expect(visible.map(\.id) == [destination.clientID])
        #expect(visible.first?.status == .draft)
        #expect(try await actor.pendingOperations().count == 1)
        let stored = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first)
        #expect(try stored.toDomain() == visible.first)
    }

    @Test
    func `editing and deactivating preserve consent while sharing the local causal chain`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ClientPersistenceActor(modelContainer: container)
        let signal = ClientObservationSignal()
        let original = Client(
            id: ClientID(rawValue: UUID()),
            displayName: "Before edit",
            taxIdentifier: "SYNTHETIC-FORM",
            billingAddress: BillingAddress(
                streetLine: "Fixture street",
                postalCode: "00000",
                city: "Fixture city",
                province: "Fixture province"
            ),
            status: .active(consentReference: try ClientConsentReference(rawValue: "fixture-consent/form"))
        )
        try ClientLocalDataSource().upsert(original, in: ModelContext(container))
        let repository = DefaultClientRepository(persistenceActor: actor, observationSignal: signal)
        var observation = await repository.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == [original])
        let editing = AppDependencies.makeClientFormViewModel(
            destination: ClientFormDestination(id: UUID(), clientID: original.id, mode: .edit),
            persistenceActor: actor,
            observationSignal: signal
        )
        await editing.load()
        #expect(editing.fields.displayName == "Before edit")
        editing.fields.displayName = "After edit"
        await editing.save(in: container.mainContext)
        let edited = try #require(try await observation.next()?.first)
        #expect(edited.displayName == "After edit")
        #expect(edited.status == original.status)
        #expect(edited.taxIdentifier == original.taxIdentifier)
        #expect(edited.billingAddress == original.billingAddress)

        let deactivating = AppDependencies.makeClientFormViewModel(
            destination: ClientFormDestination(id: UUID(), clientID: original.id, mode: .edit),
            persistenceActor: actor,
            observationSignal: signal
        )
        await deactivating.load()
        await deactivating.deactivate(in: container.mainContext)
        #expect(deactivating.state == .deactivated)
        #expect(try await observation.next() == [])
        #expect(try await actor.pendingOperations().count == 2)
        let retained = try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first)
        #expect(try retained.toDomain() == edited)
    }
}
