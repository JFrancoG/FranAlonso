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

- [ ] Tipo de entrega identificado: funcional para demo (ADR 0029) o cierre integral para uso real.
- [ ] Un tipo `View` por archivo; preview determinista propio con trait compartido.
- [ ] Estados carga, vacío, contenido y error cubiertos cuando aplican.
- [ ] Pantallas afectadas renderizadas e inspeccionadas en `Large`, `XXX Large` y `AX 5` soportados, también para demo;
  estados/apariencias representativos y evidencia previa válida reutilizada. Matriz restante completa en cierre integral.
- [ ] Matriz de ADR 0022 actualizada con evidencia real; cada aplazamiento de demo enlaza issue, responsable y recuperación.
- [ ] VoiceOver, Voice Control, Switch Control, teclado, orden/foco y anuncios validados o aplazados conforme a ADR 0029.
- [ ] Contraste, color, Dynamic Type, preferencias, orientación, ventana, RTL y gestos validados o aplazados conforme a ADR 0029.
- [ ] En cierre integral: evidencia aplicable completa y deuda accesible resuelta antes del primer candidato para uso real.
- [ ] Objetivos interactivos cumplen la política de 44×44 pt o documentan excepción equivalente y operable.

## Revisión y cierre

- [ ] `$franalonso-review-ios-standards` sin hallazgos abiertos.
- [ ] `$franalonso-review-accessibility` favorable para el tipo de entrega; deuda permitida explícita en demo, sin
  hallazgos abiertos en cierre integral salvo excepciones aceptadas; o `N/A` justificado por ausencia de alcance UI.
- [ ] Solo se repitieron las auditorías cuyos ámbitos cambiaron.
- [ ] `docs/Progress.md` y `docs/progress/phase-XX.md` contienen estado, evidencia, pendiente y bloqueos.
- [ ] Linear coincide con el estado real; activación live y siguiente subfase siguen siendo gates separados.
- [ ] Diff final, secretos y archivos previstos revisados antes de cualquier commit/push/PR autorizado.
