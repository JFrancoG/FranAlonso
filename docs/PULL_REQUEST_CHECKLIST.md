# Pull Request Checklist

## Alcance y autoridad

- [ ] Cambio limitado a la subfase y aprobación registradas.
- [ ] Spec activa, constitución y ADR aplicables revisados.
- [ ] Alternativas, riesgos y fuentes primarias revisados por un par read-only antes del código.
- [ ] Sin limpieza oportunista ni cambios locales ajenos incluidos.
- [ ] ADR nuevo o actualizado cuando existe una decisión no trivial.

## Arquitectura y datos

- [ ] Domain permanece libre de UI, persistencia y SDK externos.
- [ ] Views renderizan estado y delegan intenciones al `@Observable @MainActor` ViewModel.
- [ ] Stores, protocolos, mappers y servicios poseen una responsabilidad demostrada.
- [ ] SwiftData, Firebase, sincronización y `ModelContext` respetan los ADR aplicables.
- [ ] Concurrencia estructurada, aislamiento y sendability son seguros, sin opt-outs no aprobados.
- [ ] Sin PII, payloads de negocio, secretos ni estado efímero del asistente en logs, telemetría o persistencia.

## Código y tests

- [ ] API moderna compatible con configuración real; cero warnings.
- [ ] Swift legible, 120 columnas preferidas y sin APIs legacy/deprecated no aprobadas.
- [ ] Codable y `.xcstrings`; dependencias limitadas a las aprobadas.
- [ ] DocC preciso en contratos semánticos modificados.
- [ ] Evidencia TDD con Swift Testing, o `N/A` justificado.
- [ ] Tests afectados y build verdes mediante Xcode MCP.
- [ ] Sin XCTest, XCUITest, UI tests nativos ni `xcodebuild`.

## SwiftUI y accesibilidad

- [ ] Un tipo `View` por archivo; preview determinista propio con trait compartido.
- [ ] Estados carga, vacío, contenido y error cubiertos cuando aplican.
- [ ] Variantes soportadas `Large`, `XXX Large` y `AX 5` renderizadas e inspeccionadas.
- [ ] Matriz de ADR 0022 completada para cada pantalla afectada.
- [ ] VoiceOver, Voice Control, Switch Control, teclado, orden/foco y anuncios validados cuando aplican.
- [ ] Contraste, color, Dynamic Type, Reduce Motion/Transparency, orientación, ventana, RTL y gestos alternativos validados.
- [ ] Objetivos interactivos cumplen la política de 44×44 pt o documentan excepción equivalente y operable.

## Revisión y cierre

- [ ] `$franalonso-review-ios-standards` sin hallazgos abiertos.
- [ ] `$franalonso-review-accessibility` sin hallazgos abiertos, o `N/A` justificado.
- [ ] Solo se repitieron las auditorías cuyos ámbitos cambiaron.
- [ ] `docs/Progress.md` y `docs/progress/phase-XX.md` contienen estado, evidencia, pendiente y bloqueos.
- [ ] Linear coincide con el estado real; activación live y siguiente subfase siguen siendo gates separados.
- [ ] Diff final, secretos y archivos previstos revisados antes de cualquier commit/push/PR autorizado.
