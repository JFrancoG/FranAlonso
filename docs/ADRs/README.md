# Architecture Decision Records

Los ADR se escriben antes de implementar una decisión no trivial y no se reescriben una vez aceptados; cualquier cambio posterior crea otro ADR que lo sustituye.

## Estados

`Propuesto` → `Aceptado` → `Sustituido` o `Obsoleto`. También puede quedar `Rechazado`.

## Índice

| ADR | Decisión | Estado |
|---|---|---|
| [0001](0001-clean-architecture-observable.md) | Clean Architecture, ViewModel y Store opcional | Aceptado |
| [0002](0002-swiftdata-local-sot-firestore-remote-sot.md) | SwiftData local y Firestore remoto | Aceptado |
| [0003](0003-swift-testing-only.md) | Swift Testing sin tests UI nativos | Aceptado |
| [0004](0004-no-jsonserialization.md) | Codable como única serialización JSON | Aceptado |
| [0005](0005-warnings-as-errors.md) | Warnings como errores | Aceptado |
| [0006](0006-sync-conflicts-tombstones.md) | Conflictos, revisiones y tombstones | Aceptado |
| [0007](0007-firebase-temporary-vapor-exit.md) | Excepción temporal Firebase y salida a Vapor | Aceptado |
| [0008](0008-atomic-billing-numbering.md) | Numeración atómica e idempotente | Aceptado |
| [0009](0009-client-consent-activation.md) | Consentimiento y activación offline-first | Aceptado |
| [0010](0010-on-device-assistant-provider-strategy.md) | Asistente local en el MVP y proveedor remoto pos-MVP | Aceptado |

Los ADR 0001–0009 fueron revisados y aceptados por el propietario del producto el 14 de julio de 2026. El propietario aceptó el ADR 0010 el 23 de julio de 2026 al incorporar Foundation Models al MVP, preparar GPT-5.6 Luna para después y mantener GPT Realtime únicamente como opción. Cualquier cambio posterior en estas decisiones requiere un nuevo ADR que las sustituya.
