import Foundation
import SwiftUI
import Testing
@testable import FranAlonso

@Suite("Design system color assets")
struct DesignSystemColorAssetTests {
    @Test("The semantic color catalog contains the approved token inventory")
    func semanticColorCatalogContainsTheApprovedTokenInventory() throws {
        let urls = try FileManager.default.contentsOfDirectory(
            at: Self.colorsDirectory,
            includingPropertiesForKeys: nil
        )
        let names = Set(
            urls
                .filter { $0.pathExtension == "colorset" }
                .map { $0.deletingPathExtension().lastPathComponent }
        )

        #expect(names == Set(Self.approvedTokens.keys))
    }

    @Test("Every semantic color has the approved four sRGB appearances")
    func everySemanticColorHasTheApprovedFourSRGBAppearances() throws {
        for (name, expectedAppearances) in Self.approvedTokens {
            let document = try Self.loadColorSet(at: Self.colorsDirectory.appending(path: "\(name).colorset"))

            #expect(try Self.hexAppearances(in: document) == expectedAppearances, "Unexpected values for \(name)")
        }
    }

    @Test("The global accent follows Brand Primary Ink")
    func globalAccentFollowsBrandPrimaryInk() throws {
        let accent = try Self.loadColorSet(at: Self.assetsDirectory.appending(path: "AccentColor.colorset"))

        #expect(try Self.hexAppearances(in: accent) == Self.approvedTokens["BrandPrimaryInk"])
    }

    @Test("Approved text pairs meet the project contrast thresholds")
    func approvedTextPairsMeetTheProjectContrastThresholds() throws {
        let pairs = [
            ("TextPrimary", "Canvas"),
            ("TextPrimary", "Surface"),
            ("TextSecondary", "Canvas"),
            ("TextSecondary", "Surface"),
            ("BrandPrimaryInk", "Canvas"),
            ("BrandPrimaryInk", "Surface"),
            ("BrandSecondaryInk", "Canvas"),
            ("BrandSecondaryInk", "Surface"),
            ("SuccessInk", "Canvas"),
            ("SuccessInk", "Surface"),
            ("WarningInk", "Canvas"),
            ("WarningInk", "Surface"),
            ("ErrorInk", "Canvas"),
            ("ErrorInk", "Surface"),
            ("OnBrandPrimary", "BrandPrimary"),
            ("OnSuccess", "SuccessFill"),
            ("OnWarning", "WarningFill"),
            ("OnError", "ErrorFill")
        ]

        for (foregroundName, backgroundName) in pairs {
            for appearance in Appearance.allCases {
                let foreground = try #require(Self.approvedTokens[foregroundName]?[appearance])
                let background = try #require(Self.approvedTokens[backgroundName]?[appearance])
                let threshold = appearance.isHighContrast ? 7.0 : 4.5
                let ratio = try Self.contrastRatio(foreground, background)

                #expect(
                    ratio >= threshold,
                    "\(foregroundName) on \(backgroundName) is \(ratio):1 in \(appearance.rawValue)"
                )
            }
        }
    }

    @Test("Accent control boundaries meet non-text contrast")
    func accentControlBoundariesMeetNonTextContrast() throws {
        for accentName in ["BrandPrimary", "BrandPrimaryInk"] {
            for backgroundName in ["Canvas", "Surface"] {
                for appearance in Appearance.allCases {
                    let accent = try #require(Self.approvedTokens[accentName]?[appearance])
                    let background = try #require(Self.approvedTokens[backgroundName]?[appearance])
                    let ratio = try Self.contrastRatio(accent, background)

                    #expect(
                        ratio >= 3.0,
                        "\(accentName) on \(backgroundName) is \(ratio):1 in \(appearance.rawValue)"
                    )
                }
            }
        }
    }

    @Test("Xcode generates Color and ShapeStyle symbols for every semantic token")
    func xcodeGeneratesColorAndShapeStyleSymbolsForEverySemanticToken() {
        let colors: [Color] = [
            .canvas, .surface, .textPrimary, .textSecondary,
            .brandPrimary, .brandPrimaryInk, .onBrandPrimary,
            .brandSecondary, .brandSecondaryInk,
            .successFill, .successInk, .onSuccess,
            .warningFill, .warningInk, .onWarning,
            .errorFill, .errorInk, .onError
        ]
        let styles: [AnyShapeStyle] = [
            AnyShapeStyle(.canvas), AnyShapeStyle(.surface),
            AnyShapeStyle(.textPrimary), AnyShapeStyle(.textSecondary),
            AnyShapeStyle(.brandPrimary), AnyShapeStyle(.brandPrimaryInk), AnyShapeStyle(.onBrandPrimary),
            AnyShapeStyle(.brandSecondary), AnyShapeStyle(.brandSecondaryInk),
            AnyShapeStyle(.successFill), AnyShapeStyle(.successInk), AnyShapeStyle(.onSuccess),
            AnyShapeStyle(.warningFill), AnyShapeStyle(.warningInk), AnyShapeStyle(.onWarning),
            AnyShapeStyle(.errorFill), AnyShapeStyle(.errorInk), AnyShapeStyle(.onError)
        ]

        #expect(colors.count == Self.approvedTokens.count)
        #expect(styles.count == Self.approvedTokens.count)
        _ = Color.accentColor
    }
}

