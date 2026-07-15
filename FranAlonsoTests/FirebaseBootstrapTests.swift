import Foundation
import Testing
@testable import FranAlonso

@Suite("Firebase bootstrap")
@MainActor
struct FirebaseBootstrapTests {
    @Test("Firebase Analytics automatic collection stays deactivated")
    func firebaseAnalyticsAutomaticCollectionStaysDeactivated() {
        let info = Bundle.main.infoDictionary

        #expect(info?["FIREBASE_ANALYTICS_COLLECTION_ENABLED"] as? Bool == false)
        #expect(info?["FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED"] as? Bool == true)
        #expect(info?["FirebaseAutomaticScreenReportingEnabled"] as? Bool == false)
        #expect(info?["GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED"] as? Bool == false)
    }

    @Test("Firebase application delegate proxy stays disabled")
    func firebaseApplicationDelegateProxyStaysDisabled() {
        let info = Bundle.main.infoDictionary

        #expect(info?["FirebaseAppDelegateProxyEnabled"] as? Bool == false)
    }
}
