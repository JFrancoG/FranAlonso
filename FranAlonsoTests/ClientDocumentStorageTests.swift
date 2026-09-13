import Foundation
import Testing
@testable import FranAlonso

@Suite("Immutable client document Storage")
struct ClientDocumentStorageTests {
    @Test
    func `retry after repository recreation recovers the exact document and receipt`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let document = try await document()
        let first = try await InMemoryClientDocumentStorage(remote: remote).upload(document, principalID: "principal-A")
        let recovered = try await InMemoryClientDocumentStorage(remote: remote).upload(
            document,
            principalID: "principal-A"
        )

        #expect(recovered == first)
        #expect(recovered.matches(documentID: document.id, principalID: "principal-A"))
        #expect(await remote.documentCount == 1)
        #expect(await remote.document(documentID: document.id, principalID: "principal-A") == document)
    }

    @Test
    func `concurrent equal uploads have one stable acknowledgement`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let document = try await document()
        let receipts = try await withThrowingTaskGroup(of: ClientDocumentUploadReceipt.self) { group in
            for _ in 0..<12 {
                group.addTask {
                    try await InMemoryClientDocumentStorage(remote: remote).upload(document, principalID: "principal-A")
                }
            }
            var receipts: [ClientDocumentUploadReceipt] = []
            for try await receipt in group {
                receipts.append(receipt)
            }
            return receipts
        }

        let accepted = try #require(receipts.first)
        #expect(receipts.count == 12)
        #expect(receipts.allSatisfy { $0 == accepted })
        #expect(await remote.documentCount == 1)
    }

    @Test(arguments: [Mutation.pdf, .signedAt, .signature, .clientName, .content, .photoDecision, .clientID])
    func `any different signed field conflicts without replacing the original`(mutation: Mutation) async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote)
        let original = try await document()
        let changed = try await document(mutation: mutation)
        let receipt = try await storage.upload(original, principalID: "principal-A")

        await #expect(throws: ClientDocumentStorageError.conflict) {
            try await storage.upload(changed, principalID: "principal-A")
        }

        #expect(await remote.documentCount == 1)
        #expect(await remote.document(documentID: original.id, principalID: "principal-A") == original)
        #expect(try await storage.upload(original, principalID: "principal-A") == receipt)
    }

    @Test
    func `competing different payloads create one document and reject the other`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let original = try await document()
        let changed = try await document(mutation: .pdf)
        let outcomes = await withTaskGroup(of: Result<ClientDocumentUploadReceipt, ClientDocumentStorageError>.self) {
            group in
            for document in [original, changed] {
                group.addTask {
                    do {
                        return .success(try await InMemoryClientDocumentStorage(remote: remote).upload(
                            document,
                            principalID: "principal-A"
                        ))
                    } catch let error as ClientDocumentStorageError {
                        return .failure(error)
                    } catch {
                        Issue.record(error)
                        return .failure(.unavailable)
                    }
                }
            }
            var outcomes: [Result<ClientDocumentUploadReceipt, ClientDocumentStorageError>] = []
            for await outcome in group {
                outcomes.append(outcome)
            }
            return outcomes
        }

        #expect(outcomes.filter {
            if case .success = $0 {
                true
            } else {
                false
            }
        }.count == 1)
        #expect(outcomes.filter {
            if case .failure(.conflict) = $0 {
                true
            } else {
                false
            }
        }.count == 1)
        let accepted = try #require(await remote.document(documentID: original.id, principalID: "principal-A"))
        #expect(accepted == original || accepted == changed)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `equal document identifiers remain separate for different principals`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote)
        let original = try await document()
        let other = try await document(mutation: .pdf)
        let first = try await storage.upload(original, principalID: "principal-A")
        let second = try await storage.upload(other, principalID: "principal-B")

        #expect(first.reference != second.reference)
        #expect(!second.matches(documentID: original.id, principalID: "principal-A"))
        #expect(await remote.document(documentID: original.id, principalID: "principal-A") == original)
        #expect(await remote.document(documentID: other.id, principalID: "principal-B") == other)
        #expect(await remote.documentCount == 2)
    }

    @Test(arguments: [
        (InMemoryClientDocumentStorage.Failure.permissionDenied, ClientDocumentStorageError.permissionDenied),
        (.unavailable, .unavailable)
    ])
    func `access and availability failures retain no remote value and allow explicit retry`(
        failure: InMemoryClientDocumentStorage.Failure,
        expected: ClientDocumentStorageError
    ) async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [failure])
        let document = try await document()

        await #expect(throws: expected) {
            try await storage.upload(document, principalID: "principal-A")
        }
        #expect(await remote.documentCount == 0)
        let receipt = try await storage.upload(document, principalID: "principal-A")
        #expect(receipt.matches(documentID: document.id, principalID: "principal-A"))
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `response loss preserves remote acceptance and recovers its original receipt`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [.responseLost])
        let document = try await document()

        await #expect(throws: ClientDocumentStorageError.unavailable) {
            try await storage.upload(document, principalID: "principal-A")
        }
        let accepted = try #require(await remote.receipt(documentID: document.id, principalID: "principal-A"))
        let recovered = try await InMemoryClientDocumentStorage(remote: remote).upload(
            document,
            principalID: "principal-A"
        )

        #expect(recovered == accepted)
        #expect(await remote.document(documentID: document.id, principalID: "principal-A") == document)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `cancellation before acceptance creates nothing and allows retry`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [.cancelledBeforeAcceptance])
        let document = try await document()

        await #expect(throws: CancellationError.self) {
            try await storage.upload(document, principalID: "principal-A")
        }
        #expect(await remote.documentCount == 0)
        let receipt = try await storage.upload(document, principalID: "principal-A")
        #expect(receipt.matches(documentID: document.id, principalID: "principal-A"))
    }

    @Test
    func `cancellation after acceptance reports no success and retains the remote receipt`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [.cancelledAfterAcceptance])
        let document = try await document()

        await #expect(throws: CancellationError.self) {
            try await storage.upload(document, principalID: "principal-A")
        }
        let accepted = try #require(await remote.receipt(documentID: document.id, principalID: "principal-A"))
        #expect(try await storage.upload(document, principalID: "principal-A") == accepted)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `a cancelled calling task cannot create a remote document`() async throws {
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(remote: remote)
        let document = try await document()

        await #expect(throws: CancellationError.self) {
            try await withThrowingTaskGroup(of: ClientDocumentUploadReceipt.self) { group in
                group.cancelAll()
                group.addTask {
                    try await storage.upload(document, principalID: "principal-A")
                }
                try await group.waitForAll()
            }
        }
        #expect(await remote.documentCount == 0)
    }

    @Test
    func `receipt correlation rejects an acknowledgement for another document`() async throws {
        let storage = InMemoryClientDocumentStorage()
        let document = try await document()
        let receipt = try await storage.upload(document, principalID: "principal-A")

        #expect(!receipt.matches(
            documentID: UUID(uuidString: "00000000-0000-0000-0000-000000000086")!,
            principalID: "principal-A"
        ))
    }

    enum Mutation {
        case pdf, signedAt, signature, clientName, content, photoDecision, clientID
    }

    private func document(mutation: Mutation? = nil) async throws -> ClientSignedDocument {
        let initial = try await ClientDocumentTestFixtures.snapshot()
        var fields = initial.fields
        var signature = try ClientDocumentTestFixtures.binding(initial).signature
        var signedAt = ClientDocumentTestFixtures.date
        var pdf = Data("%PDF-1.7\nSynthetic accepted artifact\n%%EOF".utf8)
        switch mutation {
        case .pdf:
            pdf = Data("%PDF-1.7\nDifferent synthetic artifact\n%%EOF".utf8)
        case .signedAt:
            signedAt = Date(timeIntervalSince1970: 1_800_000_001)
        case .signature:
            signature = try ClientSignature(strokes: [[.init(x: 0.2, y: 0.3), .init(x: 0.8, y: 0.5)]])
        case .clientName:
            fields = .init(
                id: fields.id,
                clientID: fields.clientID,
                clientName: "Nombre sintético cambiado",
                context: fields.context,
                content: fields.content
            )
        case .content:
            let content = fields.content.fields
            fields = .init(
                id: fields.id,
                clientID: fields.clientID,
                clientName: fields.clientName,
                context: fields.context,
                content: try ClientDocumentContent(.init(
                    version: "different-synthetic-version",
                    language: content.language,
                    title: content.title,
                    reviewNotice: content.reviewNotice,
                    sections: content.sections,
                    photoAuthorization: content.photoAuthorization,
                    signatureNotice: content.signatureNotice,
                    labels: content.labels
                ))
            )
        case .photoDecision:
            fields = try await ClientDocumentTestFixtures.snapshot(decision: .authorized).fields
        case .clientID:
            fields = .init(
                id: fields.id,
                clientID: ClientID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!),
                clientName: fields.clientName,
                context: fields.context,
                content: fields.content
            )
        case nil:
            break
        }
        return try ClientSignedDocument(.init(
            binding: ClientDocumentSignature(snapshot: ClientDocumentSnapshot(fields), signature: signature),
            signedAt: signedAt,
            pdf: pdf
        ))
    }
}
