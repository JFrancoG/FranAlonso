import Testing
@testable import FranAlonso

@Suite("Biometric announcement gate")
@MainActor
struct BiometricAnnouncementGateTests {
    @Test("A failure without scene departure is announced while active")
    func failureWithoutSceneDepartureIsAnnouncedWhileActive() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()

        #expect(
            gate.receiveFailure(.biometricUnavailable, sceneIsActive: true)
                == .announce(.biometricUnavailable)
        )
        #expect(gate.sceneBecameActive() == .none)
        #expect(gate.receiveFailure(.biometricUnavailable, sceneIsActive: true) == .none)
    }

    @Test("A failure while inactive is announced after return")
    func failureWhileInactiveIsAnnouncedAfterReturn() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        gate.sceneBecameInactive()

        #expect(gate.receiveFailure(.biometricCancelled, sceneIsActive: false) == .none)
        #expect(gate.sceneBecameActive() == .announce(.biometricCancelled))
        #expect(gate.sceneBecameActive() == .none)
    }

    @Test("A failure after return is announced when received")
    func failureAfterReturnIsAnnouncedWhenReceived() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        gate.sceneBecameInactive()

        #expect(gate.sceneBecameActive() == .none)
        #expect(
            gate.receiveFailure(.biometricCancelled, sceneIsActive: true)
                == .announce(.biometricCancelled)
        )
        #expect(gate.receiveFailure(.biometricCancelled, sceneIsActive: true) == .none)
    }

    @Test("An active snapshot closes a return whose scene callback is still pending")
    func activeSnapshotClosesPendingReturn() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        gate.sceneBecameInactive()

        #expect(
            gate.receiveFailure(.biometricCancelled, sceneIsActive: true)
                == .announce(.biometricCancelled)
        )
        #expect(gate.sceneBecameActive() == .none)
    }

    @Test("A second scene interruption before the result waits for its return")
    func secondSceneInterruptionBeforeResultWaitsForReturn() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        gate.sceneBecameInactive()
        #expect(gate.sceneBecameActive() == .none)

        gate.sceneBecameInactive()
        #expect(gate.receiveFailure(.biometricCancelled, sceneIsActive: false) == .none)
        #expect(gate.sceneBecameActive() == .announce(.biometricCancelled))
    }

    @Test("A failure outside a biometric attempt uses normal presentation")
    func failureOutsideBiometricAttemptUsesNormalPresentation() {
        var gate = BiometricAnnouncementGate()

        #expect(
            gate.receiveFailure(.secureStorageUnavailable, sceneIsActive: true)
                == .presentFailureNormally
        )
    }

    @Test("Reset suppresses an obsolete attempt")
    func resetSuppressesObsoleteAttempt() {
        var gate = BiometricAnnouncementGate()

        #expect(!gate.isCoordinatingAttempt)
        gate.beginAttempt()
        #expect(gate.isCoordinatingAttempt)
        gate.sceneBecameInactive()
        gate.reset()

        #expect(!gate.isCoordinatingAttempt)
        #expect(gate.sceneBecameActive() == .none)
        #expect(
            gate.receiveFailure(.biometricCancelled, sceneIsActive: true)
                == .presentFailureNormally
        )
    }

    @Test("Reset after delivery restores normal presentation for a sign-out failure")
    func resetAfterDeliveryRestoresNormalFailurePresentation() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        #expect(
            gate.receiveFailure(.biometricCancelled, sceneIsActive: true)
                == .announce(.biometricCancelled)
        )

        gate.reset()

        #expect(
            gate.receiveFailure(.secureStorageUnavailable, sceneIsActive: true)
                == .presentFailureNormally
        )
    }

    @Test("A second attempt can announce its own failure")
    func secondAttemptCanAnnounceItsOwnFailure() {
        var gate = BiometricAnnouncementGate()

        gate.beginAttempt()
        gate.sceneBecameInactive()
        #expect(gate.receiveFailure(.biometricDenied, sceneIsActive: false) == .none)
        #expect(gate.sceneBecameActive() == .announce(.biometricDenied))

        gate.beginAttempt()
        gate.sceneBecameInactive()
        #expect(gate.receiveFailure(.biometricCancelled, sceneIsActive: false) == .none)
        #expect(gate.sceneBecameActive() == .announce(.biometricCancelled))
    }
}
