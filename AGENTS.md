# FranAlonso Repository Rules

## Autoridad y alcance

- Leer `docs/specs/01_constitution.md`, la spec activa y los ADR aceptados aplicables antes de cambiar código.
- `docs/specs/00_index.md` fija el orden; `docs/Progress.md` resume el estado; Linear gestiona el trabajo operativo.
- Inspeccionar código y configuración reales. Sustentar decisiones con specs/ADR y fuentes primarias actuales.
- Antes de código ejecutable, obtener una revisión independiente read-only de propuesta, alternativas y fuentes.
- No alterar código funcional fuera del cambio exacto aprobado. Conservar cambios locales ajenos.
- No hacer commit, push, PR, merge, cambio de estado o activación live sin autorización explícita.

## Reglas no negociables

- Arquitectura por feature con `Domain`, `Data`, `Presentation` y composición concreta en `App`.
- Domain no importa SwiftUI, SwiftData, Firebase ni UIKit; las Views renderizan estado y envían intenciones semánticas.
- Cada pantalla posee un `@Observable @MainActor` ViewModel; Store solo por responsabilidad cohesiva demostrada.
- SwiftData es fuente local; Firebase queda en adaptadores Data reemplazables y los motores permanecen inactivos sin gate live.
- Swift Concurrency extremo a extremo; no GCD directo ni opt-outs inseguros sin ADR y aprobación previa.
- TDD con Swift Testing; no XCTest, XCUITest ni UI tests nativos; serialización con Codable.
- Texto visible en `.xcstrings`; warnings como errores; API moderna compatible con el target real.
- Una sola conformidad `View` por archivo, preview determinista por View y DocC solo para contratos semánticos.
- Toda pantalla aplica ADR 0022 y no se cierra sin su evidencia de accesibilidad.
- `GoogleService-Info.plist`, PII y payloads de negocio nunca entran en Git, logs o telemetría.

## Herramientas y skills

- Inicio de fase/subfase: usar `$franalonso-start-subphase`.
- Implementación iOS/SwiftUI: usar `$ios-development-standards` y solo sus referencias aplicables.
- Accesibilidad de pantalla: usar `$ios-accessibility-implementation` durante la implementación.
- Apple API dudosa: usar `$cupertino-mcp` con documentación oficial actual.
- Build, tests, previews y diagnósticos: usar `$xcode-mcp`; `xcodebuild` está prohibido.
- Trabajo operativo en Linear: usar `$linear` y mantener paridad con `docs/Progress.md`.
- Notas del vault raíz: usar `$obsidian-cli`; Obsidian no sustituye specs, ADR, Git ni Linear.
- ADR: usar `$architecture-decision-records`.
- Política Swift propia al tocar Swift: leer `docs/standards/swift-code-policy.md`.
- Cierre de subfase: usar `$franalonso-finish-subphase`.
- Auditoría general: agente read-only `ios-standards-reviewer` con `$franalonso-review-ios-standards`.
- Auditoría UI/accesibilidad: agente read-only `ios-accessibility-reviewer` con `$franalonso-review-accessibility`.

## Entrega

- Seguir `docs/DEVELOPMENT_GUIDE.md` y `docs/PULL_REQUEST_CHECKLIST.md`.
- Validar por Xcode MCP cuando cambie código/configuración; para documentación registrar `N/A` razonado.
- Actualizar `docs/Progress.md` y `docs/progress/phase-XX.md` con evidencia, pendiente y bloqueos.
- Corregir hallazgos válidos y repetir solo la auditoría cuyo ámbito cambió.
- Detenerse ante una excepción arquitectónica, unsafe, dependencia nueva, activación live o ampliación material de alcance.
