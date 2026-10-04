import Foundation
import Testing
@testable import FranAlonso

struct BillingEmailComposerFixtures {
    static let principalID = "synthetic-principal-email-13-11"

    static func draft(
        pdf: Data? = nil,
        principalID: String = BillingEmailComposerFixtures.principalID
    ) throws -> EmailDraft {
        let document = try billingRenderingDocument()
        var delivery = try BillingDocumentDelivery(request: document.request, principalID: principalID)
        try delivery.accept(document)
        try delivery.acceptPDF(pdf ?? billingPDFTemplate())
        try delivery.beginUpload()
        try delivery.completeUpload(.accepted(documentID: document.id, principalID: principalID))
        return try EmailDraft.prepared(
            delivery: delivery,
            recipient: "recipient@example.invalid",
            content: BillingEmailContent(
                subject: "Synthetic ticket 41",
                body: "Please find the synthetic document attached."
            )
        )
    }

    @MainActor
    static func composer(
        driver: BillingEmailComposerDriver,
        permit: BillingEmailComposerPermit = BillingEmailComposerPermit(),
        principalID: String = BillingEmailComposerFixtures.principalID
    ) -> AppleBillingEmailComposer {
        AppleBillingEmailComposer(
            driver: driver,
            access: BillingAssetAccess(principalID: principalID) {
                try await permit.validate()
            }
        )
    }

    @MainActor
    static func operation(
        composer: AppleBillingEmailComposer,
        driver: BillingEmailComposerDriver,
        draft: EmailDraft
    ) -> Task<EmailCompositionResult, any Error> {
        Task { @MainActor in
            defer { driver.operationFinished() }
            return try await composer.compose(draft)
        }
    }
}

@MainActor
final class BillingEmailComposerDriver: AppleMailCompositionDriver {
    var canCompose = true
    var immediateResult: EmailCompositionResult?
    var startFailure: BillingEmailComposerProviderFailure?
    var inlineCancellationResult: EmailCompositionResult?
    private(set) var drafts: [EmailDraft] = []
    private(set) var cancellationCount = 0
    private var completions: [@MainActor (EmailCompositionResult) -> Void] = []
    private var completedOperationCount = 0
    private var observers: [Observer] = []

    func start(
        _ draft: EmailDraft,
        completion: @escaping @MainActor (EmailCompositionResult) -> Void
    ) throws {
        drafts.append(draft)
        completions.append(completion)
        notifyObservers()
        if let immediateResult {
            completion(immediateResult)
        }
        if let startFailure {
            throw startFailure
        }
    }

    func cancel() {
        cancellationCount += 1
        if let inlineCancellationResult {
            completions.last?(inlineCancellationResult)
        }
    }

    func complete(operation: Int, with result: EmailCompositionResult) {
        completions[operation](result)
    }

    func operationFinished() {
        completedOperationCount += 1
        notifyObservers()
    }

    func waitUntilStartedOrCompleted(startBaseline: Int = 0, completionBaseline: Int = 0) async -> Bool {
        if drafts.count > startBaseline {
            return true
        }
        if completedOperationCount > completionBaseline {
            return false
        }
        return await withCheckedContinuation { continuation in
            observers.append(Observer(
                startBaseline: startBaseline,
                completionBaseline: completionBaseline,
                continuation: continuation
            ))
        }
    }

    private func notifyObservers() {
        var waiting: [Observer] = []
        for observer in observers {
            if drafts.count > observer.startBaseline {
                observer.continuation.resume(returning: true)
            } else if completedOperationCount > observer.completionBaseline {
                observer.continuation.resume(returning: false)
            } else {
                waiting.append(observer)
            }
        }
        observers = waiting
    }

    private struct Observer {
        let startBaseline: Int
        let completionBaseline: Int
        let continuation: CheckedContinuation<Bool, Never>
    }
}

actor BillingEmailComposerPermit {
    private var authorized = true
    private var checkCount = 0
    private let pause: BillingStoragePause?
    private let pauseOnCheck: Int

    init(pause: BillingStoragePause? = nil, pauseOnCheck: Int = 1) {
        self.pause = pause
        self.pauseOnCheck = pauseOnCheck
    }

    func validate() async throws {
        checkCount += 1
        if checkCount == pauseOnCheck, let pause {
            await pause.wait()
        }
        guard authorized else { throw BillingAssetError.unauthorized }
    }

    func revoke() {
        authorized = false
    }
}

enum BillingEmailComposerProviderFailure: Error {
    case privateProviderDetails
}

enum BillingEmailComposerInvalidPDF: CaseIterable {
    case corrupt, truncated, tooManyPages

    func bytes() throws -> Data {
        switch self {
        case .corrupt:
            Data("%PDF-1.7\nnot a parseable document\n%%EOF".utf8)
        case .truncated:
            Data(try billingPDFTemplate().dropLast(20))
        case .tooManyPages:
            try billingPDFTemplate(pageCount: 101)
        }
    }
}
