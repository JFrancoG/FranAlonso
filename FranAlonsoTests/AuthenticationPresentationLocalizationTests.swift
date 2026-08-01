import Foundation
import Testing
@testable import FranAlonso

@Suite("Authentication presentation localization")
@MainActor
struct AuthenticationPresentationLocalizationTests {
    @Test(
        "Login failures map to stable localized resources",
        arguments: [
            (LoginViewModel.Failure.credentialsRejected, "authentication.login.error.credentials-rejected"),
            (LoginViewModel.Failure.temporarilyUnavailable, "authentication.login.error.temporarily-unavailable"),
            (LoginViewModel.Failure.configuration, "authentication.login.error.configuration"),
            (LoginViewModel.Failure.secureStorageUnavailable, "authentication.login.error.secure-storage"),
            (LoginViewModel.Failure.unexpected, "authentication.login.error.unexpected")
        ]
    )
    func loginFailuresMapToStableLocalizedResources(_ failure: LoginViewModel.Failure, _ expectedKey: String) {
        #expect(failure.localizedMessage.key == expectedKey)
    }

    @Test("Session observation failure maps to a stable localized resource")
    func sessionObservationFailureMapsToAStableLocalizedResource() {
        #expect(
            SessionViewModel.Failure.observationEnded.localizedMessage.key
                == "authentication.session.error.observation-ended"
        )
    }

    @Test(
        "Session action failures map to stable localized resources",
        arguments: [
            (SessionViewModel.ActionFailure.biometricDenied, "authentication.session.error.biometric-denied"),
            (SessionViewModel.ActionFailure.biometricCancelled, "authentication.session.error.biometric-cancelled"),
            (SessionViewModel.ActionFailure.biometricUnavailable, "authentication.session.error.biometric-unavailable"),
            (
                SessionViewModel.ActionFailure.temporarilyUnavailable,
                "authentication.session.error.temporarily-unavailable"
            ),
            (SessionViewModel.ActionFailure.configuration, "authentication.session.error.configuration"),
            (SessionViewModel.ActionFailure.secureStorageUnavailable, "authentication.session.error.secure-storage"),
            (SessionViewModel.ActionFailure.unexpected, "authentication.session.error.unexpected")
        ]
    )
    func sessionActionFailuresMapToStableLocalizedResources(
        _ failure: SessionViewModel.ActionFailure,
        _ expectedKey: String
    ) {
        #expect(failure.localizedMessage.key == expectedKey)
    }

    @Test(
        "Critical authentication symbols keep their semantic keys",
        arguments: [
            (LocalizedStringResource.authenticationLoginEmailLabel, "authentication.login.email.label"),
            (LocalizedStringResource.authenticationLoginPasswordLabel, "authentication.login.password.label"),
            (LocalizedStringResource.authenticationLoginSubmit, "authentication.login.submit"),
            (
                LocalizedStringResource.authenticationSessionBiometricUnlock,
                "authentication.session.biometric.unlock"
            ),
            (
                LocalizedStringResource.authenticationSessionEmailFallback,
                "authentication.session.email-fallback"
            ),
            (
                LocalizedStringResource.authenticationSessionBiometricReason,
                "authentication.session.biometric.reason"
            )
        ]
    )
    func criticalAuthenticationSymbolsKeepTheirSemanticKeys(
        _ resource: LocalizedStringResource,
        _ expectedKey: String
    ) {
        #expect(resource.key == expectedKey)
    }
}
