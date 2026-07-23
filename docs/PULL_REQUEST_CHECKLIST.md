# Checklist de Pull Request

## Alcance y arquitectura

- [ ] La PR cubre una subfase revisable y enlaza su ID.
- [ ] El diff no contiene cambios ajenos.
- [ ] Se respetan `Domain`, `Data`, `Presentation` y `App`.
- [ ] ViewModel sigue siendo la fachada; cada Store está justificado y no duplica estado.
- [ ] Los imports Firebase permanecen en Data/Infrastructure; modelos y persistencia SwiftData permanecen en Data, con la composición del `ModelContainer` limitada a App.
- [ ] Backend Firebase y telemetría dependen de contratos de sustitución independientes.
- [ ] Nombres y sufijos expresan responsabilidad.

## Datos, concurrencia y producto

- [ ] SwiftData/Firestore mantienen sus fuentes de verdad.
- [ ] Cambios de sync son idempotentes y cubren conflicto, tombstone y recuperación.
- [ ] SwiftData fuera de MainActor usa `@ModelActor`.
- [ ] UI está en MainActor e I/O no lo bloquea.
- [ ] `Sendable` y cancelación están revisados.
- [ ] No existe `@unchecked Sendable` sin ADR y tests.
- [ ] Invariantes de producto y snapshots históricos se preservan.
- [ ] Analytics y Crashlytics no reciben PII ni payloads de negocio; consentimiento y activación se respetan.
- [ ] Si cambia el asistente, su salida es tipada y solo consulta, navega o rellena borradores; guardar sigue siendo visual y ningún UseCase mutador es accesible desde voz/modelo.
- [ ] Audio, transcripciones, prompts, respuestas y estado conversacional no se persisten, registran ni telemetrizan; cancelar/interrumpir los descarta.

## Código y testing

- [ ] API moderna compatible con deployment target real.
- [ ] Las APIs del asistente son estables para iOS/Xcode 26; disponibilidad, permisos y fallback manual están cubiertos sin fallback cloud o background mode.
- [ ] Warnings como errores y cero warnings.
- [ ] Codable; sin `JSONSerialization`.
- [ ] Textos visibles en `.xcstrings`.
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
- [ ] Primera auditoría `$review-ios-standards` registrada.
- [ ] Hallazgos válidos corregidos o descartados con evidencia.
- [ ] Segunda auditoría sin hallazgos válidos abiertos.
- [ ] `docs/Progress.md` actualizado con estado, evidencia, siguiente acción y bloqueos.
- [ ] Definition of Done de la subfase completamente marcada.
