import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@MainActor
struct ClientDocumentRecoveryFixtures {
    static func repository(
        container: ModelContainer,
        authority: RecoveryAuthorization = RecoveryAuthorization()
    ) -> DefaultClientDocumentRepository {
        repository(persistence: ClientDocumentPersistenceActor(modelContainer: container), authority: authority)
    }

    static func repository(
        persistence: ClientDocumentPersistenceActor,
        authority: RecoveryAuthorization = RecoveryAuthorization(),
        signal: any ClientChangeSignaling = ClientObservationSignal()
    ) -> DefaultClientDocumentRepository {
        DefaultClientDocumentRepository(
            persistence: persistence,
            access: ClientDocumentAccess(
                session: AuthenticationSession(id: "principal-A"),
                authorizer: LocalPrincipalAuthorizer { session in try await authority.authorize(session) },
                validateSession: { try await authority.validateRevision() }
            ),
            observationSignal: signal
        )
    }

    static func repository(at url: URL) throws -> DefaultClientDocumentRepository {
        repository(container: try ClientDocumentPersistenceFixtures.container(at: url))
    }

    static func accept(_ repository: some ClientDocumentRepository) async throws -> ClientDocumentDelivery {
        let saved = try await repository.saveDraft(ClientDocumentPersistenceFixtures.draft(), operationID: UUID())
        return try await repository.accept(
            ClientDocumentPersistenceFixtures.document(saved),
            draftID: saved.id,
            revision: saved.fields.revision
        )
    }

    static func upload(
        _ repository: some ClientDocumentRepository,
        storage: some ClientDocumentStorage
    ) -> UploadConsentUseCase {
        UploadConsentUseCase(repository: repository, storage: storage, now: { ClientDocumentTestFixtures.date })
    }

    static func save(_ draft: ClientDocumentDraft, at url: URL) async throws {
        _ = try await repository(at: url).saveDraft(draft, operationID: UUID())
    }

    static func render(
        draftID: UUID,
        at url: URL,
        renderer: some ClientDocumentRenderer
    ) async throws -> ClientDocumentDelivery {
        try await RenderAndPersistConsentUseCase(repository: repository(at: url), renderer: renderer)(draftID: draftID)
    }

    static func loseUploadResponse(
        at url: URL,
        remote: InMemoryClientDocumentStorage.RemoteStore
    ) async throws -> ClientDocumentDelivery {
        let repository = try repository(at: url)
        let accepted = try await accept(repository)
        let storage = InMemoryClientDocumentStorage(remote: remote, failures: [.responseLost])
        await #expect(throws: ClientDocumentStorageError.unavailable) {
            try await upload(repository, storage: storage)(documentID: accepted.id)
        }
        return accepted
    }
}

actor RecoveryAuthorization {
    private var revision = 0
    private var authorizationError: LocalPrincipalAuthorizationError?

    func authorize(_ session: AuthenticationSession) throws {
        if let authorizationError {
            throw authorizationError
        }
        guard session.id == "principal-A" else { throw LocalPrincipalAuthorizationError.differentPrincipal }
    }

    func validateRevision() throws {
        guard revision == 0 else { throw ClientDocumentAccessError.sessionExpired }
    }

    func revoke() {
        revision += 1
    }

    func failAuthorization(with error: LocalPrincipalAuthorizationError) {
        authorizationError = error
    }
}

actor RecoveryRenderer: ClientDocumentRenderer {
    private let fails: Bool
    private(set) var dates: [Date] = []
    private(set) var bindings: [ClientDocumentSignature] = []

    init(fails: Bool = false) {
        self.fails = fails
    }

    func render(binding: ClientDocumentSignature, signedAt: Date) throws -> Data {
        dates.append(signedAt)
        bindings.append(binding)
        guard !fails else { throw ClientDocumentError.renderingFailed }
        return ClientDocumentPersistenceFixtures.bytes
    }
}

