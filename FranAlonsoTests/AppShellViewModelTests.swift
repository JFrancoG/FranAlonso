import Testing
@testable import FranAlonso

@Suite("App shell view model")
@MainActor
struct AppShellViewModelTests {
    @Test("Starts in the Workday section")
    func startsInWorkdaySection() {
        let viewModel = AppShellViewModel()

        #expect(viewModel.selectedSection == .workday)
    }
}
