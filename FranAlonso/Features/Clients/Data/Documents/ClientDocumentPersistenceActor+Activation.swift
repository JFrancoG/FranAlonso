import Foundation
import SwiftData

extension ClientDocumentPersistenceActor {
    /// Validates the initial document and stages pending activation without downgrading an active client.
    func prepareActivation(
        clientID: ClientID,
        documentID: UUID,
        operationID: UUID,
        principalID: String
    ) throws -> Client {
        try transaction {
            let (client, delivery) = try activationInputs(clientID: clientID, documentID: documentID)
            try validateReceipt(in: delivery, principalID: principalID)
            switch client.status {
            case .active(let reference):
                try requireInitialReference(reference, in: delivery)
                return client
            case .consentPendingUpload:
                return client
            case .draft:
                return try stageActivation(client, status: .consentPendingUpload, operationID: operationID)
            }
        }
    }

    /// Commits activation and its causal upsert atomically from the current persisted profile and receipt.
    func activate(
        clientID: ClientID,
        documentID: UUID,
        operationID: UUID,
        principalID: String
    ) throws -> Client {
        try transaction {
            let (client, delivery) = try activationInputs(clientID: clientID, documentID: documentID)
            try validateReceipt(in: delivery, principalID: principalID)
            guard case .uploaded(let receipt) = delivery.state else { throw ClientActivationError.uploadRequired }
            if case .active(let reference) = client.status {
                guard reference == receipt.reference else { throw ClientActivationError.differentInitialDocument }
                return client
            }
            return try stageActivation(
                client,
                status: .active(consentReference: receipt.reference),
                operationID: operationID
            )
        }
    }

    private func activationInputs(clientID: ClientID, documentID: UUID) throws -> (Client, ClientDocumentDelivery) {
        guard let document = try documentModel(id: documentID)?.toDomain() else {
            throw ClientDocumentPersistenceError.notFound
        }
        let snapshot = document.document.fields.binding.snapshot.fields
        guard snapshot.clientID == clientID, snapshot.context.purpose == .initialInformation else {
            throw ClientActivationError.invalidDocument
        }
        if case .conflict = document.state {
            throw ClientDocumentStorageError.conflict
        }
        let rawClientID = clientID.rawValue
        var profile = FetchDescriptor<ClientModel>(predicate: #Predicate { $0.id == rawClientID })
        profile.fetchLimit = 1
        guard try modelContext.fetch(profile).first != nil else { throw ClientError.notFound }
        guard let client = try ClientLocalDataSource().client(id: clientID, in: modelContext) else {
            throw ClientError.deactivated
        }
        var conflict = FetchDescriptor<ClientSyncConflictModel>(predicate: #Predicate { $0.clientID == rawClientID })
        conflict.fetchLimit = 1
        guard try modelContext.fetch(conflict).isEmpty else { throw ClientError.conflict }
        return (client, document)
    }

    private func validateReceipt(in delivery: ClientDocumentDelivery, principalID: String) throws {
        if case .uploaded(let receipt) = delivery.state {
            guard receipt.matches(documentID: delivery.id, principalID: principalID) else {
                throw ClientDocumentStorageError.invalidReceipt
            }
        }
    }

    private func requireInitialReference(
        _ reference: ClientConsentReference,
        in delivery: ClientDocumentDelivery
    ) throws {
        guard case .uploaded(let receipt) = delivery.state else { throw ClientActivationError.uploadRequired }
        guard reference == receipt.reference else { throw ClientActivationError.differentInitialDocument }
    }

    private func stageActivation(_ client: Client, status: ClientStatus, operationID: UUID) throws -> Client {
        let updated = Client(
            id: client.id,
            displayName: client.displayName,
            taxIdentifier: client.taxIdentifier,
            billingAddress: client.billingAddress,
            status: status
        )
        try ClientLocalDataSource().stagePendingUpsert(updated, operationID: operationID, in: modelContext)
        return updated
    }
}
