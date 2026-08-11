# Fase 01 — Constitución del proyecto

## Propósito

Estas son las reglas estables y no negociables. Las decisiones concretas viven en ADR, el alcance en specs, el método en
skills y la evidencia en Progress, Git y Linear.

## Plataforma y evidencia

- Comprobar deployment target, SDK, Xcode, Swift y aislamiento reales antes de elegir APIs.
- Usar APIs modernas compatibles; no elevar targets ni adoptar betas como efecto lateral.
- Tratar warnings Swift y Clang como errores.
- Inspeccionar el proyecto real y respaldar propuestas con specs/ADR y documentación primaria actual.
- Exigir revisión independiente read-only antes de escribir código ejecutable.
- No alterar código conocido como funcional fuera del cambio exacto aprobado.
- Usar Xcode MCP para build, tests, previews y diagnósticos; no usar `xcodebuild`.

## Arquitectura

- Organizar por feature y por `Domain`, `Data` y `Presentation`; `App` es el composition root.
- Domain contiene valores, invariantes, contratos, UseCases y políticas puras; no importa UI, persistencia ni SDK externos.
- Data posee DTO, modelos persistentes, conversiones, data sources, repositorios y sincronización.
- Presentation contiene Views, ViewModels y Stores justificados; no importa Firebase ni ejecuta operaciones de persistencia.
- Cada pantalla tiene un `@Observable @MainActor` ViewModel; un Store solo se extrae por responsabilidad cohesiva,
  complejidad o reutilización demostrada y nunca duplica estado.
- Una View representa estado y llama intenciones semánticas; no valida, filtra, calcula, persiste, consulta red ni decide
  negocio.
- La única excepción SwiftData en Presentation es el `ModelContext` efímero definido por ADR 0011.
- Las abstracciones deben demostrar responsabilidad, invariante, frontera o reutilización real.
- Las conversiones deterministas viven junto a la representación Data; un Mapper requiere política o dependencia real.
- Usar nombres de responsabilidad explícita: `UseCase`, `Repository`, `DTO`, `Model`, `DataSource`, `PersistenceActor`,
  `SyncEngine`, `SyncPolicy`, `ViewModel`, `Store` y `Screen`.

## Swift y concurrencia

- Usar Swift Concurrency de extremo a extremo: `async`/`await`, estructura, actores, `AsyncSequence` y cancelación.
- No introducir GCD directo, `OperationQueue`, callbacks como diseño principal ni bloqueos de hilos.
- No usar `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)` o equivalentes sin ADR y aprobación explícita.
- Preferir inferencia segura de `Sendable`; no repetir conformidades heredadas o implícitas.
- No introducir APIs deprecated ni interoperabilidad Objective-C/legacy cuando exista alternativa Swift compatible.
- Serializar exclusivamente con Codable.
- Mantener declaraciones legibles dentro de 120 columnas: horizontal para firmas simples de hasta tres parámetros;
  vertical para cuatro o más parámetros, closures, tipos complejos o requisitos genéricos.
- Documentar con DocC en inglés contratos, invariantes, efectos, errores y transiciones no obvias; omitir boilerplate.

## Datos, sincronización y privacidad

- SwiftData es la fuente de verdad local; Firebase es remoto temporal y queda confinado a adaptadores Data reemplazables.
- Las escrituras son local-first y la sincronización es bidireccional, idempotente, conflict-aware y recuperable.
- Fuera de MainActor, SwiftData vive en `@ModelActor`; nunca cruzan actores modelos persistentes vivos.
- Motores, índices, reglas y writers live requieren una puerta operativa separada.
- Telemetría usa allowlists y nunca recibe PII, payloads de negocio ni secretos.
- Audio, transcripciones, prompts, respuestas y estado conversacional son efímeros y no se persisten ni registran.
- El asistente MVP usa APIs Apple estables on-device, sin fallback cloud ni escucha en segundo plano.
- Una capacidad probabilística solo lee, navega o rellena borradores reversibles; nunca recibe persistencia/bindings
  directos ni ejecuta UseCases mutadores. La persona revisa y guarda por el flujo visual normal.
- Solo se permiten frameworks Apple y los módulos Firebase ya aprobados: Core, Auth, Firestore, Storage, AnalyticsCore y
  Crashlytics. Cualquier dependencia nueva exige propuesta y aprobación explícita.

## SwiftUI, localización y accesibilidad

- Los observables propios usan `@Observable`; no introducir `ObservableObject`, `@Published`, `@StateObject` ni
  `@ObservedObject`.
- Cada archivo Swift contiene como máximo un tipo `View`; subviews extraídas viven en archivos propios.
- `@ViewBuilder` se reserva para fronteras reales; usar trailing closures cuando no exista ambigüedad.
- Cada View tiene un `#Preview` propio con el `PreviewModifier` compartido y datos in-memory deterministas.
- Todo texto visible vive en `Localizable.xcstrings`.
- Toda pantalla aplica el objetivo interno aceptado por ADR 0022, basado en WCAG 2.2 A/AA, WCAG2ICT y convenciones de
  accesibilidad Apple, y conserva su evidencia antes del cierre.
- Dynamic Type, VoiceOver, Voice Control, Switch Control, teclado, contraste, movimiento, orientación, RTL y tamaños de
  ventana se consideran desde la implementación, no como remediación final.

## Testing y entrega

- Aplicar TDD con Swift Testing; no crear XCTest, XCUITest ni tests UI nativos.
- Usar dobles deterministas, `ModelContainer` in-memory e inyección de reloj/UUID/errores cuando afecten al resultado.
- Validar código y configuración mediante Xcode MCP y mantener cero warnings.
- Auditar arquitectura/gobernanza y, cuando aplique, SwiftUI/accesibilidad mediante revisores independientes read-only.
- Una subfase termina solo con checklist, evidencia, Progress y Linear reconciliados.
- Commit, push, PR, merge, publicación, activación live y siguiente subfase son autorizaciones separadas.

## Referencias normativas

- Los ADR aceptados concretan y, cuando lo declaran, sustituyen decisiones previas.
- `docs/standards/swift-code-policy.md` conserva la política Swift estable y detallada.
- `docs/DEVELOPMENT_GUIDE.md` define el flujo; `docs/PULL_REQUEST_CHECKLIST.md`, el cierre.
- Las fuentes externas de cada decisión se conservan en su ADR o referencia especializada, no en esta constitución.
