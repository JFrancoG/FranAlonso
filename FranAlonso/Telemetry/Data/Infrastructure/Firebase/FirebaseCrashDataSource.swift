import FirebaseCrashlytics
import Foundation

/// A Firebase-backed crash sink for allowlisted nonfatal diagnostics.
struct FirebaseCrashDataSource: CrashDataSource {
    /// Persists the SDK override for the requested collection state.
    ///
    /// Firebase applies a changed override on the next application run.
    ///
    /// - Parameter isEnabled: Whether future launches should collect crash reports.
    func setCollectionEnabled(_ isEnabled: Bool) async throws {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isEnabled)
    }

    /// Records a diagnostic as a nonfatal error with its stable domain and numeric code.
    ///
    /// - Parameter diagnostic: The allowlisted diagnostic to record.
    func record(_ diagnostic: CrashDiagnostic) async throws {
        let error = NSError(
            domain: diagnostic.errorDomain,
            code: diagnostic.rawValue
        )
        Crashlytics.crashlytics().record(error: error)
    }
}
