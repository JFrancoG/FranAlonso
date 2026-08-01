import Foundation
import LocalAuthentication
import Testing
@testable import FranAlonso

@Suite("Biometric authenticator")
struct BiometricAuthenticatorTests {
    @Test("Availability delegates every query instead of caching the first result")
    func availabilityDelegatesEveryQuery() async {
        await confirmation("Availability is checked twice", expectedCount: 2) { availabilityChecked in
            let authenticator = makeLocalAuthenticationAuthenticator(
                canEvaluate: {
                    availabilityChecked()
                    return true
                }
            )

            #expect(authenticator.canAuthenticate())
            #expect(authenticator.canAuthenticate())
        }
    }

    @Test("Unavailable biometrics report false")
    func unavailableBiometricsReportFalse() {
        let authenticator = makeLocalAuthenticationAuthenticator(
            canEvaluate: { false }
        )

        #expect(!authenticator.canAuthenticate())
    }

    @Test("Authorization delegates the exact localized reason")
    func authorizationDelegatesLocalizedReason() async throws {
        try await confirmation("Authorization is evaluated once", expectedCount: 1) { evaluated in
            let authenticator = BiometricAuthenticator(
                canAuthenticate: { true },
                authenticate: { localizedReason in
                    #expect(localizedReason == "Desbloquea tu sesión")
                    evaluated()
                }
            )

            try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
        }
    }

    @Test("An empty localized reason fails before invoking the provider")
    func emptyLocalizedReasonFailsBeforeProvider() async {
        await confirmation("The provider is not invoked", expectedCount: 0) { providerInvoked in
            let authenticator = BiometricAuthenticator(
                canAuthenticate: { true },
                authenticate: { _ in providerInvoked() }
            )

            await #expect(throws: BiometricAuthenticationError.configuration) {
                try await authenticator.authenticate(localizedReason: "")
            }
        }
    }

    @Test("A cancelled task fails before invoking the provider")
    func preCancelledTaskFailsBeforeProvider() async {
        await confirmation("The provider is not invoked", expectedCount: 0) { providerInvoked in
            let authenticator = BiometricAuthenticator(
                canAuthenticate: { true },
                authenticate: { _ in providerInvoked() }
            )
            let authentication = Task {
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
            }

            await #expect(throws: CancellationError.self) {
                try await authentication.value
            }
        }
    }

    @Test("A false provider result is denied")
    func falseProviderResultIsDenied() async {
        let authenticator = makeLocalAuthenticationAuthenticator(evaluate: { _ in false })

        await #expect(throws: BiometricAuthenticationError.denied) {
            try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
        }
    }

    @Test(
        "Provider failures map to the stable biometric contract",
        arguments: [
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.authenticationFailed.rawValue,
                expected: .denied
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.userCancel.rawValue,
                expected: .cancelled
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.userFallback.rawValue,
                expected: .cancelled
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.systemCancel.rawValue,
                expected: .cancelled
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.appCancel.rawValue,
                expected: .cancelled
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.passcodeNotSet.rawValue,
                expected: .unavailable
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.biometryNotAvailable.rawValue,
                expected: .unavailable
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.biometryNotEnrolled.rawValue,
                expected: .unavailable
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.biometryLockout.rawValue,
                expected: .unavailable
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.notInteractive.rawValue,
                expected: .unavailable
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.invalidContext.rawValue,
                expected: .unexpected
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: LAError.Code.companionNotAvailable.rawValue,
                expected: .unexpected
            ),
            BiometricErrorFixture(
                domain: LAError.errorDomain,
                code: 199_999,
                expected: .unexpected
            ),
            BiometricErrorFixture(
                domain: "ExampleBiometricErrorDomain",
                code: LAError.Code.authenticationFailed.rawValue,
                expected: .unexpected
            )
        ]
    )
    fileprivate func providerFailureMapsToStableContract(_ fixture: BiometricErrorFixture) async {
        let authenticator = makeLocalAuthenticationAuthenticator(
            evaluate: { _ in
                throw NSError(domain: fixture.domain, code: fixture.code)
            }
        )

        await #expect(throws: fixture.expected) {
            try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
        }
    }

    @Test("Provider cancellation remains CancellationError")
    func providerCancellationRemainsCancellationError() async {
        let authenticator = makeLocalAuthenticationAuthenticator(
            evaluate: { _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
        }
    }

    @Test("Cancelling an in-flight evaluation invalidates it once and remains CancellationError")
    func cancellationInvalidatesInFlightEvaluation() async {
        let gate = BiometricEvaluationGate()
        let authenticator = makeLocalAuthenticationAuthenticator(
            evaluate: { localizedReason in
                await gate.evaluate(localizedReason: localizedReason)
            },
            invalidate: {
                await gate.invalidate()
            }
        )
        let authentication = Task {
            try await authenticator.authenticate(localizedReason: "Desbloquea tu sesión")
        }

        await gate.waitUntilEvaluationStarts()
        authentication.cancel()

        await #expect(throws: CancellationError.self) {
            try await authentication.value
        }
        #expect(await gate.receivedReasons == ["Desbloquea tu sesión"])
        #expect(await gate.invalidationCount == 1)
    }

    @Test("The Domain capability is safe to cross concurrency boundaries")
    func capabilityIsSendable() {
        let authenticator = BiometricAuthenticator(
            canAuthenticate: { true },
            authenticate: { _ in }
        )

        requireSendable(authenticator)
    }
}

private struct BiometricErrorFixture {
    let domain: String
    let code: Int
    let expected: BiometricAuthenticationError
}

private actor BiometricEvaluationGate {
    private var evaluationContinuation: CheckedContinuation<Bool, Never>?
    private var startContinuations: [CheckedContinuation<Void, Never>] = []
    private(set) var receivedReasons: [String] = []
    private(set) var invalidationCount = 0

    func evaluate(localizedReason: String) async -> Bool {
        receivedReasons.append(localizedReason)
        let continuations = startContinuations
        startContinuations.removeAll()
        continuations.forEach { $0.resume() }

        return await withCheckedContinuation { continuation in
            evaluationContinuation = continuation
        }
    }

    func waitUntilEvaluationStarts() async {
        guard receivedReasons.isEmpty else { return }

        await withCheckedContinuation { continuation in
            startContinuations.append(continuation)
        }
    }

    func invalidate() {
        invalidationCount += 1
        evaluationContinuation?.resume(returning: false)
        evaluationContinuation = nil
    }
}

private func makeLocalAuthenticationAuthenticator(
    canEvaluate: @escaping @Sendable () -> Bool = { true },
    evaluate: @escaping @Sendable (String) async throws -> Bool = { _ in true },
    invalidate: @escaping @Sendable () async -> Void = {}
) -> BiometricAuthenticator {
    BiometricAuthenticator.localAuthentication(
        canEvaluate: canEvaluate,
        makeEvaluation: {
            BiometricPolicyEvaluation(
                evaluate: evaluate,
                invalidate: invalidate
            )
        }
    )
}

private func requireSendable<Value: Sendable>(_ value: Value) {}
