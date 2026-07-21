import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Model container factory")
struct ModelContainerFactoryTests {
    @Test("In-memory container persists explicit CRUD saves")
    func inMemoryContainerPersistsExplicitCRUDSaves() throws {
        let schema = Schema([PersistenceFixtureModel.self])
        let container = try ModelContainerFactory.makeInMemory(for: schema)
        let configuration = try #require(container.configurations.first)

        #expect(container.configurations.count == 1)
        #expect(configuration.isStoredInMemoryOnly)
        #expect(configuration.allowsSave)
        #expect(configuration.groupAppContainerIdentifier == nil)
        #expect(configuration.cloudKitContainerIdentifier == nil)

        let identifier = try #require(
            UUID(uuidString: "DAA42E70-6D86-4C54-A916-C4FD845BC012")
        )
        let creationContext = ModelContext(container)
        creationContext.autosaveEnabled = false
        creationContext.insert(
            PersistenceFixtureModel(
                identifier: identifier,
                value: "created"
            )
        )

        #expect(creationContext.hasChanges)
        let beforeSaveContext = ModelContext(container)
        #expect(try beforeSaveContext.fetchCount(FetchDescriptor<PersistenceFixtureModel>()) == 0)

        try creationContext.save()
        #expect(!creationContext.hasChanges)

        let updateContext = ModelContext(container)
        let createdModel = try #require(
            try updateContext.fetch(FetchDescriptor<PersistenceFixtureModel>()).first
        )
        #expect(createdModel.identifier == identifier)
        #expect(createdModel.value == "created")

        createdModel.value = "updated"
        #expect(updateContext.hasChanges)
        try updateContext.save()

        let deletionContext = ModelContext(container)
        let updatedModel = try #require(
            try deletionContext.fetch(FetchDescriptor<PersistenceFixtureModel>()).first
        )
        #expect(updatedModel.value == "updated")

        deletionContext.delete(updatedModel)
        #expect(deletionContext.hasChanges)
        try deletionContext.save()

        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<PersistenceFixtureModel>()) == 0)
    }
}

@Model
final class PersistenceFixtureModel {
    var identifier: UUID
    var value: String

    init(identifier: UUID, value: String) {
        self.identifier = identifier
        self.value = value
    }
}
