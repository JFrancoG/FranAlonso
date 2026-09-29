import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct ClientActivationFixtures {
    let container: ModelContainer
    let documents: DefaultClientDocumentRepository
    let activation: DefaultClientActivationRepository

    func useCase(storage: some ClientDocumentStorage) -> ActivateClientUseCase {
        ActivateClientUseCase(
            repository: activation,
            upload: ClientDocumentRecoveryFixtures.upload(documents, storage: storage),
            makeOperationID: { UUID() }
        )
    }

    func client() throws -> Client {
        try #require(ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first).toDomain()
    }

    func pending() throws -> [ClientPendingUpsert] {
        try ClientLocalDataSource().pendingUpserts(in: ModelContext(container))
    }

    static func uploaded(at url: URL) async throws -> ClientDocumentUploadReceipt {
        let fixtures = try ClientActivationFixtures(container: ClientDocumentPersistenceFixtures.container(at: url))
        let accepted = try await ClientDocumentRecoveryFixtures.accept(fixtures.documents)
        _ = try await fixtures.activation.prepareActivation(
            clientID: ClientDocumentTestFixtures.clientID,
            documentID: accepted.id,
            operationID: UUID()
        )
        return try await ClientDocumentRecoveryFixtures.upload(
            fixtures.documents,
            storage: InMemoryClientDocumentStorage()
        )(documentID: accepted.id)
    }

    func apply(_ blocker: ActivationBlocker, receipt: ClientDocumentUploadReceipt) throws {
        let context = ModelContext(container)
        let local = ClientLocalDataSource()
        switch blocker {
        case .documentConflict:
            let model = try #require(context.fetch(FetchDescriptor<ClientSignedDocumentModel>()).first)
            try model.setState(.conflict(receipt: receipt))
            try context.save()
        case .clientConflict:
            try local.recordConflict(
                operation: #require(local.pendingUpserts(in: context).last),
                reason: .baseChanged,
                remoteRecord: nil,
                in: context
            )
        case .deactivated:
            try local.deactivateClient(ClientDocumentTestFixtures.clientID, operationID: UUID(), in: context)
        }
    }
}

extension ClientActivationFixtures {
    init(container: ModelContainer, persistence: ClientDocumentPersistenceActor? = nil) {
        let documents = ClientDocumentRecoveryFixtures.repository(
            persistence: persistence ?? ClientDocumentPersistenceActor(modelContainer: container)
        )
        self.init(
            container: container,
            documents: documents,
            activation: DefaultClientActivationRepository(
                persistence: documents.persistence,
                access: documents.access,
                observationSignal: documents.observationSignal
            )
        )
    }
}

enum ActivationReceiptScenario {
    case missing, wrongDocument, wrongPrincipal
}

enum ActivationBlocker {
    case documentConflict, clientConflict, deactivated

    func matches(_ error: any Error) -> Bool {
        switch self {
        case .documentConflict: error as? ClientDocumentStorageError == .conflict
        case .clientConflict: error as? ClientError == .conflict
        case .deactivated: error as? ClientError == .deactivated
        }
    }
}
