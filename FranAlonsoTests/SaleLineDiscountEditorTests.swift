import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale line discount editor", .timeLimit(.minutes(1)))
@MainActor
struct SaleLineDiscountEditorTests {
    @Test(arguments: [
        ("es_ES", "0", "0"),
        ("es_ES", "100", "100"),
        ("es_ES", "12,5", "12.5"),
        ("es_ES", " 0012,5000 \n", "12.5"),
        ("en_US", "12.5", "12.5"),
        ("en_US", "-0.000", "0"),
        ("en_US", "0.12345678901234567890123456789012345678", "0.12345678901234567890123456789012345678")
    ])
    func `localized complete percentages reach acceptance without rounding`(
        locale: String,
        text: String,
        expected: String
    ) async throws {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder, locale: locale)
        editor.discountText = text
        editor.requestApply()
        await editor.submit()

        #expect(recorder.commands.count == 1)
        let command = try #require(recorder.commands.first)
        #expect(command?.percentage == (try viewModelDecimal(expected)))
        #expect(editor.hasAcceptedChange)
        #expect(!editor.hasInputError)
        #expect(!editor.canEdit)
    }

    @Test(arguments: [
        ("es_ES", ""),
        ("es_ES", " \n"),
        ("es_ES", "-0,1"),
        ("es_ES", "100,0001"),
        ("es_ES", "12.5"),
        ("es_ES", "10%"),
        ("es_ES", "1,2foo"),
        ("es_ES", "1.000"),
        ("es_ES", "1e1"),
        ("es_ES", "NaN"),
        ("en_US", ".5"),
        ("en_US", "10."),
        ("en_US", "1,000"),
        ("en_US", "0.123456789012345678901234567890123456789")
    ])
    func `invalid incomplete or inexact input cannot become a write`(locale: String, text: String) async {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder, locale: locale)
        editor.discountText = text
        editor.requestApply()
        await editor.submit()

        #expect(recorder.commands.isEmpty)
        #expect(editor.hasInputError)
        #expect(editor.canEdit)
        #expect(!editor.hasAcceptedChange)
    }

    @Test
    func `blank input cannot remove an existing zero and only explicit removal sends absence`() async throws {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder, initial: try Discount(percentage: 0))
        #expect(editor.discountText == "0")
        #expect(editor.canRemove)
        editor.discountText = ""
        editor.requestApply()
        await editor.submit()
        #expect(recorder.commands.isEmpty)
        #expect(editor.hasInputError)
        editor.requestRemoval()
        await editor.submit()

        #expect(recorder.commands.count == 1)
        #expect(recorder.commands.first == .some(nil))
        #expect(editor.hasAcceptedChange)
        #expect(!editor.hasInputError)
        #expect(!editor.canRemove)
    }

    @Test
    func `an absent initial discount offers no removal and dismissing does not submit text`() async {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder)
        editor.discountText = "25"
        #expect(!editor.canRemove)
        editor.requestRemoval()
        await editor.submit()
        editor.close()
        editor.requestApply()
        editor.retry()
        await editor.submit()

        #expect(recorder.commands.isEmpty)
        #expect(editor.state == .closed)
        #expect(!editor.canEdit)
        #expect(!editor.hasAcceptedChange)
    }

    @Test
    func `failed acceptance retries the frozen percentage once with another task identity`() async throws {
        let recorder = SaleLineDiscountRecorder()
        recorder.failNext = true
        let editor = discountEditor(recorder: recorder)
        editor.discountText = "12,5"
        editor.requestApply()
        let firstRequest = try #require(editor.requestID)
        await editor.submit()
        #expect(editor.hasAcceptanceError)
        #expect(editor.canEdit)
        editor.discountText = "12,5"
        #expect(editor.hasAcceptanceError)
        editor.retry()
        let retryRequest = try #require(editor.requestID)
        #expect(retryRequest != firstRequest)
        await editor.submit()
        editor.retry()
        editor.requestApply()
        await editor.submit()

        let expected = try viewModelDecimal("12.5")
        #expect(recorder.commands.map { $0?.percentage } == [expected, expected])
        #expect(editor.hasAcceptedChange)
        #expect(!editor.hasAcceptanceError)
    }

    @Test
    func `changing text abandons a failed retry and requires a fresh explicit application`() async throws {
        let recorder = SaleLineDiscountRecorder()
        recorder.failNext = true
        let editor = discountEditor(recorder: recorder)
        editor.discountText = "10"
        editor.requestApply()
        _ = try #require(editor.requestID)
        await editor.submit()
        #expect(editor.hasAcceptanceError)
        editor.discountText = "20"
        #expect(!editor.hasAcceptanceError)
        editor.retry()
        await editor.submit()
        #expect(recorder.commands.count == 1)
        editor.requestApply()
        await editor.submit()

        #expect(recorder.commands.map { $0?.percentage } == [10, 20])
        #expect(editor.hasAcceptedChange)
    }

    @Test(arguments: [false, true])
    func `a capability lost before request or task entry never invokes acceptance`(requestedFirst: Bool) async throws {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder, initial: try Discount(percentage: 0))
        editor.discountText = "10"
        if requestedFirst {
            editor.requestApply()
            _ = try #require(editor.requestID)
        }
        recorder.isEditable = false
        editor.requestApply()
        await editor.submit()

        #expect(recorder.commands.isEmpty)
        #expect(editor.isUnavailable)
        #expect(!editor.canEdit)
        #expect(!editor.canRemove)
        #expect(!editor.hasAcceptanceError)
    }

    @Test
    func `invalid input clears when edited and can then be explicitly accepted`() async throws {
        let recorder = SaleLineDiscountRecorder()
        let editor = discountEditor(recorder: recorder)
        editor.discountText = "101"
        editor.requestApply()
        #expect(editor.hasInputError)
        editor.discountText = "100"
        #expect(!editor.hasInputError)
        editor.requestApply()
        await editor.submit()

        #expect(recorder.commands.map { $0?.percentage } == [100])
        #expect(editor.hasAcceptedChange)
    }
}

@MainActor
private final class SaleLineDiscountRecorder {
    var isEditable = true
    var failNext = false
    private(set) var commands: [Discount?] = []

    func apply(_ discount: Discount?) throws {
        commands.append(discount)
        if failNext {
            failNext = false
            throw SaleDraftError.persistenceUnavailable
        }
    }
}

@MainActor
private func discountEditor(
    recorder: SaleLineDiscountRecorder,
    initial: Discount? = nil,
    locale: String = "es_ES"
) -> SaleDiscountViewModel {
    SaleDiscountViewModel(
        target: .line(serviceName: "Kit original"),
        discount: initial,
        locale: Locale(identifier: locale),
        canEdit: { recorder.isEditable },
        apply: {
            try recorder.apply($0)
        }
    )
}
