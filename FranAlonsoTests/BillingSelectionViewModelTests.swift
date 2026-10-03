import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing selection form")
@MainActor
struct BillingSelectionViewModelTests {
    @Test(arguments: [true, false])
    func `a late accepted prefill reconciles validation only when the draft changes`(
        _ changesInput: Bool
    ) async throws {
        let client = changesInput ? billingFormClient() : Client.draft(id: billingFormClient().id, displayName: "")
        let gate = RecoveryOperationGate()
        let clients = BillingFormClientRepository(client: client, gate: gate)
        let repository = BillingPresentationRepository()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument, clientID: client.id),
            reserve: ReserveBillingDocumentUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients)
        )
        model.selectKind(.invoice)
        let load = Task {
            await model.loadRecipient()
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        #expect(model.isLoadingRecipient)
        #expect(model.prepareSelection() == nil)
        #expect(model.formIssue == .required(.displayName))
        let validation = try #require(model.validationID)
        await gate.release()
        await load.value

        if changesInput {
            #expect(model.fieldValue(.displayName) == "Synthetic Recipient")
            #expect(model.fieldValue(.taxIdentifier) == "Synthetic Tax ID")
            #expect(model.formIssue == nil)
            #expect(model.validationID == nil)
        } else {
            #expect(model.fieldValue(.displayName).isEmpty)
            #expect(model.formIssue == .required(.displayName))
            #expect(model.validationID == validation)
        }
        #expect(model.request == nil)
        #expect(!model.isLoadingRecipient)
        #expect(await clients.reads == 1)
        #expect(await clients.writes == 0)
        #expect(await repository.received.isEmpty)
    }

    @Test
    func `an unchanged field write preserves the required error and its validation focus intention`() throws {
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument),
            reserve: ReserveBillingDocumentUseCase(repository: BillingPresentationRepository())
        )
        model.selectKind(.invoice)
        model.updateField(.displayName, value: "Manual Recipient")
        #expect(model.prepareSelection() == nil)
        let validation = try #require(model.validationID)
        #expect(model.formIssue == .required(.taxIdentifier))
        model.updateField(.taxIdentifier, value: "")
        #expect(model.formIssue == .required(.taxIdentifier))
        #expect(model.validationID == validation)
        model.updateField(.displayName, value: "Manual Recipient")
        #expect(model.formIssue == .required(.taxIdentifier))
        model.updateField(.taxIdentifier, value: "Corrected identifier")
        #expect(model.formIssue == nil)
    }

    @Test
    func `ticket preparation seals once without contacting the numbering authority or closing the sale`() async throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let repository = BillingPresentationRepository()
        let model = BillingViewModel(sale: sale, reserve: ReserveBillingDocumentUseCase(repository: repository))
        model.updateField(.displayName, value: "Unused invoice data")

        let prepared = try #require(model.prepareSelection())
        #expect(prepared.sale == sale)
        #expect(prepared.kind == .ticket)
        #expect(prepared.fiscalRecipient == nil)
        #expect(model.prepareSelection() == prepared)
        model.selectKind(.invoice)
        model.updateField(.displayName, value: "Replacement")
        #expect(model.request == prepared)
        #expect(model.selectedKind == .ticket)
        #expect(model.fieldValue(.displayName).isEmpty)
        model.close()
        #expect(model.request == prepared)
        #expect(model.prepareSelection() == nil)
        #expect(await repository.received.isEmpty)
        #expect(WorkdaySalesPolicy()([prepared.sale]).awaitingClosure.map(\.id) == [sale.id])
    }

    @Test
    func `invoice errors retain entered text and repeated validation publishes the first required field`() throws {
        let repository = BillingPresentationRepository()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument),
            reserve: ReserveBillingDocumentUseCase(repository: repository)
        )
        model.selectKind(.invoice)
        model.updateField(.displayName, value: "   ")
        #expect(model.prepareSelection() == nil)
        #expect(model.formIssue == .required(.displayName))
        #expect(model.fieldValue(.displayName) == "   ")
        let firstAttempt = try #require(model.validationID)
        #expect(model.prepareSelection() == nil)
        #expect(model.validationID != firstAttempt)
        model.updateField(.displayName, value: "Manual Recipient")
        #expect(model.prepareSelection() == nil)
        #expect(model.formIssue == .required(.taxIdentifier))
        #expect(model.request == nil)
    }

    @Test
    func `a corrected invoice keeps its exact fiscal snapshot after later editing and cancellation`() async throws {
        let repository = BillingPresentationRepository()
        let sale = try viewModelSale(stage: .awaitingDocument)
        let model = BillingViewModel(sale: sale, reserve: ReserveBillingDocumentUseCase(repository: repository))
        model.selectKind(.invoice)
        populateBillingForm(model)
        let prepared = try #require(model.prepareSelection())
        let recipient = try #require(prepared.fiscalRecipient)
        #expect(recipient.displayName == "Manual Recipient")
        #expect(recipient.billingAddress.postalCode == "XY 99")
        model.updateField(.city, value: "Changed city")
        model.selectKind(.ticket)
        #expect(model.request == prepared)
        #expect(model.fieldValue(.city) == "Manual City")
        model.close()
        #expect(model.request == prepared)
        #expect(await repository.received.isEmpty)
        #expect(WorkdaySalesPolicy()([prepared.sale]).awaitingClosure.map(\.id) == [sale.id])
    }

    @Test
    func `cancel before preparation clears fiscal editing and parent revocation prevents preparation`() async throws {
        let repository = BillingPresentationRepository()
        let availability = BillingFormAvailability()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument),
            reserve: ReserveBillingDocumentUseCase(repository: repository),
            canPrepare: { availability.value }
        )
        model.selectKind(.invoice)
        populateBillingForm(model)
        availability.value = false
        #expect(model.prepareSelection() == nil)
        #expect(model.formIssue == .unavailable)
        #expect(model.request == nil)
        model.close()
        #expect(model.fieldValue(.displayName).isEmpty)
        model.updateField(.displayName, value: "After close")
        #expect(model.fieldValue(.displayName).isEmpty)
        #expect(await repository.received.isEmpty)
    }

    @Test
    func `client prefill reads only its matching identity and never updates the client or reserves`() async throws {
        let client = billingFormClient()
        let clients = BillingFormClientRepository(client: client)
        let repository = BillingPresentationRepository()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument, clientID: client.id),
            reserve: ReserveBillingDocumentUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients)
        )
        await model.loadRecipient()
        #expect(await clients.reads == 0)
        model.selectKind(.invoice)
        await model.loadRecipient()
        #expect(model.fieldValue(.displayName) == "Synthetic Recipient")
        #expect(model.fieldValue(.postalCode) == "AB 12")
        let prepared = try #require(model.prepareSelection())
        #expect(prepared.fiscalRecipient?.billingAddress.city == "Synthetic City")
        #expect(await clients.reads == 1)
        #expect(await clients.writes == 0)
        #expect(await repository.received.isEmpty)
    }

    @Test
    func `an unrelated client response cannot populate another sales fiscal recipient`() async throws {
        let clients = BillingFormClientRepository(client: billingFormClient(index: 6_002))
        let repository = BillingPresentationRepository()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument, clientID: billingFormClient().id),
            reserve: ReserveBillingDocumentUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients)
        )
        model.selectKind(.invoice)
        await model.loadRecipient()
        #expect(model.fieldValue(.displayName).isEmpty)
        #expect(model.fieldValue(.taxIdentifier).isEmpty)
        #expect(model.prepareSelection() == nil)
        #expect(await clients.writes == 0)
    }

    @Test(arguments: BillingPrefillRevocation.allCases)
    func `late prefill never replaces manual or sealed input and cannot reopen a revoked session`(
        _ revocation: BillingPrefillRevocation
    ) async throws {
        let client = billingFormClient()
        let gate = RecoveryOperationGate()
        let clients = BillingFormClientRepository(client: client, gate: gate)
        let repository = BillingPresentationRepository()
        let availability = BillingFormAvailability()
        let model = BillingViewModel(
            sale: try viewModelSale(stage: .awaitingDocument, clientID: client.id),
            reserve: ReserveBillingDocumentUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients),
            canPrepare: { availability.value }
        )
        model.selectKind(.invoice)
        let load = Task {
            await model.loadRecipient()
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        switch revocation {
        case .edited:
            model.updateField(.displayName, value: "Manual Recipient")
        case .ticket:
            model.selectKind(.ticket)
        case .closed:
            model.close()
        case .prepared:
            populateBillingForm(model)
            _ = try #require(model.prepareSelection())
        case .parentClosed:
            availability.value = false
        }
        await gate.release()
        await load.value
        #expect(!model.isLoadingRecipient)
        if revocation == .edited || revocation == .prepared {
            #expect(model.fieldValue(.displayName) == "Manual Recipient")
        } else {
            #expect(model.fieldValue(.displayName).isEmpty)
        }
        #expect(await repository.received.isEmpty)
        #expect(await clients.writes == 0)
    }
}
