import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client form coordination")
@MainActor
struct ClientFormViewModelTests {
    @Test
    func `failed edit loading blocks writes even after fields are filled`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        let model = makeModel(probe: probe, mode: .edit)
        await model.load()
        #expect(model.state == .failed(.load, .notFound))
        model.fields.displayName = "Cannot overwrite an unknown client"
        #expect(model.state == .failed(.load, .notFound))
        await model.save(in: container.mainContext)
        await model.deactivate(in: container.mainContext)
        #expect(probe.profiles.isEmpty)
        #expect(probe.deactivationCount == 0)
    }

    @Test
    func `invalid input stays editable and never reaches persistence`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        let model = makeModel(probe: probe)
        model.fields.displayName = " \n"
        await model.save(in: container.mainContext)
        #expect(model.state == .failed(.save, .invalidDisplayName))
        #expect(probe.profiles.isEmpty)

        model.fields.displayName = "  Valid name  "
        #expect(model.state == .editing)
        #expect(model.fields.displayName == "  Valid name  ")
        #expect(probe.profiles.isEmpty)
        await model.save(in: container.mainContext)
        #expect(probe.profiles.map(\.displayName) == ["Valid name"])
        guard case .saved(let client) = model.state else {
            Issue.record("Expected the corrected draft to be accepted")
            return
        }
        #expect(client.status == .draft)
    }

    @Test(arguments: ["", " \n\t"])
    func `name validation remains until the name is valid`(invalidName: String) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        let model = makeModel(probe: probe)
        model.fields.displayName = " "
        await model.save(in: container.mainContext)

        model.fields.city = "Sevilla"
        #expect(model.state == .failed(.save, .invalidDisplayName))
        model.fields.displayName = invalidName
        #expect(model.state == .failed(.save, .invalidDisplayName))
        #expect(probe.profiles.isEmpty)

        model.close()
        model.fields.displayName = "Valid after closing"
        #expect(model.state == .closed)
    }

    @Test
    func `a failed write preserves fields and retries the same client identity`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.failure = ClientError.persistenceUnavailable
        let model = makeModel(probe: probe)
        model.fields.displayName = "Draft to keep"
        model.fields.city = "Sevilla"
        let originalFields = model.fields
        await model.save(in: container.mainContext)
        #expect(model.state == .failed(.save, .persistenceUnavailable))
        #expect(model.fields == originalFields)

        model.fields.displayName = "Revised draft"
        #expect(model.state == .failed(.save, .persistenceUnavailable))
        probe.failure = nil
        await model.save(in: container.mainContext)
        #expect(probe.identities == [model.destination.clientID, model.destination.clientID])
        guard case .saved = model.state else {
            Issue.record("Expected retry to accept the retained draft")
            return
        }
    }

    @Test
    func `a pending write rejects another submission and uses its captured fields`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.suspends = true
        let model = makeModel(probe: probe)
        model.fields.displayName = "Accepted draft"
        let saving = Task {
            await model.save(in: container.mainContext)
        }
        await probe.waitUntilStarted()
        #expect(model.state == .saving)
        model.fields.displayName = "Later typing"
        #expect(model.state == .saving)
        await model.save(in: container.mainContext)
        #expect(probe.profiles.map(\.displayName) == ["Accepted draft"])
        probe.release()
        await saving.value
        guard case .saved(let client) = model.state else {
            Issue.record("Expected first write to complete")
            return
        }
        #expect(client.displayName == "Accepted draft")
        #expect(probe.identities.count == 1)
    }

    @Test(arguments: [FormTestOperation.save, .deactivate])
    func `cancellation before delegation leaves the draft and storage untouched`(
        operation: FormTestOperation
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        let model = await loadedEditModel(probe: probe)
        let originalFields = model.fields
        let task = Task {
            await perform(operation, model: model, container: container)
        }
        task.cancel()
        await task.value
        #expect(model.fields == originalFields)
        #expect(model.state == .editing)
        #expect(probe.profiles.isEmpty)
        #expect(probe.deactivationCount == 0)
    }

    @Test(arguments: [FormTestOperation.save, .deactivate])
    func `cooperative operation cancellation keeps the fields without a failure`(
        operation: FormTestOperation
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.failure = CancellationError()
        let model = await loadedEditModel(probe: probe)
        let originalFields = model.fields
        await perform(operation, model: model, container: container)
        #expect(model.state == .editing)
        #expect(model.fields == originalFields)
    }

    @Test(arguments: [FormTestOperation.save, .deactivate])
    func `accepted operations remain successful when the caller was cancelled`(
        operation: FormTestOperation
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.suspends = true
        let model = await loadedEditModel(probe: probe)
        let task = Task {
            await perform(operation, model: model, container: container)
        }
        await probe.waitUntilStarted()
        task.cancel()
        probe.release()
        await task.value
        if operation == .deactivate {
            #expect(model.state == .deactivated)
        } else if case .saved(let client) = model.state {
            #expect(client.id == model.destination.clientID)
        } else {
            Issue.record("Cancellation after durable acceptance must not discard success")
        }
    }

    @Test(arguments: [FormTestOperation.save, .deactivate])
    func `a late mutation response cannot reopen a closed form`(operation: FormTestOperation) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.suspends = true
        let model = await loadedEditModel(probe: probe)
        let task = Task {
            await perform(operation, model: model, container: container)
        }
        await probe.waitUntilStarted()
        model.close()
        probe.release()
        await task.value
        #expect(model.state == .closed)
    }

    @Test
    func `deactivation rejects overlapping and repeated requests`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        probe.suspends = true
        let model = await loadedEditModel(probe: probe)
        let task = Task {
            await model.deactivate(in: container.mainContext)
        }
        await probe.waitUntilStarted()
        await model.deactivate(in: container.mainContext)
        await model.save(in: container.mainContext)
        probe.release()
        await task.value
        await model.deactivate(in: container.mainContext)
        #expect(probe.deactivationCount == 1)
        #expect(probe.profiles.isEmpty)
        #expect(model.state == .deactivated)
    }

    @Test
    func `new drafts cannot invoke deactivation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let probe = FormWriteProbe()
        let model = makeModel(probe: probe)
        await model.deactivate(in: container.mainContext)
        #expect(probe.deactivationCount == 0)
        #expect(model.state == .editing)
    }

    @Test(arguments: [FormReadOutcome.profile, .failure, .cancelled])
    func `a replaced read cannot overwrite the current editable profile`(outcome: FormReadOutcome) async {
        let current = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Current profile")
        let repository = DelayedFormRepository(current: current)
        let model = makeModel(
            probe: FormWriteProbe(),
            mode: .edit,
            repository: repository,
            clientID: current.id
        )
        let first = Task {
            await model.load()
        }
        await repository.waitUntilStarted()
        await model.load()
        if outcome == .cancelled {
            first.cancel()
        }
        await repository.release(outcome)
        await first.value
        #expect(model.fields.displayName == "Current profile")
        #expect(model.state == .editing)
    }

    @Test
    func `cancelling the current read discards its noncooperative result`() async {
        let client = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Cancelled profile")
        let repository = DelayedFormRepository(current: client)
        let model = makeModel(
            probe: FormWriteProbe(),
            mode: .edit,
            repository: repository,
            clientID: client.id
        )
        let task = Task {
            await model.load()
        }
        await repository.waitUntilStarted()
        task.cancel()
        await repository.release(.profile)
        await task.value
        #expect(model.state == .idle)
        #expect(model.fields.displayName.isEmpty)
    }

    @Test
    func `closing during loading leaves the late profile unpresented`() async {
        let current = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Current profile")
        let repository = DelayedFormRepository(current: current)
        let model = makeModel(
            probe: FormWriteProbe(),
            mode: .edit,
            repository: repository,
            clientID: current.id
        )
        let task = Task {
            await model.load()
        }
        await repository.waitUntilStarted()
        model.close()
        await repository.release(.profile)
        await task.value
        #expect(model.state == .closed)
        #expect(model.fields.displayName.isEmpty)
    }

    @Test
    func `retry loads a previously missing profile and later loads preserve edits`() async throws {
        let repository = InMemoryClientRepository()
        let probe = FormWriteProbe()
        let id = ClientID(rawValue: UUID())
        let model = makeModel(
            probe: probe,
            mode: .edit,
            repository: repository,
            clientID: id
        )
        await model.load()
        #expect(model.state == .failed(.load, .notFound))
        _ = try await repository.createClient(id: id, profile: ClientProfile(displayName: "Recovered profile"))
        await model.load()
        #expect(model.fields.displayName == "Recovered profile")
        model.fields.displayName = "Unsaved editing"
        await model.load()
        #expect(model.fields.displayName == "Unsaved editing")
        #expect(model.state == .editing)
    }

    private func loadedEditModel(probe: FormWriteProbe) async -> ClientFormViewModel {
        let client = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Existing profile")
        let model = makeModel(
            probe: probe,
            mode: .edit,
            repository: InMemoryClientRepository(clients: [client]),
            clientID: client.id
        )
        await model.load()
        return model
    }

    private func makeModel(
        probe: FormWriteProbe,
        mode: ClientFormDestination.Mode = .create,
        repository: any ClientRepository = InMemoryClientRepository(),
        clientID: ClientID = ClientID(rawValue: UUID())
    ) -> ClientFormViewModel {
        ClientFormViewModel(
            destination: ClientFormDestination(id: UUID(), clientID: clientID, mode: mode),
            getClient: GetClientUseCase(repository: repository),
            create: { id, profile, _ in
                try await probe.write(id: id, profile: profile)
            },
            update: { id, profile, _ in
                try await probe.write(id: id, profile: profile)
            },
            deactivate: { _, _ in
                try await probe.deactivate()
            }
        )
    }

    private func perform(_ operation: FormTestOperation, model: ClientFormViewModel, container: ModelContainer) async {
        switch operation {
        case .save:
            await model.save(in: container.mainContext)
        case .deactivate:
            await model.deactivate(in: container.mainContext)
        }
    }
}

enum FormTestOperation {
    case save
    case deactivate
}

enum FormReadOutcome {
    case profile
    case failure
    case cancelled
}

@MainActor
private final class FormWriteProbe {
    var suspends = false
    var failure: (any Error)?
    private(set) var profiles: [ClientProfile] = []
    private(set) var identities: [ClientID] = []
    private(set) var deactivationCount = 0
    private var pending: CheckedContinuation<Void, Never>?
    private var entered: CheckedContinuation<Void, Never>?

    func write(id: ClientID, profile: ClientProfile) async throws -> Client {
        profiles.append(profile)
        identities.append(id)
        await suspendIfRequested()
        if let failure {
            throw failure
        }
        return Client(
            id: id,
            displayName: profile.displayName,
            taxIdentifier: profile.taxIdentifier,
            billingAddress: profile.billingAddress,
            status: .draft
        )
    }

    func deactivate() async throws {
        deactivationCount += 1
        await suspendIfRequested()
        if let failure {
            throw failure
        }
    }

    func waitUntilStarted() async {
        guard pending == nil else { return }
        await withCheckedContinuation {
            entered = $0
        }
    }

    func release() {
        pending?.resume()
        pending = nil
    }

    private func suspendIfRequested() async {
        guard suspends else { return }
        await withCheckedContinuation { continuation in
            pending = continuation
            entered?.resume()
            entered = nil
        }
    }
}

private actor DelayedFormRepository: ClientRepository {
    private let current: Client
    private var calls = 0
    private var pending: CheckedContinuation<Client?, any Error>?
    private var entered: CheckedContinuation<Void, Never>?

    init(current: Client) {
        self.current = current
    }

    func client(id: ClientID) async throws -> Client? {
        calls += 1
        guard calls == 1 else { return current }
        return try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            entered?.resume()
            entered = nil
        }
    }

    func waitUntilStarted() async {
        guard pending == nil else { return }
        await withCheckedContinuation {
            entered = $0
        }
    }

    func release(_ outcome: FormReadOutcome) {
        switch outcome {
        case .profile, .cancelled:
            pending?.resume(returning: Client.draft(id: current.id, displayName: "Obsolete profile"))
        case .failure:
            pending?.resume(throwing: ClientError.persistenceUnavailable)
        }
        pending = nil
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream {
            $0.finish()
        }
    }

    func saveClient(_ client: Client) async throws {
        throw ClientError.persistenceUnavailable
    }

    func deactivateClient(_ id: ClientID) async throws {
        throw ClientError.persistenceUnavailable
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }
}
