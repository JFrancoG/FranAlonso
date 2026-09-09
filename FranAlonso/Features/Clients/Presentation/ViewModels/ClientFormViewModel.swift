import Foundation
import Observation
import SwiftData

/// Owns a single client form session and coordinates validated, caller-context local mutations.
@Observable
@MainActor
final class ClientFormViewModel {
    typealias SaveOperation = @MainActor (ClientID, ClientProfile, ModelContext) async throws -> Client
    typealias DeactivateOperation = @MainActor (ClientID, ModelContext) async throws -> Void

    enum Operation: Equatable {
        case load
        case save
        case deactivate
    }

    /// Failure retains the operation so a failed initial read cannot become a writable blank edit.
    enum State: Equatable {
        case idle
        case loading
        case editing
        case saving
        case deactivating
        case saved(Client)
        case deactivated
        case failed(Operation, ClientError)
        case closed
    }

    let destination: ClientFormDestination

    /// Clears only a rejected name's validation error when editing makes that name valid, without saving.
    var fields = ClientFormFields() {
        didSet {
            guard fields.displayName != oldValue.displayName,
                  state == .failed(.save, .invalidDisplayName),
                  (try? ClientProfile(displayName: fields.displayName)) != nil else { return }
            state = .editing
        }
    }

    private(set) var state: State

    private let getClient: GetClientUseCase
    private let prepareProfile = PrepareClientProfileUseCase()
    private let create: SaveOperation
    private let update: SaveOperation
    private let deactivateClient: DeactivateOperation
    @ObservationIgnored private var operationGeneration = UUID()

    /// Receives contextual capabilities composed by App; no persistent context is retained.
    init(
        destination: ClientFormDestination,
        getClient: GetClientUseCase,
        create: @escaping SaveOperation,
        update: @escaping SaveOperation,
        deactivate: @escaping DeactivateOperation
    ) {
        self.destination = destination
        self.getClient = getClient
        self.create = create
        self.update = update
        deactivateClient = deactivate
        state = destination.mode == .create ? .editing : .idle
    }

    /// Allows editing after a rejected mutation, but never before an existing profile has loaded.
    var canEdit: Bool {
        switch state {
        case .editing, .failed(.save, _), .failed(.deactivate, _): true
        default: false
        }
    }

    /// Loads an existing client or retries its failed read without overwriting an editable draft.
    /// The caller owns cancellation; a newer load or closing the session fences obsolete responses.
    func load() async {
        guard destination.mode == .edit else { return }
        switch state {
        case .idle, .loading, .failed(.load, _): break
        default: return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .loading
        do {
            let client = try await getClient(destination.clientID)
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            fields = ClientFormFields(client)
            state = .editing
        } catch {
            guard operationGeneration == generation else { return }
            if error is CancellationError || Task.isCancelled {
                state = .idle
            } else {
                state = .failed(.load, clientError(error))
            }
        }
    }

    /// Validates a captured draft and delegates exactly one local write using the ephemeral caller context.
    /// Concurrent submissions are ignored. A successful durable response remains success after cancellation.
    func save(in context: ModelContext) async {
        guard canEdit, !Task.isCancelled else { return }
        let profile: ClientProfile
        do {
            profile = try prepareProfile(
                displayName: fields.displayName,
                taxIdentifier: fields.taxIdentifier,
                streetLine: fields.streetLine,
                postalCode: fields.postalCode,
                city: fields.city,
                province: fields.province
            )
        } catch {
            state = .failed(.save, clientError(error))
            return
        }

        let generation = UUID()
        operationGeneration = generation
        state = .saving
        do {
            let client: Client
            switch destination.mode {
            case .create:
                client = try await create(destination.clientID, profile, context)
            case .edit:
                client = try await update(destination.clientID, profile, context)
            }
            guard operationGeneration == generation else { return }
            state = .saved(client)
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.save, clientError(error))
        }
    }

    /// Accepts an already-confirmed deactivation of a loaded client, excluding overlapping or repeated requests.
    /// Confirmation presentation belongs to the caller; success means local acceptance, not remote convergence.
    func deactivate(in context: ModelContext) async {
        guard destination.mode == .edit, canEdit, !Task.isCancelled else { return }
        let generation = UUID()
        operationGeneration = generation
        state = .deactivating
        do {
            try await deactivateClient(destination.clientID, context)
            guard operationGeneration == generation else { return }
            state = .deactivated
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.deactivate, clientError(error))
        }
    }

    /// Closes presentation and ignores later responses without claiming to roll back accepted writes.
    func close() {
        operationGeneration = UUID()
        state = .closed
    }

    private func clientError(_ error: any Error) -> ClientError {
        error as? ClientError ?? .persistenceUnavailable
    }
}
