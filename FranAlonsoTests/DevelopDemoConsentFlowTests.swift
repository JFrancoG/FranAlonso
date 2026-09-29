import Foundation
import SwiftData
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Reusable Develop demo consent flow")
@MainActor
struct DevelopDemoConsentFlowTests {
    @Test
    func `normal demo signs renders sends and activates once through the real form`() async throws {
        let session = try await DemoTestSession.make(configuration: .clients)
        defer { session.observation.cancel() }
        let form = try await retainedForm(session)
        let retained = try #require(form.consentStore?.delivery)
        #expect(form.loadedClient?.status == .draft)
        #expect(retained.document.fields.pdf.starts(with: Data("%PDF".utf8)))
        await form.performConsent(.upload)

        let uploaded = try #require(form.consentStore?.delivery)
        guard case .uploaded(let receipt) = uploaded.state else {
            Issue.record("The normal demo must retain a simulated receipt")
            return
        }
        #expect(form.loadedClient?.status == .active(consentReference: receipt.reference))
        #expect(uploaded.document == retained.document)
        #expect(await session.demo.documentRemoteStore.documentCount == 1)
        #expect(await session.demo.documentRemoteStore.document(
            documentID: retained.id, principalID: DevelopAuthenticationFixture.principalID
        ) == retained.document)
        await form.performConsent(.upload)
        #expect(await session.demo.documentRemoteStore.documentCount == 1)
        #expect(try activeOperationCount(session) == 1)
    }

    @Test
    func `lost response keeps one artifact and reopens against the same simulated acceptance`() async throws {
        let session = try await DemoTestSession.make(configuration: .clientsResponseLost)
        defer { session.observation.cancel() }
        let form = try await retainedForm(session)
        let retained = try #require(form.consentStore?.delivery)
        let clientID = form.destination.clientID
        await form.performConsent(.upload)
        #expect(form.consentStore?.failure == .unavailable)
        #expect(form.loadedClient?.status == .consentPendingUpload)
        #expect(form.consentStore?.delivery?.document == retained.document)
        #expect(await session.demo.documentRemoteStore.documentCount == 1)
        let firstReceipt = try #require(await session.demo.documentRemoteStore.receipt(
            documentID: retained.id, principalID: DevelopAuthenticationFixture.principalID
        ))
        form.close()

        let reopened = session.form(clientID: clientID, mode: .edit)
        await reopened.load()
        #expect(reopened.consentStore?.delivery?.document == retained.document)
        await reopened.performConsent(.upload)
        #expect(reopened.consentStore?.failure == nil)
        #expect(reopened.consentStore?.delivery?.state == .uploaded(firstReceipt))
        #expect(reopened.loadedClient?.status == .active(consentReference: firstReceipt.reference))
        #expect(await session.demo.documentRemoteStore.documentCount == 1)
        #expect(try activeOperationCount(session) == 1)
    }

    @Test
    func `response loss is consumed once per composition and a restart restores it`() async throws {
        let first = try await DemoTestSession.make(configuration: .clientsResponseLost)
        defer { first.observation.cancel() }
        let firstForm = try await retainedForm(first)
        await firstForm.performConsent(.upload)
        #expect(firstForm.consentStore?.failure == .unavailable)
        await firstForm.performConsent(.upload)
        #expect(firstForm.consentStore?.failure == nil)
        let secondClientForm = try await retainedForm(first, clientIndex: 1)
        await secondClientForm.performConsent(.upload)
        #expect(secondClientForm.consentStore?.delivery?.state.isUploaded == true)
        #expect(await first.demo.documentRemoteStore.documentCount == 2)

        let restarted = try await DemoTestSession.make(configuration: .clientsResponseLost)
        defer { restarted.observation.cancel() }
        #expect(await restarted.demo.documentRemoteStore.documentCount == 0)
        #expect(try restarted.clients().allSatisfy { $0.status == .draft })
        let restartedForm = try await retainedForm(restarted)
        await restartedForm.performConsent(.upload)
        #expect(restartedForm.consentStore?.failure == .unavailable)
        #expect(restartedForm.loadedClient?.status == .consentPendingUpload)
        #expect(await restarted.demo.documentRemoteStore.documentCount == 1)
        #expect(await first.demo.documentRemoteStore.documentCount == 2)
    }

    private func retainedForm(_ session: DemoTestSession, clientIndex: Int = 0) async throws -> ClientFormViewModel {
        let clients = try session.clients()
        let client = try #require(clients.dropFirst(clientIndex).first)
        let form = session.form(clientID: client.id, mode: .edit)
        await form.load()
        await form.performConsent(.review)
        let captureID = try #require(form.beginConsentCapture())
        let signature = try ClientSignature(strokes: [[.init(x: 0.1, y: 0.2), .init(x: 0.8, y: 0.7)]])
        await form.performConsent(.captured(.captured(signature), captureID))
        await form.performConsent(.accept)
        #expect(form.consentStore?.failure == nil)
        #expect(form.consentStore?.delivery?.document.fields.binding.signature == signature)
        return form
    }

    private func activeOperationCount(_ session: DemoTestSession) throws -> Int {
        let operations = try ClientLocalDataSource().pendingOperations(
            in: ModelContext(session.composition.modelContainer)
        )
        return operations.filter { operation in
            guard case .upsert(let upsert) = operation else { return false }
            return upsert.client.status == .active
        }.count
    }
}
#endif
