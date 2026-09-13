import Foundation
import Testing
@testable import FranAlonso

@Suite("Signed document boundaries")
struct ClientDocumentContractTests {
    @Test(arguments: ["id", "client", "name", "purpose", "decision", "version", "language", "text", "variant"])
    func `every changed presentation invalidates previously captured ink`(change: String) async throws {
        let original = try await ClientDocumentTestFixtures.snapshot(decision: .authorized)
        let changed = try replacing(original, change: change)
        let renderer = FailingDocumentRenderer()
        await #expect(throws: ClientDocumentError.staleSignature) {
            try await RenderConsentUseCase(renderer: renderer, now: { ClientDocumentTestFixtures.date })(
                snapshot: changed,
                binding: ClientDocumentTestFixtures.binding(original)
            )
        }
        #expect(await renderer.calls == 0)
    }

    @Test
    func `decoding a pending photo cannot bypass the signature decision`() async throws {
        let pending = try await ClientDocumentTestFixtures.snapshot(decision: .undecided)
        struct Payload: Encodable {
            let snapshot: ClientDocumentSnapshot
            let signature: ClientSignature
        }
        let data = try JSONEncoder().encode(Payload(
            snapshot: pending,
            signature: ClientSignature(strokes: [[.init(x: 0, y: 0), .init(x: 1, y: 1)]])
        ))
        #expect(throws: ClientDocumentError.photoDecisionRequired) {
            try JSONDecoder().decode(ClientDocumentSignature.self, from: data)
        }
    }

    @Test
    func `decoding cannot attach photo authorization to a data-only decision`() async throws {
        let original = try await ClientDocumentTestFixtures.snapshot(decision: .authorized)
        let payload = ClientDocumentSnapshot.Fields(
            id: original.id,
            clientID: original.fields.clientID,
            clientName: original.fields.clientName,
            context: .init(purpose: .initialInformation, photoDecision: .notSelected),
            content: original.fields.content
        )
        let data = try JSONEncoder().encode(payload)
        #expect(throws: ClientDocumentError.invalidContext) {
            try JSONDecoder().decode(ClientDocumentSnapshot.self, from: data)
        }
    }

    @Test(arguments: [ClientDocumentPhotoDecision.declined, .notSelected])
    func `later authorization cannot silently become initial information`(decision: ClientDocumentPhotoDecision) async {
        await #expect(throws: ClientDocumentError.invalidContext) {
            try await ClientDocumentTestFixtures.snapshot(decision: decision, purpose: .subsequentPhotoAuthorization)
        }
    }

    @Test
    func `renderer failure remains an explicit failure and cannot create a record`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let renderer = FailingDocumentRenderer()
        await #expect(throws: ClientDocumentError.renderingFailed) {
            try await RenderConsentUseCase(renderer: renderer, now: { ClientDocumentTestFixtures.date })(
                snapshot: snapshot,
                binding: ClientDocumentTestFixtures.binding(snapshot)
            )
        }
        #expect(await renderer.calls == 1)
    }

    @Test
    func `pre-cancelled render never calls the PDF adapter`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let binding = try ClientDocumentTestFixtures.binding(snapshot)
        let renderer = FailingDocumentRenderer()
        await withTaskGroup(of: Bool.self) { group in
            group.cancelAll()
            group.addTask {
                do {
                    _ = try await RenderConsentUseCase(renderer: renderer, now: { ClientDocumentTestFixtures.date })(
                        snapshot: snapshot,
                        binding: binding
                    )
                    return false
                } catch is CancellationError {
                    return true
                } catch {
                    return false
                }
            }
            #expect(await group.next() == true)
        }
        #expect(await renderer.calls == 0)
    }

    @Test
    func `invalid signing time is refused before export`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let renderer = FailingDocumentRenderer()
        await #expect(throws: ClientDocumentError.invalidDate) {
            try await RenderConsentUseCase(renderer: renderer, now: { Date(timeIntervalSince1970: .infinity) })(
                snapshot: snapshot,
                binding: ClientDocumentTestFixtures.binding(snapshot)
            )
        }
        #expect(await renderer.calls == 0)
    }

    @Test
    func `decoding a truncated PDF does not create a historical document`() async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let payload = try ClientSignedDocument.Fields(
            binding: ClientDocumentTestFixtures.binding(snapshot),
            signedAt: ClientDocumentTestFixtures.date,
            pdf: Data("%PDF-1.3 truncated".utf8)
        )
        let data = try JSONEncoder().encode(payload)
        #expect(throws: ClientDocumentError.invalidArtifact) {
            try JSONDecoder().decode(ClientSignedDocument.self, from: data)
        }
    }

    private func replacing(_ snapshot: ClientDocumentSnapshot, change: String) throws -> ClientDocumentSnapshot {
        let old = snapshot.fields
        let text = old.content.fields
        let content = try ClientDocumentContent(.init(
            version: change == "version" ? "future-version" : text.version,
            language: change == "language" ? "en" : text.language,
            title: text.title,
            reviewNotice: text.reviewNotice,
            sections: change == "text" ? [.init(heading: "", body: "Otro contenido sintético")] : text.sections,
            photoAuthorization: change == "variant" ? nil : text.photoAuthorization,
            signatureNotice: text.signatureNotice,
            labels: text.labels
        ))
        let context = ClientDocumentContext(
            purpose: change == "purpose" ? .subsequentPhotoAuthorization : old.context.purpose,
            photoDecision: change == "variant" ? .notSelected : change == "decision" ? .undecided : .authorized
        )
        return try ClientDocumentSnapshot(.init(
            id: change == "id" ? UUID(uuidString: "00000000-0000-0000-0000-000000000086")! : old.id,
            clientID: change == "client" ? ClientID(rawValue: old.id) : old.clientID,
            clientName: change == "name" ? "Otra persona sintética" : old.clientName,
            context: context,
            content: content
        ))
    }
}

private actor FailingDocumentRenderer: ClientDocumentRenderer {
    private(set) var calls = 0

    func render(binding: ClientDocumentSignature, signedAt: Date) async throws -> Data {
        calls += 1
        throw CocoaError(.fileWriteUnknown)
    }
}
