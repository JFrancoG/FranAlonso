import Testing
@testable import FranAlonso

@Suite("Consent presentation focus restoration")
@MainActor
struct ClientConsentFocusRestorationTests {
    @Test
    func `Returning to the navigation button corrects focus only once`() {
        var restoration = ClientConsentFocusRestoration()
        restoration.prepare(.capture, voiceOverEnabled: true)
        #expect(restoration.consume(returnControlFocused: true) == .capture)
        #expect(restoration.consume(returnControlFocused: true) == nil)
    }

    @Test
    func `Reading another element prevents a later focus correction`() {
        var restoration = ClientConsentFocusRestoration()
        restoration.prepare(.title, voiceOverEnabled: true)
        #expect(restoration.consume(returnControlFocused: false) == nil)
        #expect(restoration.consume(returnControlFocused: true) == nil)
    }

    @Test
    func `A new presentation supersedes the previous destination`() {
        var restoration = ClientConsentFocusRestoration()
        restoration.prepare(.capture, voiceOverEnabled: true)
        restoration.prepare(.accept, voiceOverEnabled: true)
        #expect(restoration.consume(returnControlFocused: true) == .accept)
        #expect(restoration.consume(returnControlFocused: true) == nil)
    }

    @Test
    func `Cancelling the intention prevents a deferred focus correction`() {
        var restoration = ClientConsentFocusRestoration()
        restoration.prepare(.feedback, voiceOverEnabled: true)
        restoration.cancel()
        #expect(restoration.consume(returnControlFocused: true) == nil)
    }

    @Test
    func `Preparing without VoiceOver discards an older intention`() {
        var restoration = ClientConsentFocusRestoration()
        restoration.prepare(.capture, voiceOverEnabled: true)
        restoration.prepare(.title, voiceOverEnabled: false)
        #expect(restoration.consume(returnControlFocused: true) == nil)
    }
}
