import Observation

/// Owns the selected top-level section of the authenticated application shell.
@Observable
@MainActor
final class AppShellViewModel {
    var selectedSection: AppSection = .workday
}
