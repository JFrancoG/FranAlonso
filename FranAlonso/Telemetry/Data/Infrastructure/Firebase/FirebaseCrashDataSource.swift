import FirebaseCrashlytics
import Foundation

struct FirebaseCrashDataSource: CrashDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) async throws {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isEnabled)
    }

    func record(_ diagnostic: CrashDiagnostic) async throws {
        let error = NSError(
            domain: diagnostic.errorDomain,
            code: diagnostic.rawValue
        )
        Crashlytics.crashlytics().record(error: error)
    }
}
