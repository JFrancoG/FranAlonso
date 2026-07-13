# Architecture Decision Records

Los ADR se escriben antes de implementar una decisión no trivial y no se reescriben una vez aceptados; cualquier cambio posterior crea otro ADR que lo sustituye.

## Estados

`Propuesto` → `Aceptado` → `Sustituido` o `Obsoleto`. También puede quedar `Rechazado`.

## Índice

| ADR | Decisión | Estado |
|---|---|---|
| [0001](0001-clean-architecture-observable.md) | Clean Architecture, ViewModel y Store opcional | Propuesto |
| [0002](0002-swiftdata-local-sot-firestore-remote-sot.md) | SwiftData local y Firestore remoto | Propuesto |
| [0003](0003-swift-testing-only.md) | Swift Testing sin tests UI nativos | Propuesto |
| [0004](0004-no-jsonserialization.md) | Codable como única serialización JSON | Propuesto |
| [0005](0005-warnings-as-errors.md) | Warnings como errores | Propuesto |
| [0006](0006-sync-conflicts-tombstones.md) | Conflictos, revisiones y tombstones | Propuesto |
| [0007](0007-firebase-temporary-vapor-exit.md) | Excepción temporal Firebase y salida a Vapor | Propuesto |
| [0008](0008-atomic-billing-numbering.md) | Numeración atómica e idempotente | Propuesto |
| [0009](0009-client-consent-activation.md) | Consentimiento y activación offline-first | Propuesto |

El estado inicial es propuesto. Cada ADR se revisa y acepta o rechaza durante la fase 01, antes de escribir el código afectado.