private extension DesignSystemColorAssetTests {
    enum Appearance: String, CaseIterable {
        case light
        case dark
        case highContrastLight
        case highContrastDark

        var isHighContrast: Bool {
            switch self {
            case .light, .dark:
                false
            case .highContrastLight, .highContrastDark:
                true
            }
        }
    }

    struct ColorSetDocument: Decodable {
        let colors: [ColorEntry]
    }

    struct ColorEntry: Decodable {
        let appearances: [AppearanceEntry]?
        let color: ColorDefinition?
        let idiom: String
    }

    struct AppearanceEntry: Decodable {
        let appearance: String
        let value: String
    }

    struct ColorDefinition: Decodable {
        let colorSpace: String
        let components: Components

        enum CodingKeys: String, CodingKey {
            case colorSpace = "color-space"
            case components
        }
    }

    struct Components: Decodable {
        let alpha: String
        let blue: String
        let green: String
        let red: String
    }

    static let assetsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "FranAlonso/Resources/Assets.xcassets")
    static let colorsDirectory = assetsDirectory.appending(path: "Colors")

    static let approvedTokens: [String: [Appearance: String]] = [
        "Canvas": palette("F7F8FA", "1C1C1E", "FFFFFF", "000000"),
        "Surface": palette("E2E6EB", "2C2C2E", "E5E7EB", "1C1C1E"),
        "TextPrimary": palette("1C1C1E", "FFFFFF", "000000", "FFFFFF"),
        "TextSecondary": palette("66666B", "9E9E9F", "333438", "D1D1D6"),
        "BrandPrimary": palette("B65A9E", "E49ACE", "6B205D", "F4B2DF"),
        "BrandPrimaryInk": palette("7B2F70", "E49ACE", "6B205D", "F4B2DF"),
        "OnBrandPrimary": palette("000000", "000000", "FFFFFF", "000000"),
        "BrandSecondary": palette("D6A84B", "F0C96A", "5B4000", "FFD980"),
        "BrandSecondaryInk": palette("765400", "F0C96A", "5B4000", "FFD980"),
        "SuccessFill": palette("34C759", "30D158", "075018", "7EE787"),
        "SuccessInk": palette("1C7135", "30D158", "075018", "7EE787"),
        "OnSuccess": palette("000000", "000000", "FFFFFF", "000000"),
        "WarningFill": palette("FF9500", "FF9F0A", "5E3C00", "FFD37A"),
        "WarningInk": palette("825500", "FF9F0A", "5E3C00", "FFD37A"),
        "OnWarning": palette("000000", "000000", "FFFFFF", "000000"),
        "ErrorFill": palette("FF3B30", "FF453A", "8B1E1E", "FF9B96"),
        "ErrorInk": palette("B42318", "FF6B63", "8B1E1E", "FF9B96"),
        "OnError": palette("000000", "000000", "FFFFFF", "000000")
    ]

    static func palette(
        _ light: String,
        _ dark: String,
        _ highLight: String,
        _ highDark: String
    ) -> [Appearance: String] {
        [
            Appearance.light: light,
            Appearance.dark: dark,
            Appearance.highContrastLight: highLight,
            Appearance.highContrastDark: highDark
        ]
    }

    static func loadColorSet(at directory: URL) throws -> ColorSetDocument {
        let data = try Data(contentsOf: directory.appending(path: "Contents.json"))
        return try JSONDecoder().decode(ColorSetDocument.self, from: data)
    }

    static func hexAppearances(in document: ColorSetDocument) throws -> [Appearance: String] {
        var result: [Appearance: String] = [:]

        for entry in document.colors {
            #expect(entry.idiom == "universal")
            let color = try #require(entry.color)
            #expect(color.colorSpace == "srgb")
            #expect(color.components.alpha == "1.000")
            result[try appearance(for: entry.appearances ?? [])] = try hex(from: color.components)
        }

        #expect(result.count == Appearance.allCases.count)
        return result
    }

    static func appearance(for entries: [AppearanceEntry]) throws -> Appearance {
        let traits = Set(entries.map { "\($0.appearance)=\($0.value)" })
        _ = try #require(traits.count == entries.count, "Duplicate appearance traits: \(traits.sorted())")

        let appearance: Appearance? = switch traits {
        case []: .light
        case ["luminosity=dark"]: .dark
        case ["contrast=high"]: .highContrastLight
        case ["luminosity=dark", "contrast=high"]: .highContrastDark
        default: nil
        }

        return try #require(appearance, "Unexpected appearance traits: \(traits.sorted())")
    }

    static func hex(from components: Components) throws -> String {
        try [components.red, components.green, components.blue]
            .map { try #require(Int($0.dropFirst(2), radix: 16)) }
            .map { String(format: "%02X", $0) }
            .joined()
    }

    static func contrastRatio(_ firstHex: String, _ secondHex: String) throws -> Double {
        let first = try relativeLuminance(of: firstHex)
        let second = try relativeLuminance(of: secondHex)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    static func relativeLuminance(of hex: String) throws -> Double {
        let values = try stride(from: 0, to: 6, by: 2).map { index in
            let start = hex.index(hex.startIndex, offsetBy: index)
            let end = hex.index(start, offsetBy: 2)
            let component = try #require(Int(hex[start..<end], radix: 16))
            return Double(component) / 255.0
        }
        let linear = values.map { value in
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2])
    }
}
