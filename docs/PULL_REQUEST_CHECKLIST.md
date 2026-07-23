# Checklist de Pull Request

## Alcance y arquitectura

- [ ] La PR cubre una subfase revisable y enlaza su ID.
- [ ] El diff no contiene cambios ajenos.
- [ ] La solución cita fuentes primarias actuales y no depende del conocimiento recordado del modelo.
- [ ] Un revisor de solo lectura validó la propuesta y sus fuentes antes de escribir código ejecutable, o se documentó que no había aislamiento multiagente.
- [ ] Todo cambio de código ya funcional coincide con una propuesta exacta aprobada por el propietario; no hay refactors oportunistas.
- [ ] Se respetan `Domain`, `Data`, `Presentation` y `App`.
- [ ] ViewModel sigue siendo la fachada; cada Store está justificado y no duplica estado.
- [ ] La View solo representa estado y llama acciones semánticas del ViewModel; no contiene negocio, persistencia, red, validación, filtrado o cálculo.
- [ ] Si una acción inserta, actualiza o borra con SwiftData, la View pasa `@Environment(\.modelContext)` a la función `@MainActor` del ViewModel sin operar sobre el contexto, almacenarlo o cruzarlo entre actores.
- [ ] La mutación se inyecta como closure `@MainActor` sobre un valor de Domain y `ModelContext`: App la compone, Data ejecuta CRUD/mapping/local-first, Domain no recibe el contexto y Data no importa Presentation.
- [ ] Si conviven adaptador contextual y Repository context-free, comparten una única primitiva interna de escritura Data y no duplican mapping, cola, idempotencia o la misma mutación.
- [ ] Los imports Firebase permanecen en Data/Infrastructure; modelos, mappers y políticas SwiftData permanecen en Data, con la composición del `ModelContainer` limitada a App y `ModelContext` como única excepción efímera en Presentation.
- [ ] Backend Firebase y telemetría dependen de contratos de sustitución independientes.
- [ ] Nombres y sufijos expresan responsabilidad.

## Datos, concurrencia y producto

- [ ] SwiftData/Firestore mantienen sus fuentes de verdad.
- [ ] Cambios de sync son idempotentes y cubren conflicto, tombstone y recuperación.
- [ ] SwiftData fuera de MainActor usa `@ModelActor`.
- [ ] UI está en MainActor e I/O no lo bloquea.
- [ ] La inferencia de `Sendable` y la cancelación están revisadas; los actores no repiten conformidad y toda declaración explícita de un tipo valor responde a una frontera pública o genérica demostrada.
- [ ] Todo flujo concurrente propio usa Swift Concurrency y `async`/`await`; no hay GCD, Dispatch, `OperationQueue` ni callbacks como modelo de concurrencia.
- [ ] No existe `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)` ni salida equivalente sin una excepción respaldada por fuentes y aprobada explícitamente antes de implementarla.
- [ ] Invariantes de producto y snapshots históricos se preservan.
- [ ] Analytics y Crashlytics no reciben PII ni payloads de negocio; consentimiento y activación se respetan.
- [ ] Si cambia el asistente, su salida es tipada y solo consulta, navega o rellena borradores; guardar sigue siendo visual y ningún UseCase mutador es accesible desde voz/modelo.
- [ ] Audio, transcripciones, prompts, respuestas y estado conversacional no se persisten, registran ni telemetrizan; cancelar/interrumpir los descarta.

## Código y testing

- [ ] API moderna compatible con deployment target real.
- [ ] Declaraciones y call sites usan construcciones nativas de Swift; no hay patrones ceremoniales trasladados, abstracciones sin responsabilidad demostrada ni protocolos heredados repetidos en una lista de conformidad.
- [ ] Sin APIs deprecated ni usos propios de `@objc`, selectors, `NotificationCenter` por selector, `DateFormatter`, `NSRegularExpression` u otras elecciones Objective-C/legacy no aprobadas.
- [ ] Presentation usa `@Observable`; no introduce `ObservableObject`, `@Published`, `@StateObject` ni `@ObservedObject`.
- [ ] Las APIs del asistente son estables para iOS/Xcode 26; disponibilidad, permisos y fallback manual están cubiertos sin fallback cloud o background mode.
- [ ] Warnings como errores y cero warnings.
- [ ] Codable; sin `JSONSerialization`.
- [ ] Textos visibles en `.xcstrings`.
- [ ] Cada archivo Swift contiene como máximo un tipo que conforme a `View`; las subviews extraídas tienen archivo propio.
- [ ] Los inicializadores/modificadores SwiftUI usan trailing closures y multiple trailing closures cuando no existe ambigüedad.
- [ ] `@ViewBuilder` aparece solo en fronteras reales de composición; no es redundante en `body`, una helper de una expresión o una View sobredimensionada.
- [ ] Las dimensiones numéricas explícitas de contenido no textual significativo que acompañan Dynamic Type usan `@ScaledMetric(relativeTo:)`; excepciones automáticas o fijas están justificadas.
- [ ] Cada `View` tiene un `#Preview` en su archivo y cada preview usa el trait `PreviewModifier` compartido con `ModelContainer` de test en memoria y datos deterministas, idempotentes y navegables.
- [ ] Sin dependencias externas fuera de Firebase aprobado.
- [ ] `GoogleService-Info.plist` permanece ignorado y `Package.resolved` compartido está versionado.
- [ ] TDD con Swift Testing y evidencia RED/GREEN, o `N/A` justificado porque la subfase no cambia comportamiento ejecutable.
- [ ] Tests nuevos y anteriores afectados verdes, o `N/A` justificado cuando no hay targets afectados.
- [ ] Sin XCTest, XCUITest ni tests UI nativos.
- [ ] Fakes remotos y ModelContainer in-memory cuando aplica.

## Documentación y revisión

- [ ] ADR creado/actualizado antes de decisiones no triviales.
- [ ] La API semántica nueva o modificada tiene DocC preciso y no redundante, independientemente de su visibilidad; invariantes, parámetros, retorno y errores se documentan solo cuando aportan contrato.
- [ ] Validación mediante Xcode MCP para cambios de código/configuración, o `N/A` justificado para documentación, QA manual o distribución.
- [ ] Auditoría `$review-ios-standards` registrada para arquitectura, datos, concurrencia, testing y gobernanza.
- [ ] Auditoría `$review-swiftui-accessibility` registrada para UI, previews y accesibilidad, o `N/A` justificado sin alcance SwiftUI.
- [ ] Las pantallas afectadas se renderizaron e inspeccionaron con Xcode MCP en las variantes soportadas `Large`, `XXX Large` y `AX 5`, o se registró `N/A` porque no cambió ninguna pantalla.
- [ ] Cada revisor contrastó de forma independiente las fuentes y la evidencia de su ámbito.
- [ ] Hallazgos válidos corregidos o descartados con evidencia y revisados de nuevo solo por el especialista afectado.
- [ ] `docs/Progress.md` actualizado con estado, evidencia, siguiente acción y bloqueos.
- [ ] Definition of Done de la subfase completamente marcada.
