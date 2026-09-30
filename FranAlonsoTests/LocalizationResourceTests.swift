import Foundation
import Testing
@testable import FranAlonso

@Suite("Compiled localization resources")
struct LocalizationResourceTests {
    @Test(arguments: ["es", "en"], ["Localizable", "InfoPlist", "DocumentTemplates"])
    func `every catalog entry resolves in the requested language`(_ language: String, _ table: String) throws {
        let fixtureBundle = Bundle(for: LocalizationFixtureBundle.self)
        let inventoryURL = try #require(fixtureBundle.url(forResource: "LocalizationInventory", withExtension: "json"))
        let inventory = try JSONDecoder().decode([String: [String]].self, from: Data(contentsOf: inventoryURL))
        let keys = try #require(inventory[table])
        let languageURL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let localizedBundle = try #require(Bundle(url: languageURL))
        let tableURL = try #require(localizedBundle.url(forResource: table, withExtension: "strings"))
        let compiled = try PropertyListDecoder().decode([String: String].self, from: Data(contentsOf: tableURL))

        for key in keys {
            let value = try #require(compiled[key], "Missing compiled translation: \(table)/\(language)/\(key)")
            #expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Empty translation: \(key)")
            #expect(value != key, "Unresolved localization key: \(key)")
            #expect(
                localizedBundle.localizedString(forKey: key, value: "__missing_translation__", table: table) == value,
                "Incorrect lookup: \(table)/\(language)/\(key)"
            )
        }
    }

    @Test(arguments: ["es", "en"])
    func `localized system text preserves the configured app identity`(_ language: String) throws {
        let languageURL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let localizedBundle = try #require(Bundle(url: languageURL))
        let tableURL = try #require(localizedBundle.url(forResource: "InfoPlist", withExtension: "strings"))
        let strings = try PropertyListDecoder().decode([String: String].self, from: Data(contentsOf: tableURL))

        #expect(strings["CFBundleDisplayName"] == nil)
        #expect(strings["CFBundleName"] == nil)
        let environment = try #require(Bundle.main.infoDictionary?["AppEnvironment"] as? String)
        let displayName = try #require(Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
        #expect(
            (environment == "develop" && displayName == "Fran DEV")
                || (environment == "production" && displayName == "Fran Alonso")
        )
        #expect(Bundle.main.url(forResource: "LocalizationInventory", withExtension: "json") == nil)
    }

    @Test(arguments: [
        (LocalizedStringResource.authenticationLoginTitle, "es", "Iniciar sesión"),
        (.authenticationLoginTitle, "en", "Sign in"),
        (.authenticationLoginEmailLabel, "es", "Email"),
        (.authenticationLoginEmailLabel, "en", "Email"),
        (.authenticationLoginEmailPrompt, "es", "nombre@ejemplo.com"),
        (.authenticationLoginEmailPrompt, "en", "name@example.com"),
        (.authenticationLoginPasswordLabel, "es", "Contraseña"),
        (.authenticationLoginPasswordLabel, "en", "Password"),
        (.authenticationLoginPasswordPrompt, "es", "Introduce tu contraseña"),
        (.authenticationLoginPasswordPrompt, "en", "Enter your password"),
        (.authenticationLoginPasswordShow, "es", "Mostrar contraseña"),
        (.authenticationLoginPasswordShow, "en", "Show password"),
        (.authenticationLoginPasswordHide, "es", "Ocultar contraseña"),
        (.authenticationLoginPasswordHide, "en", "Hide password"),
        (.authenticationLoginSubmit, "es", "Acceder"),
        (.authenticationLoginSubmit, "en", "Sign in"),
        (.authenticationLoginSigningIn, "es", "Comprobando credenciales…"),
        (.authenticationLoginSigningIn, "en", "Checking credentials…"),
        (.authenticationLoginSucceeded, "es", "Credenciales aceptadas. Comprobando la sesión…"),
        (.authenticationLoginSucceeded, "en", "Credentials accepted. Checking your session…"),
        (.authenticationLoginErrorConfiguration, "es", "El acceso no está configurado correctamente. Contacta con soporte."),
        (.authenticationLoginErrorConfiguration, "en", "Sign-in is not configured correctly. Contact support."),
        (.authenticationLoginErrorCredentialsRejected, "es", "No se ha podido iniciar sesión. Revisa el email y la contraseña."),
        (.authenticationLoginErrorCredentialsRejected, "en", "Unable to sign in. Check your email and password."),
        (.authenticationLoginErrorSecureStorage, "es", "No se puede acceder al almacenamiento seguro del dispositivo."),
        (.authenticationLoginErrorSecureStorage, "en", "Unable to access this device’s secure storage."),
        (.authenticationLoginErrorTemporarilyUnavailable, "es", "El acceso no está disponible temporalmente. Inténtalo de nuevo."),
        (.authenticationLoginErrorTemporarilyUnavailable, "en", "Sign-in is temporarily unavailable. Please try again."),
        (.authenticationLoginErrorUnexpected, "es", "No se ha podido iniciar sesión. Inténtalo de nuevo."),
        (.authenticationLoginErrorUnexpected, "en", "Unable to sign in. Please try again.")
    ])
    func `login resources display the approved copy`(
        _ resource: LocalizedStringResource,
        _ language: String,
        _ expected: String
    ) {
        var localized = resource
        localized.locale = Locale(identifier: language)
        #expect(String(localized: localized) == expected)
    }
}

private final class LocalizationFixtureBundle {}