enum RecoveryReceiptSubstitution {
    case wrongDocument, wrongPrincipal
}

struct SubstitutingRecoveryStorage: ClientDocumentStorage {
    let base: any ClientDocumentStorage
    let substitution: RecoveryReceiptSubstitution

    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt {
        let receipt = try await base.upload(document, principalID: principalID)
        switch substitution {
        case .wrongDocument:
            return ClientDocumentUploadReceipt(
                documentID: UUID(uuidString: "00000000-0000-0000-0000-000000000087")!,
                principalID: principalID,
                reference: receipt.reference
            )
        case .wrongPrincipal:
            return ClientDocumentUploadReceipt(
                documentID: document.id,
                principalID: "principal-B",
                reference: receipt.reference
            )
        }
    }
}

struct AfterUploadRecoveryStorage: ClientDocumentStorage {
    let base: any ClientDocumentStorage
    let beforeReturning: @Sendable () async -> Void

    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt {
        let receipt = try await base.upload(document, principalID: principalID)
        await beforeReturning()
        return receipt
    }
}

actor RecoveryOperationGate {
    private var hasEntered = false
    private var hasFinished = false
    private var entryWaiters: [CheckedContinuation<Bool, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func enter() async {
        hasEntered = true
        for waiter in entryWaiters {
            waiter.resume(returning: true)
        }
        entryWaiters.removeAll()
        await withCheckedContinuation { releaseContinuation = $0 }
    }

    func waitForEntry() async -> Bool {
        guard !hasEntered else { return true }
        guard !hasFinished else { return false }
        return await withCheckedContinuation { entryWaiters.append($0) }
    }

    func finish() {
        hasFinished = true
        for waiter in entryWaiters {
            waiter.resume(returning: hasEntered)
        }
        entryWaiters.removeAll()
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

struct GatedRecoveryRenderer: ClientDocumentRenderer {
    let gate: RecoveryOperationGate

    func render(binding: ClientDocumentSignature, signedAt: Date) async -> Data {
        await gate.enter()
        return ClientDocumentPersistenceFixtures.bytes
    }
}

actor RecoveryChangeSignal: ClientChangeSignaling {
    private(set) var count = 0

    func publishChange() {
        count += 1
    }
}

extension ClientDocumentRecoveryFixtures {
    static func uploaded(at url: URL, conflictAfterward: Bool) async throws -> ClientDocumentUploadReceipt {
        let repository = try repository(at: url)
        let accepted = try await accept(repository)
        let receipt = try await upload(repository, storage: InMemoryClientDocumentStorage())(documentID: accepted.id)
        if conflictAfterward {
            let original = accepted.document.fields
            let different = try ClientSignedDocument(.init(
                binding: original.binding,
                signedAt: original.signedAt,
                pdf: Data("%PDF-1.7\nRejected replacement artifact\n%%EOF\n".utf8)
            ))
            await #expect(throws: ClientDocumentPersistenceError.documentConflict) {
                try await repository.accept(different, draftID: ClientDocumentPersistenceFixtures.draftID, revision: 1)
            }
        }
        return receipt
    }
}

actor RefusingRecoveryStorage: ClientDocumentStorage {
    private(set) var calls = 0

    func upload(_ document: ClientSignedDocument, principalID: String) throws -> ClientDocumentUploadReceipt {
        calls += 1
        throw ClientDocumentStorageError.unavailable
    }
}

enum RecoveryLatestAttempt {
    case pending, unavailable
}

extension ClientDocumentRecoveryFixtures {
    static func apply(
        _ outcome: RecoveryLatestAttempt,
        to attempt: ClientDocumentDelivery,
        repository: some ClientDocumentRepository
    ) async throws {
        if case .unavailable = outcome {
            try await repository.recordUploadFailure(id: attempt.id, attempt: attempt.attemptCount, error: .unavailable)
        }
    }
}
