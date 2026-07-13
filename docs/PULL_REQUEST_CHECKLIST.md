# Checklist de Pull Request

## Alcance y arquitectura

- [ ] La PR cubre una subfase revisable y enlaza su ID.
- [ ] El diff no contiene cambios ajenos.
- [ ] Se respetan `Domain`, `Data`, `Presentation` y `App`.
- [ ] ViewModel sigue siendo la fachada; cada Store está justificado y no duplica estado.
- [ ] Firebase y SwiftData permanecen en Data.
- [ ] Nombres y sufijos expresan responsabilidad.

## Datos, concurrencia y producto

- [ ] SwiftData/Firestore mantienen sus fuentes de verdad.
- [ ] Cambios de sync son idempotentes y cubren conflicto, tombstone y recuperación.
- [ ] SwiftData fuera de MainActor usa `@ModelActor`.
- [ ] UI está en MainActor e I/O no lo bloquea.
- [ ] `Sendable` y cancelación están revisados.
- [ ] No existe `@unchecked Sendable` sin ADR y tests.
- [ ] Invariantes de producto y snapshots históricos se preservan.

## Código y testing

- [ ] API moderna compatible con deployment target real.
- [ ] Warnings como errores y cero warnings.
- [ ] Codable; sin `JSONSerialization`.
- [ ] Textos visibles en `.xcstrings`.
- [ ] Sin dependencias externas fuera de Firebase aprobado.
- [ ] TDD con Swift Testing y evidencia RED/GREEN, o `N/A` justificado porque la subfase no cambia comportamiento ejecutable.
- [ ] Tests nuevos y anteriores afectados verdes, o `N/A` justificado cuando no hay targets afectados.
- [ ] Sin XCTest, XCUITest ni tests UI nativos.
- [ ] Fakes remotos y ModelContainer in-memory cuando aplica.

## Documentación y revisión

- [ ] ADR creado/actualizado antes de decisiones no triviales.
- [ ] Validación mediante Xcode MCP para cambios de código/configuración, o `N/A` justificado para documentación, QA manual o distribución.
- [ ] Primera auditoría `$review-ios-standards` registrada.
- [ ] Hallazgos válidos corregidos o descartados con evidencia.
- [ ] Segunda auditoría sin hallazgos válidos abiertos.
- [ ] `docs/Progress.md` actualizado con estado, evidencia, siguiente acción y bloqueos.
- [ ] Definition of Done de la subfase completamente marcada.
