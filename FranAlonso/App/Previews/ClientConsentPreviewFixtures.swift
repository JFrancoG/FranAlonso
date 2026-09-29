import Foundation
import SwiftData

/// Seeds stable synthetic documents into isolated persistence for native reader previews.
struct ClientConsentPreviewFixtures {
    enum Scenario: Hashable, CaseIterable {
        case information, review, photoReview, signed, retained, recovery, error
        case activationPending, activated, activationFailure
    }

    @MainActor
    static func make(_ scenario: Scenario) async throws -> ClientFormViewModel {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let signal = ClientObservationSignal()
        let repository = DefaultClientDocumentRepository(
            persistence: ClientDocumentPersistenceActor(modelContainer: container),
            access: ClientDocumentAccess(
                session: AuthenticationSession(id: "isolated-consent-preview"),
                authorizer: LocalPrincipalAuthorizer { _ in },
                validateSession: {}
            ),
            observationSignal: signal
        )
        let catalog = BundleClientDocumentCatalog(bundle: .main)
        let renderer = CoreGraphicsClientDocumentRenderer()
        let profile = try ClientProfile(displayName: "Cliente de demostración Álvarez")
        let clientID = ClientID(rawValue: id(0x87))
        let activation = DefaultClientActivationRepository(
            persistence: repository.persistence,
            access: repository.access,
            observationSignal: signal
        )
        let isActivation = scenario == .activationPending || scenario == .activated || scenario == .activationFailure
        let activationRepository: any ClientActivationRepository = scenario == .activationFailure
            ? FailingActivationPreviewRepository(base: activation) : activation
        let services = ClientConsentServices(
            repository: repository,
            activationRepository: activationRepository,
            catalog: scenario == .error ? UnavailableConsentPreviewCatalog() : catalog,
            renderer: renderer,
            storage: UnavailableConsentPreviewStorage(),
            version: "2026-09-10-draft",
            language: "es",
            now: { date },
            newID: { UUID() }
        )
        if scenario != .information && scenario != .error {
            let saved = try await repository.saveDraft(
                draft(
                    clientID: clientID,
                    profile: profile,
                    catalog: catalog,
                    documentID: id(0x88),
                    draftID: id(0x89),
                    decision: scenario == .photoReview ? .undecided : .notSelected,
                    signed: scenario == .signed || scenario == .retained || isActivation
                ),
                operationID: id(0x90)
            )
            if scenario == .retained || isActivation {
                let render = RenderAndPersistConsentUseCase(repository: repository, renderer: renderer)
                let delivery = try await render(draftID: saved.id)
                if isActivation {
                    _ = try await activation.prepareActivation(
                        clientID: clientID,
                        documentID: delivery.id,
                        operationID: id(0x95)
                    )
                    _ = try await UploadConsentUseCase(
                        repository: repository,
                        storage: InMemoryClientDocumentStorage(),
                        now: { date }
                    )(documentID: delivery.id)
                }
            }
            if scenario == .recovery {
                _ = try await repository.saveDraft(
                    draft(
                        clientID: clientID,
                        profile: profile,
                        catalog: catalog,
                        documentID: id(0x91),
                        draftID: id(0x92),
                        decision: .notSelected,
                        signed: true
                    ),
                    operationID: id(0x93)
                )
            }
        }
        let model = ClientFormViewModel(
            destination: ClientFormDestination(id: id(0x94), clientID: clientID, mode: .create),
            getClient: GetClientUseCase(repository: DefaultClientRepository(
                persistenceActor: ClientPersistenceActor(modelContainer: container),
                observationSignal: signal
            )),
            create: { _, _, _ in
                throw ClientError.persistenceUnavailable
            },
            update: { _, _, _ in
                throw ClientError.persistenceUnavailable
            },
            deactivate: { _, _ in
                throw ClientError.persistenceUnavailable
            },
            consentServices: services
        )
        model.fields.displayName = profile.displayName
        await model.performConsent(scenario == .information || scenario == .error ? .information : .review)
        if scenario == .activated || scenario == .activationFailure {
            await model.performConsent(.upload)
        }
        return model
    }
}

/// Keeps an uploaded preview recoverable while demonstrating a failed local activation.
private struct FailingActivationPreviewRepository: ClientActivationRepository {
    let base: DefaultClientActivationRepository

    func prepareActivation(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client {
        try await base.prepareActivation(clientID: clientID, documentID: documentID, operationID: operationID)
    }

    func activate(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client {
        throw ClientDocumentPersistenceError.persistenceUnavailable
    }
}

private extension ClientConsentPreviewFixtures {
    static let date = Date(timeIntervalSince1970: 1_789_300_800)

    static func id(_ suffix: UInt8) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, suffix))
    }

    static func draft(
        clientID: ClientID,
        profile: ClientProfile,
        catalog: any ClientDocumentCatalog,
        documentID: UUID,
        draftID: UUID,
        decision: ClientDocumentPhotoDecision,
        signed: Bool
    ) async throws -> ClientDocumentDraft {
        let snapshot = try await PrepareClientDocumentUseCase(catalog: catalog, newID: { documentID })(
            clientID: clientID,
            clientName: profile.displayName,
            context: .init(purpose: .initialInformation, photoDecision: decision),
            version: "2026-09-10-draft",
            language: "es"
        )
        let binding: ClientDocumentSignature?
        if signed {
            binding = try ClientDocumentSignature(
                snapshot: snapshot,
                signature: ClientSignature(strokes: ClientSignaturePreviewFixtures.standard.strokes)
            )
        } else {
            binding = nil
        }
        return try ClientDocumentDraft(.init(
            id: draftID,
            clientID: clientID,
            profile: profile,
            snapshot: snapshot,
            binding: binding,
            signedAt: signed ? date : nil,
            revision: 0
        ))
    }
}

private struct UnavailableConsentPreviewCatalog: ClientDocumentCatalog {
    func content(
        variant: ClientDocumentVariant,
        version: String,
        language: String
    ) async throws -> ClientDocumentContent {
        throw ClientDocumentError.unavailableCatalog
    }
}

private struct UnavailableConsentPreviewStorage: ClientDocumentStorage {
    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt {
        throw ClientDocumentStorageError.unavailable
    }
}
